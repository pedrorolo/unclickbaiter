defmodule Unclickbaiter.Repo do
  use Ecto.Repo,
    otp_app: :unclickbaiter,
    adapter: Ecto.Adapters.Postgres
end
