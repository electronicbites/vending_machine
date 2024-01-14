defmodule VendingMachineWeb.Router do
  use VendingMachineWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", VendingMachineWeb do
    pipe_through :api
  end
end
