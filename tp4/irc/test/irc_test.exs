defmodule IRCTest do
  use ExUnit.Case
  doctest IRC

  test "the truth" do
    assert 1 + 1 == 2
  end

  test "start a server" do
  	assert ({:ok, _} = IRC.start(%IRC{name: "IRC"}))
  end

  test "register a user" do
  	IO.puts("\ntest - register a user")
  	{:ok, pidServer} = IRC.start(%IRC{name: "IRC"})
	{:ok, pidManolito} = User.start(%User{name: "Manolito", msgsByChats: %{}, server: pidServer})

	serverIRC = GenServer.call(pidServer, {:getState})

	assert Map.has_key?(serverIRC.users, pidManolito)	
  end

  test "create a private chat" do
  	IO.puts("\ntest - create a private chat")
  	{:ok, pidServer} = IRC.start(%IRC{name: "IRC"})
  	{:ok, pidManolito} = User.start(%User{name: "Manolito", msgsByChats: %{}, server: pidServer})
  	{:ok, pidSusanita} = User.start(%User{name: "Susanita", msgsByChats: %{}, server: pidServer})

	{:ok, chatId} = GenServer.call(pidServer, {:createPrivateChat, pidManolito, pidSusanita})

	userManolito = GenServer.call(pidManolito, {:getState})
	userSusanita = GenServer.call(pidSusanita, {:getState})
	serverIRC = GenServer.call(pidServer, {:getState})

	assert Map.has_key?(userSusanita.msgsByChats, chatId) && Map.has_key?(userManolito.msgsByChats, chatId) && Map.has_key?(serverIRC.chats, chatId)
  end

  test "create a group chat" do
  	IO.puts("\ntest - create a group chat")
  	{:ok, pidServer} = IRC.start(%IRC{name: "IRC"})
  	{:ok, pidManolito} = User.start(%User{name: "Manolito", msgsByChats: %{}, server: pidServer})
  	{:ok, pidSusanita} = User.start(%User{name: "Susanita", msgsByChats: %{}, server: pidServer})
  	{:ok, pidFelipe} = User.start(%User{name: "Felipe", msgsByChats: %{}, server: pidServer})
  	{:ok, pidMafalda} = User.start(%User{name: "Mafalda", msgsByChats: %{}, server: pidServer})

  	{:ok, chatId} = GenServer.call(pidServer, {:createGroupChat, pidManolito, [pidSusanita, pidFelipe, pidMafalda]})

  	userManolito = GenServer.call(pidManolito, {:getState})
	userMafalda = GenServer.call(pidMafalda, {:getState})
	serverIRC = GenServer.call(pidServer, {:getState})

  	assert Map.has_key?(userMafalda.msgsByChats, chatId) && Map.has_key?(userManolito.msgsByChats, chatId) && Map.has_key?(serverIRC.chats, chatId)
  end

  test "send a message on private chat" do
  	IO.puts("\ntest - send a message on private chat")
  	{:ok, pidServer} = IRC.start(%IRC{name: "IRC"})
  	{:ok, pidManolito} = User.start(%User{name: "Manolito", msgsByChats: %{}, server: pidServer})
  	{:ok, pidSusanita} = User.start(%User{name: "Susanita", msgsByChats: %{}, server: pidServer})

	{:ok, chatId} = GenServer.call(pidServer, {:createPrivateChat, pidManolito, pidSusanita})

	msg = %IRC.Message{id: nil, tx: pidManolito, chat: 1, content: "Hola Susanita!"}

	GenServer.cast(pidManolito, {:sendMsg, msg})

	:timer.sleep(3500) #por el tiempo q se toman para escribir

	userManolito = GenServer.call(pidManolito, {:getState})
	chatManolito = Map.get(userManolito.msgsByChats, chatId)
	msjManolito = Map.get(chatManolito, 1, nil)
	userSusanita = GenServer.call(pidSusanita, {:getState})
	chatSusanita = Map.get(userSusanita.msgsByChats, chatId)
	serverIRC = GenServer.call(pidServer, {:getState})

	IO.puts("Manolito\n#{inspect userManolito}\n")

	IO.puts("Susanita\n#{inspect userSusanita}\n")

	assert Map.get(chatSusanita, 1, nil) != nil && msjManolito.notifyRx && msjManolito.notifyTx
  end

  test "send a message on group chat" do
  	IO.puts("\ntest - send a message on group chat")
  	{:ok, pidServer} = IRC.start(%IRC{name: "IRC"})
  	{:ok, pidManolito} = User.start(%User{name: "Manolito", msgsByChats: %{}, server: pidServer})
  	{:ok, pidSusanita} = User.start(%User{name: "Susanita", msgsByChats: %{}, server: pidServer})
  	{:ok, pidFelipe} = User.start(%User{name: "Felipe", msgsByChats: %{}, server: pidServer})
  	{:ok, pidMafalda} = User.start(%User{name: "Mafalda", msgsByChats: %{}, server: pidServer})

  	{:ok, chatId} = GenServer.call(pidServer, {:createGroupChat, pidManolito, [pidSusanita, pidFelipe, pidMafalda]})

	msg = %IRC.Message{id: nil, tx: pidManolito, chat: 1, content: "Hola a todos!"}

	GenServer.cast(pidManolito, {:sendMsg, msg})

	:timer.sleep(3500) #por el tiempo q se toman para escribir

	userManolito = GenServer.call(pidManolito, {:getState})
	chatManolito = Map.get(userManolito.msgsByChats, chatId)
	msjManolito = Map.get(chatManolito, 1, nil)
	userSusanita = GenServer.call(pidSusanita, {:getState})
	chatSusanita = Map.get(userSusanita.msgsByChats, chatId)
	userFelipe = GenServer.call(pidFelipe, {:getState})
	userMafalda = GenServer.call(pidMafalda, {:getState})
	serverIRC = GenServer.call(pidServer, {:getState})

	IO.puts("\nManolito\n#{inspect userManolito}")
	IO.puts("\nSusanita\n#{inspect userSusanita}")
	IO.puts("\nMafalda\n#{inspect userMafalda}")
	IO.puts("\nFelipe\n#{inspect userFelipe}")

	assert Map.get(chatSusanita, 1, nil) != nil && msjManolito.notifyRx && msjManolito.notifyTx
  end
  
