
#modulo mensaje en usuario

defmodule ChatUserMessage do
  defstruct id: 0, content: "", type: "", notifyTx: false, notifyRx: false, notifyRead: false, user: nil
end


#modulo mensaje de una conversacion en sevidor

defmodule ChatServerMessage do
  defstruct id: 0, tx: nil, rx: nil, chat: "", content: ""
end


#modulo usuario segun servidor

defmodule ChatServerUser do
  defstruct name: "", quietUsers: %{}
end


#modulo usuario del IRC

defmodule ChatUser do

  defstruct name: "", msgsByChats: %{}, server: nil

  def start(user) do
    {:ok, pidUser} = Task.start_link(fn-> loop(user) end)
    send(user.server, {pidUser, :signUp, user})
    {:ok, pidUser}
  end

  defp loop(user) do
    receive do
      #mostrar estado del usuario
      {caller, :userInfo} ->
        IO.puts "#{inspect self} :userInfo"
        IO.puts "#{inspect user}"
        loop(user)
        
      #recibo un mensaje -msg- de -tx- para la conversacion -chat-
      {caller, :receiveMsg, serverMsg} -> 
        IO.puts "#{inspect self} :receiveMsg"
        olderMsgs = Map.get(user.msgsByChats, serverMsg.chat, %{})
        newMsg =  
          %ChatUserMessage{
            id: serverMsg.id,
            content: serverMsg.content,
            type: "rx",
            notifyTx: nil,
            notifyRx: nil,
            notifyRead: nil,
            user: serverMsg.tx
          }
        send(serverMsg.tx, {self, :notifyRx, serverMsg})
        loop(
          %ChatUser{
            name: user.name,
            msgsByChats: Map.put(user.msgsByChats, serverMsg.chat, Map.put(olderMsgs, serverMsg.id, newMsg)),
            server: user.server
          }
        )

      {caller, :sendMsg, serverMsg} ->
        IO.puts "#{inspect self} :sendMsg"
        send(user.server, {self, :notifyWriting, serverMsg})
        :timer.sleep(2500)
        send(user.server, {self, :sendMsg, serverMsg})
        loop(user)

      #notificacion de msg transmitido exitoso (llego al servidor)
      {caller, :notifyTx, serverMsg} ->
        IO.puts "#{inspect self} :notifyTx"
        olderMsgs = Map.get(user.msgsByChats, serverMsg.chat, %{})
        newMsg =  
          %ChatUserMessage{
            id: serverMsg.id,
            content: serverMsg.content,
            type: "tx",
            notifyTx: true,
            notifyRx: false,
            notifyRead: false,
            user: serverMsg.tx
          }
        loop(
          %ChatUser{
            name: user.name,
            msgsByChats: Map.put(user.msgsByChats, serverMsg.chat, Map.put(olderMsgs, serverMsg.id, newMsg)),
            server: user.server
          }
        )

      #notificacion de msg recibido exitoso por el destinatario
      {caller, :notifyRx, serverMsg} ->
		    IO.puts "#{inspect self} :notifyRx"
        olderMsgs = Map.get(user.msgsByChats, serverMsg.chat)
        oldMsg = Map.get(olderMsgs, serverMsg.id)
        newMsg = %ChatUserMessage{
            id: serverMsg.id,
            content: oldMsg.content,
            type: oldMsg.type,
            notifyTx: oldMsg.notifyTx,
            notifyRx: true,
            notifyRead: oldMsg.notifyRead,
            user: oldMsg.user 
        }
        updateMsgs = Map.put(olderMsgs, serverMsg.id, newMsg)
        loop(
          %ChatUser{
            name: user.name,
            msgsByChats: Map.put(user.msgsByChats, serverMsg.chat, updateMsgs),
            server: user.server
          }
        )

      #notifica que el msg fue leido por receptor en una conversacion
      {caller, :notifyRead, serverMsg} ->
        IO.puts "#{inspect self} :notifyRead"
        olderMsgs = Map.get(user.msgsByChats, serverMsg.chat)
        oldMsg = Map.get(olderMsgs, serverMsg.id)
        newMsg = %ChatUserMessage{
            id: serverMsg.id,
            content: oldMsg.content,
            type: oldMsg.type,
            notifyTx: oldMsg.notifyTx,
            notifyRx: oldMsg.notifyRx,
            notifyRead: true,
            user: oldMsg.user 
        }
        updateMsgs = Map.put(olderMsgs, serverMsg.id, newMsg)
        loop(
          %ChatUser{
            name: user.name,
            msgsByChats: Map.put(user.msgsByChats, serverMsg.chat, updateMsgs),
            server: user.server
          }
        )

      #notifica que tx esta escribiendo en el chat
      {caller, :notifyWriting, serverMsg} ->
        IO.puts "#{inspect self} :notifyWriting"
        loop(user)

      #lectura de mensajes de chat
      {caller, :readMsgs, chat} ->
        IO.puts "#{inspect self} :readMsg"
        msgs = Map.get(user.msgsByChats, chat, %{})
        newMsgs = readMessageFromChat(Map.keys(msgs), msgs, chat)
        loop(
          %ChatUser{
            name: user.name, 
            msgsByChats: newMsgs, 
            server: user.server
          }
        )
    end
  end

  defp readMessageFromChat([currentKey| otherKeys], msgs, chat) do
    msg = Map.get(msgs, currentKey, chat)
    if (!msg.notifyRead && msg.type == "rx") do
      readMsgs = Map.put(
        msgs, 
        currentKey, 
        %ChatUserMessage{
          id: msg.id,
          content: msg.content,
          type: msg.type,
          notifyTx: msg.notifyTx,
          notifyRx: msg.notifyRx,
          notifyRead: true,
          user: msg.user 
        }
      )
      send(msg.user, {self, :notifyRead, %ChatServerMessage{id: msg.id, chat: chat}})
      readMessageFromChat(otherKeys, readMsgs, chat)
    else
      readMessageFromChat(otherKeys, msgs, chat)
    end
  end  

  defp readMessageFromChat([], msgs, _) do
    msgs
  end

