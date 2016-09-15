defmodule Ask.Router do
  use Ask.Web, :router
  use Addict.RoutesHelper

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
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
      resources "/projects", ProjectController, except: [:new, :edit] do
        resources "/surveys", SurveyController, except: [:new, :edit] do
          post "/launch", SurveyController, :launch
          resources "/respondents", RespondentController, only: [:create, :index]
          get "/respondents/stats", RespondentController, :stats, as: :respondents_stats
        end
        resources "/questionnaires", QuestionnaireController, except: [:new, :edit]
      end
      resources "/channels", ChannelController, except: [:new, :edit]
    end
  end

  scope "/", Ask do
    pipe_through :browser

    get "/oauth_helper", OAuthHelperController, :index
    get "/*path", PageController, :index
  end
end
