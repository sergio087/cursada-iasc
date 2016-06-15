
#modulo mensaje en usuario
defmodule UserMessage do
  defstruct id: 0, content: "", type: "rx|tx", notifyTx: nil, notifyRx: nil, notifyRead: nil, user: nil
end


#modulo mensaje de una conversacion en sevidor
defmodule ServerMessage do
  defstruct id: 0, tx: nil, rx: nil, chat: nil, content: ""
end


#modulo usuario
defmodule User do
  defstruct name: "", msgsByChats: %{}, server: nil

  def start(user) do
    {:ok, pidUser} = Task.start_link(fn-> loop(user) end)
    send(user.server, {pidUser, :signUp, user})
    {:ok, pidUser}
  end

  defp loop(user) do
    receive do
      #mostrar estado del usuario
      {_caller, :userInfo} ->
        IO.puts "#{inspect self} :userInfo (user)"
        IO.puts "#{inspect user}"
        loop(user)
        
      #recibo un mensaje -msg- de -tx- para la conversacion -chat-
      {_caller, :receiveMsg, serverMsg} -> 
        IO.puts "#{inspect self} :receiveMsg (user)"
        olderMsgs = Map.get(user.msgsByChats, serverMsg.chat, %{})
        newMsg =  
          %UserMessage{
            id: serverMsg.id,
            content: serverMsg.content,
            type: "rx",
            notifyTx: nil,
            notifyRx: nil,
            notifyRead: nil,
            user: serverMsg.tx
          }
        send(
          user.server, 
          {
            self, 
            :notifyRx, 
            %ServerMessage{id: serverMsg.id, tx: serverMsg.tx, rx: self, chat: serverMsg.chat, content: serverMsg.content }
          }
        )
        loop(
          %User{
            name: user.name,
            msgsByChats: Map.put(user.msgsByChats, serverMsg.chat, Map.put(olderMsgs, serverMsg.id, newMsg)),
            server: user.server
          }
        )

      {_caller, :sendMsg, serverMsg} ->
        IO.puts "#{inspect self} :sendMsg (user)"
        send(user.server, {self, :notifyWriting, serverMsg})
        :timer.sleep(2500)
        send(user.server, {self, :deliverMsg, serverMsg})
        loop(user)

      #notificacion alta en un grupo
      {_caller, :notifyAddChat, chatId} ->
        IO.puts "#{inspect self} :notifyAddChat (user)"
        loop(
          %User{
            name: user.name,
            msgsByChats: Map.put(user.msgsByChats, chatId, %{}),
            server: user.server
          }
        )

      #notificacion de msg transmitido exitoso (llego al servidor)
      {_caller, :notifyTx, serverMsg} ->
        IO.puts "#{inspect self} :notifyTx (user)"
        olderMsgs = Map.get(user.msgsByChats, serverMsg.chat, %{})
        newMsg =  
          %UserMessage{
            id: serverMsg.id,
            content: serverMsg.content,
            type: "tx",
            notifyTx: true,
            notifyRx: false,
            notifyRead: false,
            user: serverMsg.tx
          }
        loop(
          %User{
            name: user.name,
            msgsByChats: Map.put(user.msgsByChats, serverMsg.chat, Map.put(olderMsgs, serverMsg.id, newMsg)),
            server: user.server
          }
        )

      #notificacion de msg recibido exitoso por el destinatario
      {_caller, :notifyRx, serverMsg} ->
		    IO.puts "#{inspect self} :notifyRx (user)"
        olderMsgs = Map.get(user.msgsByChats, serverMsg.chat)
        oldMsg = Map.get(olderMsgs, serverMsg.id)
        newMsg = %UserMessage{
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
          %User{
            name: user.name,
            msgsByChats: Map.put(user.msgsByChats, serverMsg.chat, updateMsgs),
            server: user.server
          }
        )

      #notifica que el msg fue leido por receptor en una conversacion
      {_caller, :notifyRead, serverMsg} ->
        IO.puts "#{inspect self} :notifyRead (user)"
        olderMsgs = Map.get(user.msgsByChats, serverMsg.chat)
        oldMsg = Map.get(olderMsgs, serverMsg.id)
        newMsg = %UserMessage{
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
          %User{
            name: user.name,
            msgsByChats: Map.put(user.msgsByChats, serverMsg.chat, updateMsgs),
            server: user.server
          }
        )

      #notifica que tx esta escribiendo en el chat
      {_caller, :notifyWriting, serverMsg} ->
        IO.puts "#{inspect self} :notifyWriting (user)"
        loop(user)

      #lectura de mensajes de chat
      {_caller, :readMsgs, chat} ->
        IO.puts "#{inspect self} :readMsg"
        msgs = Map.get(user.msgsByChats, chat, %{})
        newMsgs = readMessageFromChat(Map.keys(msgs), msgs, chat, user.server)
        loop(
          %User{
            name: user.name, 
            msgsByChats: newMsgs, 
            server: user.server
          }
        )
    end
  end

  defp readMessageFromChat([currentKey| otherKeys], msgs, chat, server) do
    msg = Map.get(msgs, currentKey)
    if (!msg.notifyRead && msg.type == "rx") do
      readMsgs = Map.put(
        msgs, 
        currentKey, 
        %UserMessage{
          id: msg.id,
          content: msg.content,
          type: msg.type,
          notifyTx: msg.notifyTx,
          notifyRx: msg.notifyRx,
          notifyRead: true,
          user: msg.user 
        }
      )
      send(
          server, 
          {
            self, 
            :notifyRead, 
            %ServerMessage{id: msg.id, tx: msg.user, rx: self, chat: chat }
          }
        )
      readMessageFromChat(otherKeys, readMsgs, chat, server)
    else
      readMessageFromChat(otherKeys, msgs, chat, server)
    end
  end  

  defp readMessageFromChat([], msgs, _, _) do
    msgs
  end
