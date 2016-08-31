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
        resources "/surveys", SurveyController, except: [:new, :edit]
      end
    end
  end

  scope "/", Ask do
    pipe_through :browser

    get "/*path", PageController, :index
  end
end
