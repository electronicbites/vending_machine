defmodule VendingMachine.SellingTest do
  use VendingMachine.DataCase

  alias VendingMachine.Selling
  import VendingMachine.AccountsFixtures
  import VendingMachine.SellingFixtures

  describe "products" do
    alias VendingMachine.Selling.Product


    @invalid_attrs %{amount_available: nil, cost: nil, product_name: nil}

    test "list_products/0 returns all products" do
      product = product_fixture()
      assert Selling.list_products() == [product]
    end

    test "get_product!/1 returns the product with given id" do
      product = product_fixture()
      assert Selling.get_product!(product.id) == product
    end

    test "create_product/1 with valid data creates a product" do
      valid_attrs = %{amount_available: 42, cost: 42, product_name: "some product_name", user_id: user_fixture().id}

      assert {:ok, %Product{} = product} = Selling.create_product(valid_attrs)
      assert product.amount_available == 42
      assert product.cost == 42
      assert product.product_name == "some product_name"
    end

    test "create_product/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Selling.create_product(@invalid_attrs)
    end

    test "update_product/2 with valid data updates the product" do
      product = product_fixture()
      update_attrs = %{amount_available: 43, cost: 43, product_name: "some updated product_name"}

      assert {:ok, %Product{} = product} = Selling.update_product(product, update_attrs)
      assert product.amount_available == 43
      assert product.cost == 43
      assert product.product_name == "some updated product_name"
    end

    test "update_product/2 with invalid data returns error changeset" do
      product = product_fixture()
      assert {:error, %Ecto.Changeset{}} = Selling.update_product(product, @invalid_attrs)
      assert product == Selling.get_product!(product.id)
    end

    test "delete_product/1 deletes the product" do
      product = product_fixture()
      assert {:ok, %Product{}} = Selling.delete_product(product)
      assert_raise Ecto.NoResultsError, fn -> Selling.get_product!(product.id) end
    end

    test "change_product/1 returns a product changeset" do
      product = product_fixture()
      assert %Ecto.Changeset{} = Selling.change_product(product)
    end
  end
end
