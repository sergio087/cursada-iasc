
#instancio actores principales
{:ok, pidServer} = ChatServer.start(%ChatServer{name: "IRC", users: %{}})
{:ok, pidManolito} = User.start(%User{name: "Manolito", msgsByChats: %{}, server: pidServer})
{:ok, pidSusanita} = User.start(%User{name: "Susanita", msgsByChats: %{}, server: pidServer})
{:ok, pidMafalda} = User.start(%User{name: "Mafalda", msgsByChats: %{}, server: pidServer})
{:ok, pidFelipe} = User.start(%User{name: "Felipe", msgsByChats: %{}, server: pidServer})
send pidServer, {self, :serverInfo}

#instancio conversaciones entre usuarios
send(pidServer, {self, :createPrivateChat, pidManolito, pidSusanita})  #chatId = 1
send pidSusanita, {self, :userInfo}
send pidManolito, {self, :userInfo}


send(pidServer, {self, :createGroupChat, pidManolito, [pidMafalda, pidFelipe]}) #chat_id = 2
send pidManolito, {self, :userInfo}
send pidFelipe, {self, :userInfo}
send pidMafalda, {self, :userInfo}

#los usuarios se envian msj entre si a traves de conversacion privada

send pidManolito, {self, :sendMsg, %ServerMessage{id: nil, tx: pidManolito, chat: 1, content: "Hola Susanita!"}}
send pidSusanita, {self, :userInfo}
send pidManolito, {self, :userInfo}

send pidManolito, {self, :sendMsg, %ServerMessage{id: nil, tx: pidManolito, chat: 1, content: "estas?"}}

send pidSusanita, {self, :readMsgs, 1}

send pidSusanita, {self, :userInfo}
send pidManolito, {self, :userInfo}


#los usuarios se envian msj entre si a traves de conversacion grupal
send pidManolito, {self, :sendMsg, %ServerMessage{id: nil, tx: pidManolito, chat: 2, content: "Hola a todos!"}}
send pidManolito, {self, :userInfo}
send pidFelipe, {self, :userInfo}
send pidMafalda, {self, :userInfo}

send pidMafalda, {self, :readMsgs, 2}
send pidFelipe, {self, :readMsgs, 2}
send pidManolito, {self, :userInfo}

send pidMafalda, {self, :sendMsg, %ServerMessage{id: nil, tx: pidMafalda, chat: 2, content: "Como va Manolito?"}}