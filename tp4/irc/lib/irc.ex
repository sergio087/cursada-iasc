defmodule IRC.Message do
    defstruct id: 0, tx: nil, rx: nil, chat: nil, content: ""
end

defmodule IRC do
  use GenServer

  defstruct [
    name: "", 
    users: %{}, #pid -> name
    chats: %{}, #name -> pid
    sqChatsId: 0
  ]

  def start(server) do
    GenServer.start_link(__MODULE__, server, [])
  end

  defp startPrivateChat(chatId, users) do
    {:ok, pidChat} = Chat.start(chatId, users)
    pidChat
  end

  defp startGroupChat(chatId, owner, members) do
    {:ok, pidChat} = Chat.start(chatId, [owner|members])
    pidChat
  end


  ## Server Callbacks
  def init(server) do
    {:ok, server}
  end

  def handle_call({:getState}, _from, server) do
    {:reply, server, server}
  end

  def handle_call({:signUp, userPid, userData}, _from, server) do
    IO.puts "#{inspect self} :signUp (server)"
    {:reply, :ok, %__MODULE__{
                        name: server.name, 
                        users: Map.put(server.users, userPid, userData.name),
                        chats: server.chats,
                        sqChatsId: server.sqChatsId
                      }
    }
  end


  #crea un grupo de chat privado
  def handle_call({:createPrivateChat, pidUser1, pidUser2}, _from, server) do
    IO.puts "#{inspect self} :createPrivateChat (server)"
    nextChatId = server.sqChatsId + 1;
    pidChat = startPrivateChat(nextChatId, [pidUser1, pidUser2])
    newChats = Map.put(server.chats, nextChatId, pidChat)
    Enum.each(
      [pidUser1, pidUser2], 
      fn(pidUser) -> GenServer.cast(pidUser,{:notifyAddChat, nextChatId}) end
    )

    {:reply, {:ok, nextChatId}, %__MODULE__{
                                name: server.name,
                                users: server.users,
                                chats: newChats,
                                sqChatsId: nextChatId
                              }
    }
  end


  #crea un grupo de chat grupal
  def handle_call({:createGroupChat, pidUserOwner, pidUserMembers}, _from, server) do
    IO.puts "#{inspect self} :createGroupChat (server)"
    nextChatId = server.sqChatsId + 1;
    newChats = Map.put(server.chats, nextChatId, startGroupChat(nextChatId, pidUserOwner, pidUserMembers))
    Enum.each(
      [pidUserOwner| pidUserMembers], 
      fn(pidUser) -> GenServer.cast(pidUser,{:notifyAddChat, nextChatId}) end
    )
 
    {:reply, {:ok, nextChatId}, %__MODULE__{
                                name: server.name,
                                users: server.users,
                                chats: newChats,
                                sqChatsId: nextChatId
                              }
    }
  end


  #notifica al usuario tx de que rx esta escribiendo un msg en el chat
  def handle_cast({:notifyWriting, msg}, server) do
    IO.puts "#{inspect self} :notifyWriting (server)"
    pidChat = Map.get(server.chats, msg.chat)
    GenServer.cast(pidChat, {:notifyWriting, msg})
    
    {:noreply, server}
  end


  #envia mensaje a rx de parte de tx en el chat
  def handle_cast({:deliverMsg, msg}, server) do
    IO.puts "#{inspect self} :deliverMsg (server)"
    chat = Map.get(server.chats, msg.chat)
    GenServer.cast(chat, {:deliverMsg, msg})

    {:noreply, server}
  end


  #notificacion de msg recibido exitoso por el destinatario
  def handle_cast({:notifyRx, msg}, server) do
    IO.puts "#{inspect self} :notifyRx (server)"
    pidChat = Map.get(server.chats, msg.chat)
    GenServer.cast(pidChat, {:notifyRx, msg})
    
    {:noreply, server}
  end


  #notificacion de msg fue leido por el destinatario
  def handle_cast({:notifyRead, msg}, server) do
    IO.puts "#{inspect self} :notifyRead (server)"
    pidChat = Map.get(server.chats, msg.chat)
    GenServer.cast(pidChat, {:notifyRead, msg})
    
    {:noreply, server}
  end
end
