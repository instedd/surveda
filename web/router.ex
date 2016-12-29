defmodule Ask.Router do
  use Ask.Web, :router
  use Addict.RoutesHelper
  use Plug.ErrorHandler
  use Sentry.Plug

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Plug.Static,
      at: "files/", from: "web/static/assets/files/", gzip: false
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session

    #plug Guardian.Plug.VerifyHeader
    #plug Guardian.Plug.LoadResource
  end

  scope "/" do
    addict :routes
  end

  scope "/api" , Ask do
    pipe_through :api

    scope "/v1" do
      get "/timezones", TimezoneController, :timezones
      resources "/projects", ProjectController, except: [:new, :edit] do
        resources "/surveys", SurveyController, except: [:new, :edit] do
          post "/launch", SurveyController, :launch
          resources "/respondents", RespondentController, only: [:create, :index, :delete]
          get "/respondents/stats", RespondentController, :stats, as: :respondents_stats
          get "/respondents/quotas_stats", RespondentController, :quotas_stats, as: :respondents_quotas_stats
          get "/respondents/csv", RespondentController, :csv, as: :respondents_csv
        end
        resources "/questionnaires", QuestionnaireController, except: [:new, :edit]
        get "/autocomplete_vars", ProjectController, :autocomplete_vars, as: :autocomplete_vars
        get "/collaborators", ProjectController, :collaborators, as: :collaborators
      end
      resources "/channels", ChannelController, except: [:new, :edit]
      resources "/audios", AudioController, only: [:create, :show]
      resources "/authorizations", OAuthClientController, only: [:index, :delete]
      get "/authorizations/synchronize", OAuthClientController, :synchronize
    end
  end

  get "/audio/:id", Ask.AudioDeliveryController, :show
  get "/callbacks/:provider", Ask.CallbackController, :callback
  post "/callbacks/:provider", Ask.CallbackController, :callback

  scope "/", Ask do
    pipe_through :browser

    get "/oauth_client/callback", OAuthClientController, :callback
    get "/*path", PageController, :index
  end
end
