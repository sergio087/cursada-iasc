defmodule Tx do
	def start do
		spawn_link(fn -> loop end)
	end

	defp loop do
		receive do
			{caller, :enviar, target, msg } -> 
				IO.puts "*** tx :enviar"
				send target, {self(), :notificar_escribiendo, nil}
				:timer.sleep(2000)
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
		spawn_link(fn -> loop([],[]) end)
	end

	defp loop(list_mensajes, list_silencio) do
		receive do
			{caller, :recibir,  msg} ->
				#IO.puts "*** rx :recibir"
				if (List.keymember?(list_silencio,caller,0)) do
					loop( list_mensajes, list_silencio)
				else
					send caller, {self(), :enviado_ok, self(), msg}
					loop( [ {caller, msg} | list_mensajes], list_silencio)
				end
				

			{caller, :messages, _} ->
				IO.puts("#{inspect list_mensajes}")
				loop([], list_silencio) 

			{caller, :notificar_escribiendo, _} ->
				#IO.puts "*** rx :notificar_escribiendo"
				IO.puts "#{inspect caller} escribiendo..."
				loop(list_mensajes, list_silencio)

			{caller, :silenciar, true} ->
				loop(list_mensajes, [ {caller, true} | list_silencio])

			{caller, :silenciar, false} ->
				loop(list_mensajes, List.keydelete(list_silencio, caller, 0) )

		end
	end
end


defmodule Chat do
	def leer(rx_pid) do
		send rx_pid, {self(), :messages, nil}
	end
end
