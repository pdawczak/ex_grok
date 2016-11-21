defmodule ExGrok.Server do
  @moduledoc """
  Holds `connection` information if the ngrok connection has been established
  successfully.
  """
  use GenServer

  alias ExGrok.{Connection, Ngrok}

  require Logger

  ######
  # Public API

  @doc false
  def start_link do
    GenServer.start_link(__MODULE__, [], name: :server)
  end

  @doc """
  Returns ngrok connection.
  """
  @spec connection :: Connection.t
  def connection do
    GenServer.call(:server, :connection)
  end

  ######
  # Callbacks

  @doc false
  def init(_) do
    {:ok, conn} = Ngrok.connect()

    %{http_url: http_url, https_url: https_url} = conn

    _ = Logger.info("ngrok connection established - #{http_url}, #{https_url}")

    {:ok, conn}
  end

  @doc false
  def handle_call(:connection, _from, conn) do
    {:reply, conn, conn}
  end
end