end


#modulo servidor de mensajeria instantanea IRC
defmodule ChatServer do

  defstruct [
    name: "", 
    users: %{}, #pid -> name
    chats: %{}, #name -> pid
    sqChatsId: 0
  ]

  def start(server) do
    Task.start_link(fn -> loop(server) end)
  end

  def loop(server) do
    receive do
      #mostrar estado del servido
      {_caller, :serverInfo} ->
        IO.puts "#{inspect self} :serverInfo"
        IO.puts "#{inspect server}"
        loop(server)

      #crear cuenta de usuario
      {_caller, :signUp, user} ->
        IO.puts "#{inspect self} :signUp (server)"
        loop(
          %ChatServer{
            name: server.name, 
            users: Map.put(server.users, _caller, user.name),
            chats: server.chats,
            sqChatsId: server.sqChatsId
          }
        )

      #crear conversacion entre usuarios tipo privada 
      {_caller, :createPrivateChat, user1, user2} ->
        IO.puts "#{inspect self} :createPrivateChat (server)"
        nextChatId = server.sqChatsId + 1;
        pidChat = startPrivateChat(nextChatId, [user1, user2])
        newChats = Map.put(server.chats, nextChatId, pidChat)
        Enum.each([user1, user2], fn(pidUser) -> send(pidUser,{self, :notifyAddChat, nextChatId}) end)
        loop(
          %ChatServer{
            name: server.name,
            users: server.users,
            chats: newChats,
            sqChatsId: nextChatId
          }
        )

      #crear conversacion entre usuarios tipo grupal
      {_caller, :createGroupChat, owner, members} ->
        IO.puts "#{inspect self} :createGroupChat (server)"
        nextChatId = server.sqChatsId + 1;
        newChats = Map.put(server.chats, nextChatId, startGroupChat(nextChatId, owner, members))
        Enum.each([owner| members], fn(pidUser) -> send(pidUser,{self, :notifyAddChat, nextChatId}) end)
        loop(
          %ChatServer{
            name: server.name,
            users: server.users,
            chats: newChats,
            sqChatsId: nextChatId
          }
        )

      #crear conversacion entre usuarios tipo broadcast
      {_caller, :createBroadcastChat, owner, users} ->
        IO.puts "#{inspect self} :createBroadcastChat (server)"

      #envia mensaje a rx de parte de tx
      {_caller, :deliverMsg, msg} ->
        IO.puts "#{inspect self} :deliverMsg (server)"
        chat = Map.get(server.chats, msg.chat)
        send(chat, {self, :deliverMsg, msg})
        loop(server)
      
      #notifica a rx de que tx esta escribiendo en el chat
      {_caller, :notifyWriting, msg} ->
        IO.puts "#{inspect self} :notifyWriting (server)"
        pidChat = Map.get(server.chats, msg.chat)
        send(pidChat, {self, :notifyWriting, msg})
        loop(server)

      #notificacion de msg recibido exitoso por el destinatario
      {_caller, :notifyRx, msg} ->
        IO.puts "#{inspect self} :notifyRx (server)"
        pidChat = Map.get(server.chats, msg.chat)
        send(pidChat, {self, :notifyRx, msg})
        loop(server)
    
      #notificacion de msg fue leido por el destinatario
      {_caller, :notifyRead, msg} ->
        IO.puts "#{inspect self} :notifyRead (server)"
        pidChat = Map.get(server.chats, msg.chat)
        send(pidChat, {self, :notifyRead, msg})
        loop(server)
    end
  end


  defp startPrivateChat(chatId, users) do
    {:ok, pidChat} = Chat.startPrivate(chatId, users)
    pidChat
  end

  defp startGroupChat(chatId, owner, members) do
    {:ok, pidChat} = Chat.startGroup(chatId, [owner|members])
    pidChat
  end