test "read a message in a private chat" do
	IO.puts("\ntest - read a message in a private chat")
  	{:ok, pidServer} = IRC.start(%IRC{name: "IRC"})
  	{:ok, pidManolito} = User.start(%User{name: "Manolito", msgsByChats: %{}, server: pidServer})
  	{:ok, pidSusanita} = User.start(%User{name: "Susanita", msgsByChats: %{}, server: pidServer})
	{:ok, chatId} = GenServer.call(pidServer, {:createPrivateChat, pidManolito, pidSusanita})
	msg = %IRC.Message{id: nil, tx: pidManolito, chat: 1, content: "Hola Susanita!"}
	GenServer.cast(pidManolito, {:sendMsg, msg})

	:timer.sleep(3500) #por el tiempo q se toman para escribir

	GenServer.cast(pidSusanita, {:readMsg, chatId})

	:timer.sleep(1000) #por el tiempo q se toman para leer

	userManolito = GenServer.call(pidManolito, {:getState})
	chatManolito = Map.get(userManolito.msgsByChats, chatId)
	msjManolito = Map.get(chatManolito, 1, nil)
	userSusanita = GenServer.call(pidSusanita, {:getState})
	chatSusanita = Map.get(userSusanita.msgsByChats, chatId)
	msjSusanita = Map.get(chatSusanita, 1, nil)

	IO.puts("\nManolito\n#{inspect userManolito}")
	IO.puts("\nSusanita\n#{inspect userSusanita}")
	
	assert msjManolito.notifyRead && msjSusanita.notifyRead
end

