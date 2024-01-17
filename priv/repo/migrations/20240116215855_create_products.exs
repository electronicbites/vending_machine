defmodule VendingMachine.Repo.Migrations.CreateProducts do
  use Ecto.Migration

  def change do
    create table(:products) do
      add :amount_available, :integer
      add :cost, :integer
      add :product_name, :string
      add :user_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:products, [:user_id])
  end
end
