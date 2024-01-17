defmodule VendingMachineWeb.ProductController do
  use VendingMachineWeb, :controller

  alias VendingMachine.Selling
  alias VendingMachine.Selling.Product
  alias VendingMachineWeb.UserAuth

  action_fallback VendingMachineWeb.FallbackController

  def index(conn, _params) do
    products = Selling.list_products()
    render(conn, :index, products: products)
  end

  def create(conn, %{"product" => product_params, "api_token" => api_token}) do
    user = UserAuth.fetch_user_by_api_token(api_token)
    if String.equivalent?(user.role, "seller") do
      product_params = Map.put(product_params, "user_id", user.id)
      with {:ok, %Product{} = product} <- Selling.create_product(product_params) do
        conn
        |> put_status(:created)
        |> put_resp_header("location", ~p"/api/products/#{product}")
        |> render(:show, product: product)
      end
    else
      UserAuth.render_unauthorized(conn)
    end
  end

  def show(conn, %{"id" => id}) do
    product = Selling.get_product!(id)
    render(conn, :show, product: product)
  end

  def update(conn, %{"id" => id, "product" => product_params, "api_token" => api_token}) do
    user = UserAuth.fetch_user_by_api_token(api_token)
    product = Selling.get_product!(id)
    if product.user_id == user.id do
      with {:ok, %Product{} = product} <- Selling.update_product(product, product_params) do
        render(conn, :show, product: product)
      end
    else
      UserAuth.render_unauthorized(conn)
    end
  end

  def delete(conn, %{"id" => id, "api_token" => api_token}) do
    user = UserAuth.fetch_user_by_api_token(api_token)
    product = Selling.get_product!(id)
    if product.user_id == user.id do
      with {:ok, %Product{}} <- Selling.delete_product(product) do
        send_resp(conn, :no_content, "")
      end
      else
      UserAuth.render_unauthorized(conn)
    end
  end
end
