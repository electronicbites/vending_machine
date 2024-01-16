defmodule VendingMachineWeb.Router do
  use VendingMachineWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :api_auth do
    plug VendingMachineWeb.UserAuth
  end

  scope "/api", VendingMachineWeb do
    pipe_through :api
    post "/login", UserSessionController, :create
    delete "/logout", UserSessionController, :delete
  end

  # scope "/api", VendingMachineWeb do
  #  pipe_through [:browser, :api_auth]
  #  resources "/products", ProductsController
  # end
end