end

#modulo usuario de conversacion
defmodule ChatUser do
  defstruct [ 
    quietUsers: [] #pid
  ]
end


#modulo status de mensaje en conversacion
defmodule ChatMessage do
  defstruct [
    id: 0,
    readers: [],
    receivers: [] 
  ]
end

#modulo conversacion
defmodule Chat do
  defstruct [
    id: nil, 
    users: %{}, #pid -> chatUser
    messages: %{}, #id msg -> ChatMessage
    sqMessagesId: 0
  ]

  def startPrivate(chatId, users) do
    chat = %Chat{
      id: chatId,
      users: mapUsers(users, %{})
    }
    Task.start_link(fn-> loop(chat) end)
  end

  def startGroup(chatId, users) do
    chat = %Chat{
      id: chatId,
      users: mapUsers(users, %{})
    }
    Task.start_link(fn-> loop(chat) end)
  end

  defp mapUsers([pidUser | tail], map) do
    mapUsers(tail, Map.put(map, pidUser, %ChatUser{}))
  end

  defp mapUsers([], map) do
    map
  end

  defp loop(chat) do
    receive do
      #notifica a rx de que tx esta escribiendo en el chat
      {_caller, :notifyWriting, msg} ->
        IO.puts "#{inspect self} :notifyWriting (chat)"
        Enum.each(
          filterUserToTx(chat.users, msg.tx), 
          fn(pidRx) -> send(pidRx, {self, :notifyWriting, msg}) end
        )
        loop(chat)

      #notificacion de msg recibido exitoso por el destinatario
      {_caller, :notifyRx, serverMsg} ->
        IO.puts "#{inspect self} :notifyRx (chat)"
        olderMsg = Map.get(chat.messages, serverMsg.id)
        newReceivers = [serverMsg.rx | olderMsg.receivers]
        if everybodyDoIt?(chat, serverMsg, newReceivers) do
          send(serverMsg.tx, {self, :notifyRx, serverMsg})
        end
        loop(
          %Chat{
            sqMessagesId: chat.sqMessagesId,
            id: chat.id,
            users: chat.users,
            messages: Map.put(
              chat.messages, 
              olderMsg.id, 
              %ChatMessage{id: olderMsg.id, readers: olderMsg.readers, receivers: newReceivers}
            )
          }
        )

      #notificacion de msg leido por un destinatario
      {_caller, :notifyRead, serverMsg} ->
        IO.puts "#{inspect self} :notifyRead (chat)"
        olderMsg = Map.get(chat.messages, serverMsg.id)
        newReaders = [serverMsg.rx | olderMsg.readers]
        if everybodyDoIt?(chat, serverMsg, newReaders) do
          send(serverMsg.tx, {self, :notifyRead, serverMsg})
        end
        loop(
          %Chat{
            sqMessagesId: chat.sqMessagesId,
            id: chat.id,
            users: chat.users,
            messages: Map.put(
              chat.messages, 
              olderMsg.id, 
              %ChatMessage{id: olderMsg.id, readers: newReaders, receivers: olderMsg.receivers}
            )
          }
        )
      

      #envia mensaje a rx de parte de tx
      {_caller, :deliverMsg, serverMsg} ->
        IO.puts "#{inspect self} :deliverMsg (chat)"
        nextMessageId = chat.sqMessagesId + 1
        newMsg = %ServerMessage{id: nextMessageId, tx: serverMsg.tx, chat: serverMsg.chat, content: serverMsg.content}
        send(serverMsg.tx, {self,:notifyTx, newMsg})
        Enum.each(filterUserToTx(chat.users, serverMsg.tx), fn(userRx) -> send(userRx, {self, :receiveMsg, newMsg}) end)
        loop(
          %Chat{
            sqMessagesId: nextMessageId,
            id: chat.id,
            users: chat.users,
            messages: Map.put(chat.messages, nextMessageId, %ChatMessage{ id: nextMessageId})
          }
        )
    end
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
end
