{:ok, pidServer} = ChatServer.start(%ChatServer{name: "IRC", users: %{}})
{:ok, pidManolito} = ChatUser.start(%ChatUser{name: "Manolito", msgsByChats: %{}, server: pidServer})
{:ok, pidSusanita} = ChatUser.start(%ChatUser{name: "Susanita", msgsByChats: %{}, server: pidServer})
{:ok, pidMafalda} = ChatUser.start(%ChatUser{name: "Mafalda", msgsByChats: %{}, server: pidServer})
{:ok, pidFelipe} = ChatUser.start(%ChatUser{name: "Felipe", msgsByChats: %{}, server: pidServer})
send pidServer, {self, :serverInfo}


send pidManolito, {self, :sendMsg, %ChatServerMessage{id: nil, tx: pidManolito, rx: pidSusanita, chat: "p2p-manolito2susanita", content: "Hola Susanita!"}}
send pidSusanita, {self, :userInfo}
send pidManolito, {self, :userInfo}

send pidManolito, {self, :sendMsg, %ChatServerMessage{id: nil, tx: pidManolito, rx: pidSusanita, chat: "p2p-manolito2susanita", content: "estas?"}}

send pidSusanita, {self, :readMsgs, "p2p-manolito2susanita"}

send pidSusanita, {self, :userInfo}
send pidManolito, {self, :userInfo}

