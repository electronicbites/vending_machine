defmodule VendingMachine.Selling.Product do
  use Ecto.Schema
  import Ecto.Changeset

  schema "products" do
    field :amount_available, :integer
    field :cost, :integer
    field :product_name, :string

    belongs_to :user, VendingMachine.Accounts.User
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(product, attrs) do
    product
    |> cast(attrs, [:amount_available, :cost, :product_name, :user_id])
    |> validate_required([:amount_available, :cost, :product_name, :user_id])
  end
end
