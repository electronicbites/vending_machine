defmodule VendingMachineWeb.ProductControllerTest do
  use VendingMachineWeb.ConnCase

  import VendingMachine.AccountsFixtures
  import VendingMachine.SellingFixtures

  alias VendingMachine.Selling.Product

  @create_attrs %{
    amount_available: 42,
    cost: 42,
    product_name: "some product_name"
  }
  @update_attrs %{
    amount_available: 43,
    cost: 43,
    product_name: "some updated product_name"
  }
  @invalid_attrs %{amount_available: nil, cost: nil, product_name: nil}

  setup %{conn: conn} do
    user = user_fixture()
    api_token = user
    |> VendingMachine.Accounts.generate_user_api_token()
    |> Base.url_encode64(padding: false)
    {:ok, conn: put_req_header(conn, "accept", "application/json"), user: user, api_token: api_token}
  end

  describe "index" do
    test "lists all products", %{conn: conn} do
      conn = get(conn, ~p"/api/products")
      assert json_response(conn, 200)["data"] == []
    end

    test "lists all products with data", %{conn: conn} do
      create_product(nil)
      conn = get(conn, ~p"/api/products")
      data = json_response(conn, 200)["data"]
      assert Enum.fetch!(data, 0)["product_name"]  == "some product_name"
    end
  end

  describe "create product" do
    test "renders product when data is valid", %{conn: conn, api_token: api_token} do
      conn = post(conn, ~p"/api/products", product: @create_attrs, api_token: api_token)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/products/#{id}")

      assert %{
               "id" => ^id,
               "amount_available" => 42,
               "cost" => 42,
               "product_name" => "some product_name"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, api_token: api_token} do
      conn = post(conn, ~p"/api/products", product: @invalid_attrs, api_token: api_token)
      assert json_response(conn, 422)["errors"] != %{}
    end

    test "renders errors when api token is mising", %{conn: conn} do
      conn = post(conn, ~p"/api/products", product: @invalid_attrs)
      assert json_response(conn, 401)["errors"] != %{}
    end
  end

  describe "update product" do
    setup [:create_product]

    test "renders product when data is valid", %{conn: conn, api_token: api_token, product: %Product{id: id} = product} do
      conn = put(conn, ~p"/api/products/#{product}", product: @update_attrs, api_token: api_token)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/products/#{id}")

      assert %{
               "id" => ^id,
               "amount_available" => 43,
               "cost" => 43,
               "product_name" => "some updated product_name"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, api_token: api_token, product: product} do
      conn = put(conn, ~p"/api/products/#{product}", product: @invalid_attrs, api_token: api_token)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete product" do
    setup [:create_product]

    test "deletes chosen product", %{conn: conn, api_token: api_token, product: product} do
      conn = delete(conn, ~p"/api/products/#{product}", api_token: api_token)
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/products/#{product}")
      end
    end
  end

  defp create_product(_) do
    product = product_fixture()
    %{product: product}
  end
end
