defmodule Adrenaline.Repo do
  use Ecto.Repo,
    otp_app: :adrenaline,
    adapter: Ecto.Adapters.Postgres
end
