defmodule VendingMachineWeb.UserAuth do
  @moduledoc """
  This module provides functions to log in and log out users.
  """
  use VendingMachineWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller

  alias VendingMachine.Accounts

  # Make the remember me cookie valid for 60 days.
  # If you want bump or reduce this value, also change
  # the token expiry itself in UserToken.
  @max_age 60 * 60 * 24 * 60

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
  def log_in_user(conn, user, params \\ %{}) do
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

  defp ensure_user_token(conn) do
    if token = get_session(conn, :user_token) do
      {token, conn}
    else
      conn = fetch_cookies(conn, signed: [@remember_me_cookie])

      if token = conn.cookies[@remember_me_cookie] do
        {token, put_token_in_session(conn, token)}
      else
        {nil, conn}
      end
    end
  end

  @doc """

  """
  def render_unauthorized(conn) do
    conn
    |> put_status(401)
    |> put_view(json: VendingMachineWeb.ErrorJSON)
    |> render(:"401")
    |> halt()
  end

  @doc """
  Used for routes that require the user to be authenticated.

  If you want to enforce the user email is confirmed before
  they use the application at all, here would be a good place.
  """
  def require_authenticated_user(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_flash(:error, "You must log in to access this page.")
      |> maybe_store_return_to()
      |> redirect(to: ~p"/users/log_in")
      |> halt()
    end
  end

  defp put_token_in_session(conn, token) do
    conn
    |> put_session(:user_token, token)
  end

  defp maybe_store_return_to(%{method: "GET"} = conn) do
    put_session(conn, :user_return_to, current_path(conn))
  end

  defp maybe_store_return_to(conn), do: conn

  defp signed_in_path(_conn), do: ~p"/"
end
