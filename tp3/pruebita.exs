defmodule Pruebita do
  def start do
    spawn_link(fn -> loop end)
  end

  defp loop do
    receive do
      {caller, :msg, arg1} -> IO.puts ""
      {caller, :msg2, arg1, arg2} -> IO.puts ""
    end
    loop
  end

end
