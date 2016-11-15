defmodule ExGrok.Server do
  use GenServer

  require Logger

  ######
  # Public API

  def start_link do
    GenServer.start_link(__MODULE__, [], name: :server)
  end

  ######
  # Callbacks

  def init(_) do
    {:ok, connection} = ExGrok.Connection.connect()

    %{http_url: http_url, https_url: https_url} = connection

    Logger.info("ngrok connection established - #{http_url}, #{https_url}")

    {:ok, connection}
  end
end
