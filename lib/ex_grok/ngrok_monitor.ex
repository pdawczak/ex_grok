defmodule ExGrok.NgrokMonitor do
  @moduledoc """
  Monitros `ExGrok.Ngrok` process.

  As managing `ngrok` port through `ExGrok.Ngrok` is very time sensitive, this
  module takes takes care about monitoring the gen_server, and attempting to
  `kill` `ngrok` so it doesn't cause any problems when restarting the server.
  """
  use GenServer

  #####
  # Public API

  @doc """
  Starts monitoring process for ngrok manager.
  """
  @spec start(pid, port) :: GenServer.on_start
  def start(pid, port) do
    GenServer.start(__MODULE__, {pid, port})
  end

  #####
  # Callbacks

  @doc false
  def init({pid, port}) do
    case Port.info(port, :os_pid) do
      nil ->
        {:stop, "No os_pid to handle"}

      {:os_pid, os_pid} ->
        Process.monitor(pid)

        {:ok, {pid, os_pid}}
    end
  end

  @doc false
  def handle_info(
    {:DOWN, _ref, :process, pid, _reason},
    {pid, os_pid} = state
  ) do
    kill(os_pid)

    {:stop, :normal, state}
  end

  @doc false
  def handle_info(_msg, state) do
    {:noreply, state}
  end

  #####
  # Private functions

  @spec kill(integer) :: no_return
  defp kill(os_pid) do
    "kill -9 #{os_pid}"
    |> String.to_char_list()
    |> :os.cmd()
  end
end
