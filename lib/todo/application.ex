defmodule Todo.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      TodoWeb.Telemetry,
      Todo.Repo,
      {DNSCluster, query: Application.get_env(:todo, :dns_cluster_query) || :ignore},
      # Ensure that only one Phoenix.PubSub is started
      {Phoenix.PubSub, name: Todo.PubSub}, # Correct name key here
      {Finch, name: Todo.Finch},
      TodoWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Todo.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    TodoWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
