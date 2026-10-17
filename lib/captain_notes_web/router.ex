defmodule CaptainNotesWeb.Router do
  use CaptainNotesWeb, :router

  pipeline :browser do
    plug :accepts, ["html", "json"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {CaptainNotesWeb.Layouts, :root}
    plug CaptainNotesWeb.CSRFProtection
    plug :put_secure_browser_headers
  end

  pipeline :authenticated do
    plug CaptainNotesWeb.Auth
  end

  scope "/", CaptainNotesWeb do
    pipe_through :browser
    get "/app-version", DeploymentController, :show
    get "/login", LoginController, :index
    post "/login", LoginController, :create
    post "/logout", LoginController, :delete
  end

  scope "/", CaptainNotesWeb do
    pipe_through [:browser, :authenticated]

    get "/push/config", PushController, :config
    get "/push/badge", PushController, :badge
    post "/push/subscription", PushController, :create
    delete "/push/subscription", PushController, :delete

    get "/avatars/:index", AvatarController, :show

    live_session :authenticated, on_mount: [CaptainNotesWeb.Auth] do
      live "/:child/:section/new", MessageComposeLive, :new
      live "/:child/:section/:discussion/reply", MessageComposeLive, :reply
      live "/", DashboardLive, :index
      live "/:child", DashboardLive, :index
      live "/:child/:section", DashboardLive, :index
      live "/:child/:section/:discussion", DashboardLive, :index
    end
  end
end
