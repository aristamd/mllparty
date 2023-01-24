defmodule MLLPartyWeb.Router do
  use MLLPartyWeb, :router

  pipeline :api do
    plug :accepts, ["json"]

    plug MLLPartyWeb.Plug.APIKeyBasicAuth,
      api_key: {Application, :fetch_env!, [:mllparty, :api_key]}
  end

  scope "/api", MLLPartyWeb do
    pipe_through :api

    get "/connections", ConnectionController, :list
    post "/mllp_messages", MLLPMessageController, :send
  end

  # Enable LiveDashboard in development
  if Application.compile_env(:mllparty, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: MLLPartyWeb.Telemetry
    end
  end
end
