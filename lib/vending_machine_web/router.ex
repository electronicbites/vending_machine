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
    resources "/products", ProductController, only: [:show, :index]
  end

  scope "/api", VendingMachineWeb do
    pipe_through [:api, :api_auth]
    resources "/products", ProductController, except: [:show, :index]
  end
end
