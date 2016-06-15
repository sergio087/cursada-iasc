defmodule Tx do
	def start do
		spawn_link(fn -> loop end)
	end

	defp loop do
		receive do
			{caller, :enviar, target, msg } -> 
				IO.puts "*** tx :enviar"
				send target, {self(), :recibir, msg}
				loop
			{caller, :enviado_ok, target, msg } -> 
				IO.puts "*** tx :enviado_ok"
				IO.puts "echo #{msg}"
				loop
		end
	end
end


defmodule Rx do
	def start do
		spawn_link(fn -> loop([]) end)
	end

	defp loop(list) do
		receive do
			{caller, :recibir,  msg} ->
				IO.puts "*** rx :recibir"
				send caller, {self(), :enviado_ok, self(), msg}
				loop( [ {caller, msg} | list])
			{caller, :messages, _} ->
				IO.puts("#{inspect list}")
				loop([])
		end
	end
end


defmodule Chat do
	def leer(rx_pid) do
		send rx_pid, {self(), :messages, nil}
	end
end
