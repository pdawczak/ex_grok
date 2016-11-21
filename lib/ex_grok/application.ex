defmodule ExGrok.Application do
  @moduledoc false
  use Application

  def start(_type, _args) do
    opts = [strategy: :one_for_one, name: ExGrok.Supervisor]
    Supervisor.start_link(children(), opts)
  end

  defp children do
    import Supervisor.Spec, warn: false

    if enabled? do
      [supervisor(ExGrok.MasterSupervisor, [])]
    else
      []
    end
  end

  defp enabled? do
    Application.get_env(
      :ex_grok,
      :enabled,
      default_enabled(Mix.env)
    )
  end

  defp default_enabled(:dev), do: true
  defp default_enabled(_),    do: false
end
