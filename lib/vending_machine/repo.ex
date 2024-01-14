defmodule VendingMachine.Repo do
  use Ecto.Repo,
    otp_app: :vending_machine,
    adapter: Ecto.Adapters.Postgres
end
