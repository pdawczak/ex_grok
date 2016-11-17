defmodule ExGrok.Application do
  @moduledoc false
  use Application

  def start(_type, _args) do
    children = children_per_env(Mix.env)

    opts = [strategy: :one_for_one, name: ExGrok.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp children_per_env(:dev) do
    import Supervisor.Spec, warn: false

    [supervisor(ExGrok.MasterSupervisor, [])]
  end

  defp children_per_env(_) do
    []
  end
end
