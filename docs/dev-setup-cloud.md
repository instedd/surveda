# HOW-TO: Setup dev environment with InSTEDD cloud servers

This guide describes the steps needed to have a development environment that will use InSTEDD staging servers for

* Guisso as single-sign-on: https://login-stg.instedd.org
* Verboise for making phone calls: https://verboice-stg.instedd.org
* Nuntium for sending and receiving https://nuntium-stg.instedd.org

1. Install [dockerdev](https://github.com/waj/dockerdev)
2. Checkout the project
3. Execute `$ ./dev-setup.sh`
4. `$ docker-compose up ngrok`
    * NOTE: if `ngrok` container is restarted the assigned tunnel URL will change and it will need to be updated in config and in Guisso.
5. Go to `http://ngrok.surveda.lvh.me/` and grab the tunnel URL: like `https://ef6e48ea.ngrok.io`.
6. Setup [Guisso](https://login-stg.instedd.org) with:
    * Any hostname, no need to be `app.surveda.lvh.me`
    * Redirect urls `http://app.surveda.lvh.me/session/oauth_callback`, `http://app.surveda.lvh.me/oauth_client/callback` (one per line)
    * No need to be trusted
    * Keep the identifier `MY_SURVEDA_GUISSO_CLIENT_ID` and secret `MY_SURVEDA_GUISSO_CLIENT_SECRET`.

7. Create `config/local.exs` file

```exs
use Mix.Config

ngrok_base_url = "https://ef6e48ea.ngrok.io" # TODO Replace
my_surveda_guisso_client_id = "MY_SURVEDA_GUISSO_CLIENT_ID" # TODO Replace
my_surveda_guisso_client_secret = "MY_SURVEDA_GUISSO_CLIENT_SECRET" # TODO Replace

config :alto_guisso,
  enabled: true,
  base_url: "https://login-stg.instedd.org",
  client_id: my_surveda_guisso_client_id,
  client_secret: my_surveda_guisso_client_secret

config :ask, AskWeb.Endpoint,
  url: [host: "app.surveda.lvh.me"]

config :ask, Verboice,
  base_url: "https://verboice-stg.instedd.org/",
  base_callback_url: ngrok_base_url,
  channel_ui: true,
  guisso: [
    base_url: "https://login-stg.instedd.org",
    client_id: my_surveda_guisso_client_id,
    client_secret: my_surveda_guisso_client_secret,
    app_id: "verboice-stg.instedd.org"
  ]

config :ask, Nuntium,
  base_url: "https://nuntium-stg.instedd.org/",
  base_callback_url: ngrok_base_url,
  channel_ui: true,
  guisso: [
    base_url: "https://login-stg.instedd.org",
    client_id: my_surveda_guisso_client_id,
    client_secret: my_surveda_guisso_client_secret,
    app_id: "nuntium-stg.instedd.org"
  ]
```

8. `$ docker-compose up db`
9. `$ docker-compose up app webpack`

Launching the containers in different consoles will allow you to restart `app` and `webpack` without changing the ngrok url.

## Use the app

1. Go to `$ open http://app.surveda.lvh.me`

## Register Verboice channel

1. In Verboice register Callcentric channel https://www.youtube.com/watch?v=CkJsub2YnWo
2. Download [a soft phone client](https://www.callcentric.com/support/device/?category=desktop). A couple of suggestions are [Linphone](http://www.linphone.org/) ir [Zopier5](https://www.callcentric.com/support/device/zoiper/v5)
3. Open surveda via ngrok `$ open http://app.surveda.lvh.me`
4. Log in to surveda and add verboice and nuntium in the channels section.

## Register Nuntium channel

You can create a qst client channel in Nuntium and manually send/receive messages from the Nuntium UI as show in https://youtu.be/pYsZLLOZ4Ks
