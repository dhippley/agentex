defmodule Agentex.Repo do
  use Ecto.Repo,
    otp_app: :agentex,
    adapter: Ecto.Adapters.Postgres
end
