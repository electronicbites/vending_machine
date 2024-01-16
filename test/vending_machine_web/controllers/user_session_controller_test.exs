defmodule VendingMachineWeb.UserSessionControllerTest do
  use VendingMachineWeb.ConnCase, async: true

  import VendingMachine.AccountsFixtures
  alias VendingMachine.Accounts

  setup %{conn: conn}  do
    conn =
      conn
      |> put_req_header("accept", "application/json")
      |> put_req_header("content-type", "application/json")

    {:ok, conn: conn, user: user_fixture()}
  end

  describe "POST /api/log_in" do
    test "logs the user in", %{conn: conn, user: user} do
      conn =
        post(conn, ~p"/api/login", %{
          "user" => %{"username" => user.username, "password" => valid_user_password()}
        })

      assert json_response(conn, 200)["api_token"] != nil
    end

    test "returns error with invalid credentials", %{conn: conn} do
      conn =
        post(conn, ~p"/api/login", %{
          "user" => %{"username" => "invalid_username", "password" => "invalid_password"}
        })

      assert json_response(conn, 401)["type"] == "login failed"
    end
  end

  describe "DELETE /api/logout" do
    test "logs the user out", %{conn: conn, user: user} do
      api_token = user
      |> Accounts.generate_user_api_token()
      |> Base.url_encode64(padding: false)

      assert api_token == Accounts.get_api_token_by_user(user) |> Base.url_encode64(padding: false)
      conn = delete(conn, ~p"/api/logout", %{"api_token" => api_token})
      assert json_response(conn, 200)["message"] == "Logout successful"
      assert Accounts.get_api_token_by_user(user) == nil

    end

    #debateable
    test "succeeds even if the api token is not given", %{conn: conn} do
      conn = delete(conn, ~p"/api/logout")
      assert json_response(conn, 200)["message"] == "Logout successful"
    end
  end
end
