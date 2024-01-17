defmodule VendingMachineWeb.SellingControllerTest do
  use VendingMachineWeb.ConnCase

  import VendingMachine.AccountsFixtures

  @valid_amount 100
  @invalid_amount 42

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "GET /api/deposit - buyer" do
    setup :setup_buyer

    test "returns success for valid deposition", %{conn: conn, api_token: api_token} do
      conn = get(conn,  ~p"/api/deposit", api_token: api_token, amount: @valid_amount)
      assert json_response(conn, 200) == %{"success" => true}
    end

    test "returns bad data  for bad amounts", %{conn: conn, api_token: api_token} do
      conn = get(conn,  ~p"/api/deposit", api_token: api_token, amount: @invalid_amount)
      assert json_response(conn, 400) == %{"success" => false}
    end
  end

  describe "GET /api/deposit - seller" do
    setup :setup_seller

    test "returns bad data when user is a seller", %{conn: conn, api_token: api_token} do
      conn = get(conn,  ~p"/api/deposit", api_token: api_token, amount: @valid_amount)
      assert json_response(conn, 400) == %{"success" => false}
    end
  end

  defp setup_buyer(_) do
    user = user_fixture(role: "buyer")
    api_token = user
    |> VendingMachine.Accounts.generate_user_api_token()
    |> Base.url_encode64(padding: false)
    %{user: user, api_token: api_token}
  end

  defp setup_seller(_) do
    user = user_fixture(role: "seller")
    api_token = user
    |> VendingMachine.Accounts.generate_user_api_token()
    |> Base.url_encode64(padding: false)
    %{user: user, api_token: api_token}
  end
end
