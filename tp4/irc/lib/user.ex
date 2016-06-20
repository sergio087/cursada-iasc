defmodule User.Message do
    defstruct id: 0, content: "", type: "rx|tx", notifyTx: nil, notifyRx: nil, notifyRead: nil, user: nil
end

defmodule User do
  use GenServer

  defstruct name: "", msgsByChats: %{}, server: nil

  def start(user) do
    GenServer.start_link(__MODULE__, user, [])
  end

  defp readMessageFromChat([currentKey| otherKeys], msgs, chat, server) do
    msg = Map.get(msgs, currentKey)
    if (!msg.notifyRead && msg.type == "rx") do
		readMsgs = Map.put(
			msgs, 
			currentKey, 
			%__MODULE__.Message{
			  id: msg.id,
			  content: msg.content,
			  type: msg.type,
			  notifyTx: msg.notifyTx,
			  notifyRx: msg.notifyRx,
			  notifyRead: true,
			  user: msg.user 
			}
		)
    	GenServer.cast(server, {:notifyRead, %IRC.Message{id: msg.id, tx: msg.user, rx: self, chat: chat }})
      
    	readMessageFromChat(otherKeys, readMsgs, chat, server)
    else
      	readMessageFromChat(otherKeys, msgs, chat, server)
    end
  end  

  defp readMessageFromChat([], msgs, _, _) do
    msgs
  end


  ## Server Callbacks
  def init(user) do
  	GenServer.call(user.server, {:signUp, self, user})
  	{:ok, user}
  end

  def handle_call({:getState}, _from, user) do
  	{:reply, user, user}
  end


  #notificacion alta en un grupo
  def handle_cast({:notifyAddChat, chatId}, user) do
  	IO.puts "#{inspect self} :notifyAddChat (user)"
  	{:noreply, %__MODULE__{
            name: user.name,
            msgsByChats: Map.put(user.msgsByChats, chatId, %{}),
            server: user.server
          }}
  end


  #envio un mensaje -msg- de -tx- para la conversacion -chat-
  def handle_cast({:sendMsg, serverMsg}, user) do
  	IO.puts "#{inspect self} :sendMsg (user)"
  	GenServer.cast(user.server, {:notifyWriting, serverMsg})
    :timer.sleep(2500)
    GenServer.cast(user.server, {:deliverMsg, serverMsg})

    {:noreply, user}
  end


  #notifica que tx esta escribiendo en el chat
  def handle_cast({:notifyWriting, _serverMsg}, user) do
  	IO.puts "#{inspect self} :notifyWriting (user)"

  	{:noreply, user}
  end


  #notificacion de msg transmitido exitoso (llego al servidor)
  def handle_cast({:notifyTx, serverMsg}, user) do
    IO.puts "#{inspect self} :notifyTx (user)"
    olderMsgs = Map.get(user.msgsByChats, serverMsg.chat, %{})
    newMsg =  
      %__MODULE__.Message{
        id: serverMsg.id,
        content: serverMsg.content,
        type: "tx",
        notifyTx: true,
        notifyRx: false,
        notifyRead: false,
        user: serverMsg.tx
      }

      {:noreply, %__MODULE__{
			            name: user.name,
			            msgsByChats: Map.put(user.msgsByChats, serverMsg.chat, Map.put(olderMsgs, serverMsg.id, newMsg)),
			            server: user.server
			          }	
      }
  end


  #notificacion de msg recibido exitoso por el destinatario
  def handle_cast({:notifyRx, serverMsg}, user) do
  	IO.puts "#{inspect self} :notifyRx (user)"
    olderMsgs = Map.get(user.msgsByChats, serverMsg.chat)
    oldMsg = Map.get(olderMsgs, serverMsg.id)
    newMsg = %__MODULE__.Message{
        id: serverMsg.id,
        content: oldMsg.content,
        type: oldMsg.type,
        notifyTx: oldMsg.notifyTx,
        notifyRx: true,
        notifyRead: oldMsg.notifyRead,
        user: oldMsg.user 
    }
    updateMsgs = Map.put(olderMsgs, serverMsg.id, newMsg)
    
    {:noreply, %__MODULE__{
							name: user.name,
							msgsByChats: Map.put(user.msgsByChats, serverMsg.chat, updateMsgs),
							server: user.server
						   }
  	}
  end

  #recibo un mensaje -msg- de -tx- para la conversacion -chat-
  def handle_cast({:receiveMsg, serverMsg}, user) do
  	IO.puts "#{inspect self} :receiveMsg (user)"
    olderMsgs = Map.get(user.msgsByChats, serverMsg.chat, %{})
    newMsg =  
      %__MODULE__.Message{
        id: serverMsg.id,
        content: serverMsg.content,
        type: "rx",
        notifyTx: nil,
        notifyRx: nil,
        notifyRead: nil,
        user: serverMsg.tx
      }

  	GenServer.cast(
  		user.server, 
  		{:notifyRx, %IRC.Message{id: serverMsg.id, tx: serverMsg.tx, rx: self, chat: serverMsg.chat, content: serverMsg.content }}
	)

  	{:noreply, %__MODULE__{
            				name: user.name,
            				msgsByChats: Map.put(user.msgsByChats, serverMsg.chat, Map.put(olderMsgs, serverMsg.id, newMsg)),
            				server: user.server
          					}
  	}
  end


  #notifica que el msg fue leido por receptor en una conversacion
  def handle_cast({:notifyRead, serverMsg}, user) do
  	IO.puts "#{inspect self} :notifyRead (user)"
    olderMsgs = Map.get(user.msgsByChats, serverMsg.chat)
    oldMsg = Map.get(olderMsgs, serverMsg.id)
    newMsg = %__MODULE__.Message{
        id: serverMsg.id,
        content: oldMsg.content,
        type: oldMsg.type,
        notifyTx: oldMsg.notifyTx,
        notifyRx: oldMsg.notifyRx,
        notifyRead: true,
        user: oldMsg.user 
    }
    updateMsgs = Map.put(olderMsgs, serverMsg.id, newMsg)

    {:noreply, %__MODULE__{
				        name: user.name,
				        msgsByChats: Map.put(user.msgsByChats, serverMsg.chat, updateMsgs),
				        server: user.server
      				}
  	}
  end


  #lectura de mensajes de chat
  def handle_cast({:readMsg, chat}, user) do
  	IO.puts "#{inspect self} :readMsg"
    msgs = Map.get(user.msgsByChats, chat, %{})
    newMsgs = readMessageFromChat(Map.keys(msgs), msgs, chat, user.server)

    {:noreply, %__MODULE__{
				            name: user.name, 
				            msgsByChats: Map.put(user.msgsByChats, chat, newMsgs), 
				            server: user.server
				          }
  	}
  end

end
