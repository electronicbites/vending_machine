defmodule VendingMachineWeb.UserSessionController do
  use VendingMachineWeb, :controller

  alias VendingMachine.Accounts
  alias VendingMachineWeb.UserAuth

  def create(conn, %{"user" => user_params}) do
    %{"username" => username, "password" => password} = user_params
    if user = Accounts.get_user_by_username_and_password(username, password) do
      conn
      |> UserAuth.log_in_user(user, user_params)
    else
      conn
      |> put_status(401)
      |> json(%{type: "login failed"})
    end
  end

  def delete(conn, params) do
    conn
    |> UserAuth.log_out_user(params)
  end
end
