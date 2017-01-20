defmodule Ask.Router do
  use Ask.Web, :router
  use Coherence.Router
  use Plug.ErrorHandler
  use Sentry.Plug

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Plug.Static, at: "files/", from: "web/static/assets/files/"
    plug Coherence.Authentication.Session
  end

  pipeline :protected do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Coherence.Authentication.Session, protected: true
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session

    #plug Guardian.Plug.VerifyHeader
    #plug Guardian.Plug.LoadResource
  end

  scope "/", Ask do
    pipe_through :browser
    get "/oauth_client/callback", OAuthClientController, :callback

    coherence_routes
    
    get "/*path", PageController, :index      
    # add public resources below
  end

  scope "/" do
    pipe_through :protected
    coherence_routes :protected
  end


  if Mix.env == :dev do
    forward "/sent_emails", Bamboo.EmailPreviewPlug
  end

  scope "/api" , Ask do
    pipe_through :api

    scope "/v1" do
      get "/timezones", TimezoneController, :timezones
      resources "/projects", ProjectController, except: [:new, :edit] do
        resources "/surveys", SurveyController, except: [:new, :edit] do
          post "/launch", SurveyController, :launch
          resources "/respondents", RespondentController, only: [:index]
          resources "/respondent_groups", RespondentGroupController, only: [:index, :create, :update, :delete]
          get "/respondents/stats", RespondentController, :stats, as: :respondents_stats
          get "/respondents/quotas_stats", RespondentController, :quotas_stats, as: :respondents_quotas_stats
          get "/respondents/csv", RespondentController, :csv, as: :respondents_csv
        end
        resources "/questionnaires", QuestionnaireController, except: [:new, :edit] do
          get "/export_zip", QuestionnaireController, :export_zip, as: :questionnaires_export_zip
          post "/import_zip", QuestionnaireController, :import_zip, as: :questionnaires_import_zip
        end
        get "/autocomplete_vars", ProjectController, :autocomplete_vars, as: :autocomplete_vars
        get "/autocomplete_primary_language", ProjectController, :autocomplete_primary_language, as: :autocomplete_primary_language
        get "/autocomplete_other_language", ProjectController, :autocomplete_other_language, as: :autocomplete_other_language
        get "/collaborators", ProjectController, :collaborators, as: :collaborators
      end
      resources "/channels", ChannelController, except: [:new, :edit]
      resources "/audios", AudioController, only: [:create, :show]
      resources "/authorizations", OAuthClientController, only: [:index, :delete]
      get "/authorizations/synchronize", OAuthClientController, :synchronize
      get "/accept_invitation", InviteController, :accept_invitation, as: :accept_invitation
      get "/invite", InviteController, :invite, as: :invite
      get "/invite_mail", InviteController, :invite_mail, as: :invite_mail
      get "/invite_show", InviteController, :show, as: :invite_show
    end
  end

  get "/audio/:id", Ask.AudioDeliveryController, :show
  get "/callbacks/:provider", Ask.CallbackController, :callback
  post "/callbacks/:provider", Ask.CallbackController, :callback
end
