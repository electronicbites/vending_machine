defmodule VendingMachineWeb.SellingController do
  use VendingMachineWeb, :controller

  alias VendingMachine.Accounts
  alias VendingMachineWeb.UserAuth

  action_fallback VendingMachineWeb.FallbackController

  def deposit(conn, %{"api_token" => api_token, "amount" => amount}) do
    result = api_token
    |> UserAuth.fetch_user_by_api_token()
    |> Accounts.deposit(String.to_integer(amount))

    render_result_for_deposit(conn, result)
  end

  def buy(conn, %{"_action" => "buy"} = _params) do
    conn
    |> put_status(200)
    |> json(%{success: true})
  end

  defp render_result_for_deposit(conn, {:ok, _}) do
    conn
    |> put_status(200)
    |> json(%{success: true})
  end

  defp render_result_for_deposit(conn, {:error}) do
    conn
    |> put_status(400)
    |> json(%{success: false})
  end

end
