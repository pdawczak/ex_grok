defmodule ExGrok.Connection do
  defstruct http_url: nil, https_url: nil

  alias ExGrok.Connection

  @type t :: %__MODULE__{
    http_url: String.t,
    https_url: String.t
  }

  @spec new :: Connection.t
  def new, do: %__MODULE__{}

  @spec established?(Connection.t) :: boolean
  def established?(%__MODULE__{http_url: http_url, https_url: https_url}) do
    http_url != nil && https_url != nil
  end
end
