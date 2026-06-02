defmodule WtsLmsApi.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [WtsLms.Repo]

    Supervisor.start_link(children, strategy: :one_for_one, name: WtsLmsApi.Supervisor)
  end
end
