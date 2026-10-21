defmodule CaptainNotes.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    CaptainNotes.Performance.attach()

    :persistent_term.put(
      {CaptainNotesWeb.DeploymentController, :version},
      Base.url_encode64(:crypto.strong_rand_bytes(18), padding: false)
    )

    children = [
      CaptainNotes.Repo,
      {Ecto.Migrator, repos: [CaptainNotes.Repo]},
      CaptainNotes.Auth,
      CaptainNotes.Pronote.ReadCache,
      CaptainNotes.Pronote.ReadRefresh,
      CaptainNotes.Pronote.Session,
      {Registry, keys: :unique, name: CaptainNotes.Pronote.Registry},
      {DynamicSupervisor, strategy: :one_for_one, name: CaptainNotes.Pronote.Supervisor},
      {Phoenix.PubSub, name: CaptainNotes.PubSub},
      {Task.Supervisor, name: CaptainNotes.RefreshTasks},
      CaptainNotes.NotificationBanners,
      CaptainNotes.Push.Worker,
      CaptainNotes.Pronote.BackgroundRefresh,
      # Start a worker by calling: CaptainNotes.Worker.start_link(arg)
      # {CaptainNotes.Worker, arg},
      # Start to serve requests, typically the last entry
      CaptainNotesWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CaptainNotes.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    CaptainNotesWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
