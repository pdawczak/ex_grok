defmodule ExGrok do
  @moduledoc """
  Main module providing access to the ngrok service.

  ex_grok takes care about opening new ngrok connection.

  Once ngrok connection is succesfully esablised, the information about current
  connection can be easily obtained by:

      iex> ExGrok.connection()
      %ExGrok.Connection{http_url: "http://1234.ngrok.io",
                         https_url: "https://123.ngrok.io"}

  Currently, starting ngrok is mandatory for starting whole application up, thus
  it doesn't provide facility reporting failed connection as this is never the
  case.
  """

  alias ExGrok.{Connection, Server}

  @doc """
  Provides ngrok connection information.
  """
  @spec connection :: Connection.t
  def connection do
    Server.connection()
  end
end
