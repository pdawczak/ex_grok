defmodule ExGrok.Connection do
  @docmodule """
  It manages ngrok connection.

  It spawns new ngrok executable and looks after it. In case ngrok stops
  responding it will try to spawn new one.
  """
  use GenServer

  require Logger

  alias ExGrok.NgrokLogParser

  defstruct port: nil, http_url: nil, https_url: nil

  ######
  # Public API

  @doc """
  Starts connection server.
  """
  def start_link do
    GenServer.start_link(__MODULE__, [], name: :connection)
  end

  @doc """
  It returns connection information.

  It will either:

    * return `{:ok, connection_information}` if connected successfully
    * raise due to timeout trying to establish the connection
  """
  def connect do
    GenServer.call(:connection, :status)
  end

  ######
  # Callbacks

  @doc false
  def init(_) do
    port = open_port(Application.get_env(:ex_grok, :command))

    send(self(), :port_health_check)

    {:ok, new(port)}
  end

  # It delegates replying with connection information to one of the following
  # `handle_info` callbacks.
  @doc false
  def handle_call(:status, from, connection) do
    send(self(), {:connected, from})
    {:noreply, connection}
  end

  # If the connection has been established - replies with connection information.
  @doc false
  def handle_info({:connected, from}, %{http_url: http_url, https_url: https_url} = connection)
  when http_url != nil
  and https_url != nil do
    GenServer.reply(from, {:ok, connection})
    {:noreply, connection}
  end

  # If the connection has NOT been established - will schedule retry in 100 milliseconds.
  @doc false
  def handle_info({:connected, _from} = msg, connection) do
    Process.send_after(self(), msg, 100)
    {:noreply, connection}
  end

  # It handles the messages that arrive from `port`.
  @doc false
  def handle_info({port, {:data, data}}, %{port: port} = connection) do
    data
    |> String.trim()
    |> String.split("\n")
    |> Enum.map(&NgrokLogParser.parse/1)
    |> Enum.each(&extract_connection_info/1)

    {:noreply, connection}
  end

  # It stops gen_server in case of connection failure detected.
  @doc false
  def handle_info({:failed_to_connect, reason}, connection) do
    {:stop, reason, connection}
  end

  @doc false
  def handle_info({:set_config, "http:" <> _rest = url}, connection) do
    {:noreply, Map.put(connection, :http_url, url)}
  end

  @doc false
  def handle_info({:set_config, "https:" <> _rest = url}, connection) do
    {:noreply, Map.put(connection, :https_url, url)}
  end

  # Performs periodic check on port opened.
  #
  # It schedules next health_check in 3 secs if port is alive, otherwise it
  # stops the gen_server.
  @doc false
  def handle_info(:port_health_check, %{port: port} = connection) do
    case Port.info(port) do
      nil ->
        {:stop, "ngrok port doesn't respond", connection}

      _ ->
        Process.send_after(self(), :port_health_check, 3_000)
        {:noreply, connection}
    end
  end

  ###
  # Private functions

  defp new(port) do
    %__MODULE__{port: port}
  end

  defp open_port(opts) do
    Port.open(
      {:spawn, prepare_command(opts)},
      [:binary]
    )
  end

  defp prepare_command(opts) do
    exec = Keyword.get(opts, :executable, "ngrok")
    port = Keyword.get(opts, :port, "4000")

    "#{exec} http -log stdout -log-level debug -log-format logfmt #{port}"
  end

  defp extract_connection_info({:ok, %{"lvl" => "eror", "err" => reason}}) do
    send(self(), {:failed_to_connect, reason})
  end

  @log_url_data_pattern  ~r{([\w\s]+URL:)(?<url>[\w\:\/\.]+)}

  defp extract_connection_info({:ok, %{"lvl" =>"dbug", "resp" => body}}) do
    @log_url_data_pattern
    |> Regex.named_captures(body)
    |> set_config()
  end

  defp extract_connection_info(_) do
  end

  defp set_config(%{"url" => url}) do
    send(self(), {:set_config, url})
  end

  defp set_config(_) do
  end
end
