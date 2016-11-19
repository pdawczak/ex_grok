defmodule ExGrok.Connection do
  @moduledoc """
  Provides information about connection establised by ngrok.
  """

  defstruct http_url: nil, https_url: nil

  alias ExGrok.Connection

  @type t :: %__MODULE__{
    http_url: String.t,
    https_url: String.t
  }

  @doc """
  Returns new empty `ExGrok.Connection` struct.
  """
  @spec new :: Connection.t
  def new, do: %__MODULE__{}

  @doc """
  Determines by information stored in `connection` if the ngrok connection has
  been successfully established.
  """
  @spec established?(Connection.t) :: boolean
  def established?(%__MODULE__{http_url: http_url, https_url: https_url}) do
    http_url != nil && https_url != nil
  end
end