test "someone reads a message in a group chat " do
	IO.puts("\ntest - any group member reads a message in a group chat")
  	{:ok, pidServer} = IRC.start(%IRC{name: "IRC"})
  	{:ok, pidManolito} = User.start(%User{name: "Manolito", msgsByChats: %{}, server: pidServer})
  	{:ok, pidSusanita} = User.start(%User{name: "Susanita", msgsByChats: %{}, server: pidServer})
  	{:ok, pidFelipe} = User.start(%User{name: "Felipe", msgsByChats: %{}, server: pidServer})
  	{:ok, pidMafalda} = User.start(%User{name: "Mafalda", msgsByChats: %{}, server: pidServer})
  	{:ok, chatId} = GenServer.call(pidServer, {:createGroupChat, pidManolito, [pidSusanita, pidFelipe, pidMafalda]})
	msg = %IRC.Message{id: nil, tx: pidManolito, chat: 1, content: "Hola a todos!"}

	GenServer.cast(pidManolito, {:sendMsg, msg})

	:timer.sleep(3500) #por el tiempo q se toman para escribir

	GenServer.cast(pidSusanita, {:readMsg, chatId})

	:timer.sleep(1000) #por el tiempo q se toman para leer

	userManolito = GenServer.call(pidManolito, {:getState})
	chatManolito = Map.get(userManolito.msgsByChats, chatId)
	msjManolito = Map.get(chatManolito, 1, nil)
	userSusanita = GenServer.call(pidSusanita, {:getState})
	chatSusanita = Map.get(userSusanita.msgsByChats, chatId)
	msjSusanita = Map.get(chatSusanita, 1, nil)
	userFelipe = GenServer.call(pidFelipe, {:getState})
	userMafalda = GenServer.call(pidMafalda, {:getState})
	chatMafalda = Map.get(userMafalda.msgsByChats, chatId)
	msjMafalda = Map.get(chatMafalda, 1, nil)
	serverIRC = GenServer.call(pidServer, {:getState})

	IO.puts("\nManolito\n#{inspect userManolito}")
	IO.puts("\nSusanita\n#{inspect userSusanita}")
	IO.puts("\nMafalda\n#{inspect userMafalda}")
	IO.puts("\nFelipe\n#{inspect userFelipe}")

	assert !msjManolito.notifyRead && msjSusanita.notifyRead && !msjMafalda.notifyRead
end


test "everyone read a message in a group chat " do
	IO.puts("\ntest - everyone read a message in a group chat")
  	{:ok, pidServer} = IRC.start(%IRC{name: "IRC"})
  	{:ok, pidManolito} = User.start(%User{name: "Manolito", msgsByChats: %{}, server: pidServer})
  	{:ok, pidSusanita} = User.start(%User{name: "Susanita", msgsByChats: %{}, server: pidServer})
  	{:ok, pidFelipe} = User.start(%User{name: "Felipe", msgsByChats: %{}, server: pidServer})
  	{:ok, pidMafalda} = User.start(%User{name: "Mafalda", msgsByChats: %{}, server: pidServer})
  	{:ok, chatId} = GenServer.call(pidServer, {:createGroupChat, pidManolito, [pidSusanita, pidFelipe, pidMafalda]})
	msg = %IRC.Message{id: nil, tx: pidManolito, chat: 1, content: "Hola a todos!"}

	GenServer.cast(pidManolito, {:sendMsg, msg})

	:timer.sleep(3500) #por el tiempo q se toman para escribir

	GenServer.cast(pidSusanita, {:readMsg, chatId})
	GenServer.cast(pidFelipe, {:readMsg, chatId})
	GenServer.cast(pidMafalda, {:readMsg, chatId})

	:timer.sleep(1000) #por el tiempo q se toman para leer

	userManolito = GenServer.call(pidManolito, {:getState})
	chatManolito = Map.get(userManolito.msgsByChats, chatId)
	msjManolito = Map.get(chatManolito, 1, nil)
	userSusanita = GenServer.call(pidSusanita, {:getState})
	chatSusanita = Map.get(userSusanita.msgsByChats, chatId)
	msjSusanita = Map.get(chatSusanita, 1, nil)
	userFelipe = GenServer.call(pidFelipe, {:getState})
	userMafalda = GenServer.call(pidMafalda, {:getState})
	chatMafalda = Map.get(userMafalda.msgsByChats, chatId)
	msjMafalda = Map.get(chatMafalda, 1, nil)
	serverIRC = GenServer.call(pidServer, {:getState})

	IO.puts("\nManolito\n#{inspect userManolito}")
	IO.puts("\nSusanita\n#{inspect userSusanita}")
	IO.puts("\nMafalda\n#{inspect userMafalda}")
	IO.puts("\nFelipe\n#{inspect userFelipe}")

	assert msjManolito.notifyRead && msjSusanita.notifyRead && msjMafalda.notifyRead
end

end
