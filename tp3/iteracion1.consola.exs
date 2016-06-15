rx = Rx.start
tx = Tx.start
Process.alive?tx
Process.alive?rx
send tx, {self(), :enviar, rx, "hola"}
send rx, {self(), :messages, ""}
send rx, {tx, :silenciar, true}
send tx, {self(), :enviar, rx, "estas?"}
send rx, {tx, :silenciar, false}
