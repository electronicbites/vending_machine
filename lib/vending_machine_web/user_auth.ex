defmodule VendingMachineWeb.UserAuth do
  @moduledoc """
  This module provides functions to log in and log out users.
  """
  use VendingMachineWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller

  alias VendingMachine.Accounts

  def init(opts) do
    opts
  end

  def call(%Plug.Conn{params: %{"api_token" => api_token}} = conn, _opts) do
    {:ok, api_token} = Base.url_decode64(api_token, padding: false)
    if user = Accounts.get_user_by_api_token(api_token) do
      assign(conn, :user, user)
    else
      render_unauthorized(conn)
    end
  end

  def call(conn, _opts) do
    render_unauthorized(conn)
  end

  @doc """
  Logs the user in.
  """
  def log_in_user(conn, user, _params \\ %{}) do
    token = Accounts.generate_user_api_token(user)
    conn
    |> put_status(200)
    |> json(%{api_token: Base.url_encode64(token, padding: false)})
  end

  @doc """
  Logs the user out.

  It clears the api token from the database.
  """
  def log_out_user(conn, _params = %{"api_token" => api_token}) do
    {:ok, api_token} = Base.url_decode64(api_token, padding: false)
    Accounts.delete_user_api_token(api_token)

    conn
    |> put_status(200)
    |> json(%{message: "Logout successful"})
  end

  def log_out_user(conn, _params) do
    conn
    |> put_status(200)
    |> json(%{message: "Logout successful"})
  end

  def fetch_user_by_api_token(api_token) do
    {:ok, api_token} = Base.url_decode64(api_token, padding: false)
     Accounts.get_user_by_api_token(api_token)
  end

  @doc """
    result after authentication failed
  """
  def render_unauthorized(conn) do
    conn
    |> put_status(401)
    |> put_view(json: VendingMachineWeb.ErrorJSON)
    |> render(:"401")
    |> halt()
  end
end
