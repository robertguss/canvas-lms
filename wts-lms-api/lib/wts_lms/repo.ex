defmodule WtsLms.Repo do
  use Ecto.Repo,
    otp_app: :wts_lms_api,
    adapter: Ecto.Adapters.Postgres
end
