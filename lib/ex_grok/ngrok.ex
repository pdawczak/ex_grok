defmodule ExGrok.Ngrok do
  @moduledoc """
  Manages ngrok port.

  It spawns new ngrok executable and looks after it. In case ngrok stops
  responding it will try to spawn new one.
  """
  use GenServer

  require Logger

  alias ExGrok.{Connection, Ngrok, NgrokLogParser, NgrokMonitor}

  defstruct port: nil, conn: %Connection{}

  @type t :: %__MODULE__{
    port: port,
    conn: Connection.t
  }

  ######
  # Public API

  @doc false
  def start_link do
    GenServer.start_link(__MODULE__, [], name: :ngrok)
  end

  @doc """
  Returns connection information.

  It will either:

    * return `{:ok, connection}` if connected successfully
    * raise due to timeout trying to establish the connection
  """
  @spec connect :: {:ok, Connection.t}
  def connect do
    GenServer.call(:ngrok, :status)
  end

  ######
  # Callbacks

  @doc false
  def init(_) do
    port = open_port(command_opts())

    {:ok, _ref} = :timer.send_interval(3_000, :port_health_check)

    {:ok, _pid} = NgrokMonitor.start(self(), port)

    {:ok, new(port)}
  end

  # It delegates replying with connection information to one of the following
  # `handle_info` callbacks.
  @doc false
  def handle_call(:status, from, state) do
    send(self(), {:connected, from})
    {:noreply, state}
  end

  # If the connection:
  #
  #     * has been established - replies with connection information.
  #     * has NOT been established - will schedule retry in 100 milliseconds.
  @doc false
  def handle_info({:connected, from} = msg, %{conn: conn} = state) do
    if Connection.established?(conn) do
      GenServer.reply(from, {:ok, conn})
      {:noreply, state}
    else
      Process.send_after(self(), msg, 100)
      {:noreply, state}
    end
  end

  # It handles the messages that arrive from `port`.
  @doc false
  def handle_info({port, {:data, data}}, %{port: port} = state) do
    data
    |> String.trim()
    |> String.split("\n")
    |> Enum.map(&NgrokLogParser.parse/1)
    |> Enum.each(&extract_info/1)

    {:noreply, state}
  end

  # It stops gen_server in case of connection failure detected.
  @doc false
  def handle_info({:failed_to_connect, reason}, state) do
    {:stop, reason, state}
  end

  @doc false
  def handle_info({:set_config, "http:" <> _rest = url}, %{conn: conn} = state) do
    new_conn = %{conn | http_url: url}
    {:noreply, %{state | conn: new_conn}}
  end

  @doc false
  def handle_info({:set_config, "https:" <> _rest = url}, %{conn: conn} = state) do
    new_conn = %{conn | https_url: url}
    {:noreply, %{state | conn: new_conn}}
  end

  # Performs periodic check on port opened.
  #
  # It schedules next health_check in 3 secs if port is alive, otherwise it
  # stops the gen_server.
  @doc false
  def handle_info(:port_health_check, %{port: port} = state) do
    case Port.info(port) do
      nil ->
        {:stop, "ngrok port doesn't respond", state}

      _ ->
        {:noreply, state}
    end
  end

  @doc false
  def handle_info(_msg, state) do
    {:noreply, state}
  end

  ###
  # Private functions

  @spec new(port) :: Ngrok.t
  defp new(port) do
    %__MODULE__{
      port: port,
      conn: Connection.new()
    }
  end

  @spec open_port(keyword) :: port
  defp open_port(opts) do
    Port.open(
      {:spawn, prepare_command(opts)},
      [:binary]
    )
  end

  @spec prepare_command(keyword) :: String.t
  defp prepare_command(opts) do
    exec = Keyword.get(opts, :executable, "ngrok")
    port = Keyword.get(opts, :port, "4000")

    "#{exec} http -log stdout -log-level debug -log-format logfmt #{port}"
  end

  @log_url_data_pattern  ~r{([\w\s]+URL:)(?<url>[\w\:\/\.]+)}

  @spec extract_info(NgrokLogParser.result) :: no_return
  defp extract_info(result)

  defp extract_info({:ok, %{"lvl" => "eror", "err" => reason}}) do
    send(self(), {:failed_to_connect, reason})
  end
  defp extract_info({:ok, %{"lvl" =>"dbug", "resp" => body}}) do
    @log_url_data_pattern
    |> Regex.named_captures(body)
    |> set_config()
  end
  defp extract_info(_) do
  end

  @spec set_config(map) :: no_return
  defp set_config(map)

  defp set_config(%{"url" => url}) do
    send(self(), {:set_config, url})
  end
  defp set_config(_) do
  end

  @spec command_opts :: keyword
  defp command_opts do
    Application.get_env(
      :ex_grok,
      :command,
      []
    )
  end
end
