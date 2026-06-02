ExUnit.start()

try do
  Ecto.Adapters.SQL.Sandbox.mode(WtsLms.Repo, :manual)
rescue
  _error -> :ok
end