end



#modulo servidor de mensajeria instantanea IRC

defmodule ChatServer do

  defstruct name: "", users: %{}, sqMessagesId: 0

  def start(server) do
    Task.start_link(fn -> loop(server) end)
  end

  def loop(server) do
    receive do
      #mostrar estado del servido
      {caller, :serverInfo} ->
        IO.puts "#{inspect self} :serverInfo"
        IO.puts "#{inspect server}"
        loop(server)

      #crear cuenta de usuario
      {caller, :signUp, user} ->
        IO.puts "#{inspect self} :signUp"
        loop(
          %ChatServer{
            name: server.name, 
            users: Map.put(server.users, caller, %ChatServerUser{name: user.name, quietUsers: %{}}),
            sqMessagesId: server.sqMessagesId
          }
        )

      #envia mensaje a rx de parte de tx
      {caller, :sendMsg, msg} ->
        IO.puts "#{inspect self} :sendMsg"
        unless isTxQuietByRx?(server, msg.tx, msg.rx) do
          nextId = server.sqMessagesId + 1 
          newMsg = %ChatServerMessage{
            id: nextId,
            tx: msg.tx,
            rx: msg.rx,
            chat: msg.chat,
            content: msg.content
          }
          send(msg.tx, {self, :notifyTx, newMsg})
          send(msg.rx, {self, :receiveMsg, newMsg})
          loop(
            %ChatServer{
                sqMessagesId: nextId,
                users: server.users,
                name: server.name
            }
          )
        else
          loop(server)
        end   
      
      #notifica a rx de que tx esta escribiendo en el chat
      {caller, :notifyWriting, msg} ->
        IO.puts "#{inspect self} :notifyWriting"
        unless isTxQuietByRx?(server, msg.tx, msg.rx) do
          send(msg.rx, {self, :notifyWriting, msg})
        end
        loop(server)
    
    end
  end

  defp isTxQuietByRx?(server, tx, rx) do
    Map.get(server.users, rx).quietUsers[tx]
  end
end

