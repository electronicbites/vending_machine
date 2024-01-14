defmodule VendingMachine.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      VendingMachineWeb.Telemetry,
      VendingMachine.Repo,
      {DNSCluster, query: Application.get_env(:vending_machine, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: VendingMachine.PubSub},
      # Start the Finch HTTP client for sending emails
      # {Finch, name: VendingMachine.Finch},
      # Start a worker by calling: VendingMachine.Worker.start_link(arg)
      # {VendingMachine.Worker, arg},
      # Start to serve requests, typically the last entry
      VendingMachineWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: VendingMachine.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    VendingMachineWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
