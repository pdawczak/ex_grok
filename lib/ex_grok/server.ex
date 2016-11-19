defmodule ExGrok.Server do
  use GenServer

  alias ExGrok.Connection

  require Logger

  ######
  # Public API

  @doc false
  def start_link do
    GenServer.start_link(__MODULE__, [], name: :server)
  end

  @doc """
  Returns ngrok connection.

  It contains information about `http` and `https` urls opened.
  """
  @spec connection :: Connection.t
  def connection do
    GenServer.call(:server, :connection)
  end

  ######
  # Callbacks

  @doc false
  def init(_) do
    {:ok, connection} = ExGrok.Ngrok.connect()

    %{http_url: http_url, https_url: https_url} = connection

    _ = Logger.info("ngrok connection established - #{http_url}, #{https_url}")

    {:ok, connection}
  end

  @doc false
  def handle_call(:connection, _from, connection) do
    {:reply, connection, connection}
  end
end
