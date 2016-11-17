defmodule ExGrok.MasterSupervisor do
  @moduledoc false
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: :master_supervisor)
  end

  def init(_) do
    children = [
      worker(ExGrok.Connection, []),
      worker(ExGrok.Server, [])
    ]

    supervise(children, strategy: :rest_for_one)
  end
end
