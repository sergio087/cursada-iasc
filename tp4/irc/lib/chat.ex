#submodulo status de mensaje en conversacion
defmodule Chat.Message do
	defstruct [
	  id: 0,
	  readers: [],
	  receivers: [] 
	]
end

#submodulo miembro de una conversacion
defmodule Chat.User do
	defstruct [ 
		quietUsers: [] #pid
	]
end

defmodule Chat do
  use GenServer

  defstruct [
    id: nil, 
    users: %{}, #pid -> chatUser
    messages: %{}, #id msg -> ChatMessage
    sqMessagesId: 0
  ]

  def start(chatId, users) do
    chat = %__MODULE__{
      id: chatId,
      users: mapUsers(users, %{})
    }
    GenServer.start_link(__MODULE__, chat, [])
  end

  defp mapUsers([pidUser | tail], map) do
    mapUsers(tail, Map.put(map, pidUser, %__MODULE__.User{}))
  end

  defp mapUsers([], map) do
    map
  end

  defp everybodyDoIt?(_, _, []) do
    false
  end

  defp everybodyDoIt?(chat, serverMsg, newUsers) do
    Enum.count(filterUserToTx(chat.users, serverMsg.tx)) == Enum.count(newUsers)
  end

  defp filterUserToTx(usersRx, userTx) do
    Enum.filter(
      Enum.filter(Map.keys(usersRx), fn(user) -> user != userTx end), 
      fn(userRx) -> 
        !Enum.any?(Map.get(usersRx, userRx).quietUsers, fn(quietUser) -> quietUser == userTx end) 
      end
    )
  end


  ## Server Callbacks
  def init(chat) do
  	{:ok, chat}
  end

  def handle_call({:getState}, _from, chat) do
  	{:reply, chat, chat}
  end


  #notifica a rx de que tx esta escribiendo en el chat
  def handle_cast({:notifyWriting, msg}, chat) do
    IO.puts "#{inspect self} :notifyWriting (chat)"
    Enum.each(
      filterUserToTx(chat.users, msg.tx), 
      fn(pidRx) -> GenServer.cast(pidRx, {:notifyWriting, msg}) end
    )
    {:noreply, chat}
  end


  #envia mensaje a rx de parte de tx
  def handle_cast({:deliverMsg, serverMsg}, chat) do
  	IO.puts "#{inspect self} :deliverMsg (chat)"
    nextMessageId = chat.sqMessagesId + 1
    newMsg = 
    	%IRC.Message{
    		id: nextMessageId, 
    		tx: serverMsg.tx, 
    		chat: serverMsg.chat, 
    		content: serverMsg.content
    	}

    GenServer.cast(serverMsg.tx, {:notifyTx, newMsg})

    Enum.each(
    	filterUserToTx(chat.users, serverMsg.tx), 
    	fn(userRx) -> GenServer.cast(userRx, {:receiveMsg, newMsg}) end
	)

    {:noreply, %__MODULE__{
							sqMessagesId: nextMessageId,
							id: chat.id,
							users: chat.users,
							messages: Map.put(chat.messages, nextMessageId, %__MODULE__.Message{ id: nextMessageId})
						}
  	}
  end


  #notificacion de msg recibido exitoso por el destinatario
  def handle_cast({:notifyRx, serverMsg}, chat) do
	IO.puts "#{inspect self} :notifyRx (chat)"
    olderMsg = Map.get(chat.messages, serverMsg.id)
    newReceivers = [serverMsg.rx | olderMsg.receivers]
    if everybodyDoIt?(chat, serverMsg, newReceivers) do
      GenServer.cast(serverMsg.tx, {:notifyRx, serverMsg})
    end
    
    {:noreply, %__MODULE__{
				            sqMessagesId: chat.sqMessagesId,
				            id: chat.id,
				            users: chat.users,
				            messages: Map.put(
				              chat.messages, 
				              olderMsg.id, 
				              %__MODULE__.Message{id: olderMsg.id, readers: olderMsg.readers, receivers: newReceivers}
				            )
				          }
  	} 
  end


  #notificacion de msg leido por un destinatario
  def handle_cast({:notifyRead, serverMsg}, chat) do
  	IO.puts "#{inspect self} :notifyRead (chat)"
    olderMsg = Map.get(chat.messages, serverMsg.id)
    newReaders = [serverMsg.rx | olderMsg.readers]
    if everybodyDoIt?(chat, serverMsg, newReaders) do
  		GenServer.cast(serverMsg.tx, {:notifyRead, serverMsg})
    end

    {:noreply, %__MODULE__{
				            sqMessagesId: chat.sqMessagesId,
				            id: chat.id,
				            users: chat.users,
				            messages: Map.put(
				              chat.messages, 
				              olderMsg.id, 
				              %__MODULE__.Message{id: olderMsg.id, readers: newReaders, receivers: olderMsg.receivers}
				            )
				          }
  	}
  end
end