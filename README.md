# Surveda

## Dockerized development

To get started checkout the project, then execute `./dev-setup.sh`. There is [a guide](./docs/dev-setup-cloud.md) that can walk you through the setup of a development environment that will use cloud instances of Nuntium and Verboice.

To run the app: `docker-compose up`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

To open a shell in a container: `docker-compose exec db bash`, where `db` is the service name. You can list the services `docker-compose ps --services`.

To start an Elixir console in your running Phoenix app container: `docker-compose exec app iex -S mix`.

## Exposing your containers as *.surveda.lvh.me

You can use [dockerdev](https://github.com/waj/dockerdev) to access the web app at `app.surveda.lvh.me` and ngrok at `ngrok.surveda.lvh.me`.

Just follow the instructions at the README of dockerdev.

**WARNING:** You should install `dockerdev` _before_ creating your stack's network in Docker. If you have already run `./dev-setup.sh`, you may want to run `docker-compose down -v` to **delete every container, data and other artifacts** from the project and start from scratch _after_ running `dockerdev`.

## Linting and Formatting

To help us keep a consistent coding style, we're using StandardJS. Follow their instructions to install it: http://standardjs.com/#install

If you're using Sublime, you can setup a Build System that will use StandardJS to format your code when you hit `Ctrl+B`. To do so:

1. In Sublime, go to `Tools -> Build System -> New Build System...`
1. A file will open, replace its contents with:

```
{
  "cmd": ["standard", "--fix", "$file"],
  "selector": "source.js"
}
```
1. Save. That's it. When you want to format, just hit `Ctrl+B`. Note that the formatter is a bit slow, so it's not a good idea to format on save.

## IVR channels with Verboice

To setup a channel you need to create it using the console. For that you need to create a channel with the folowing settings:

```
%Ask.Channel{name: "Channel name",
  provider: "verboice",
  settings: %{
    "channel" => "Verboice Channel name in Verboice",
    "username" => "Your Verboice username",
    "password" => "Your Verboice password",
    "url" => "http://verboice.instedd.org"
  },
  type: "ivr",
  user_id: your ask user id
}
```

In order for it to work, that Verboice channel must be associated to a dummy flow of a dummy Verboice project. Otherwise it will fail and won't log anything.

## GUISSO

You need GUISSO to access Verboice and/or Nuntium channels.

Get a working GUISSO instance (online, or hosted on your development machine) and create a new Application. If it's a local Guisso instance, use `app.surveda.lvh.me` as the domain, and this two redirect URIs:

```
http://app.surveda.lvh.me/session/oauth_callback
http://app.surveda.lvh.me/oauth_client/callback
```

To work with a cloud GUISSO, make sure your `ngrok` service is running (`docker-compose up ngrok`), and get your ngrok domain visiting `http://ngrok.surveda.lvh.me`. Fill the Application information as for the local case, but using the ngrok domain instead. When you restart your `ngrok` service, you will need to update this information before approving new authorizations in GUISSO.

On your local surveda directory, create a `config/local.exs` file like below, including the client ID & secret from your Application in GUISSO:

```
use Mix.Config

config :alto_guisso,
  enabled: true,
  base_url: "http://web.guisso.lvh.me", # or https://login-stg.instedd.org for a cloud GUISSO
  client_id: "<your app's client id in guisso>",
  client_secret: "<your app's client secret in guisso>",

config :ask, Ask.Endpoint,
  url: [host: "app.surveda.lvh.me"] # or "abcd123.ngrok.io" for a cloud GUISSO
```

### Verboice Channel

Once you have GUISSO enabled on Surveda, you can connect a Verboice instance that's already registered with GUISSO by adding this fragment to your `config/local.exs`:

```
config :ask, Verboice,
  base_url: "http://web.verboice.lvh.me", # or the URL for your Verboice instance
  channel_ui: true,
  base_callback_url: "http://abcd123.ngrok.io", # specify the base URL to use on channel callbacks if it's not the same as the host
  guisso: [
    base_url: "http://web.guisso.lvh.me", # or the URL for your GUISSO
    client_id: "<Surveda's client id>",
    client_secret: "<Surveda's client secret>",
    app_id: "web.verboice.lvh.me" # or your Verboice APP ID in GUISSO
  ]
```

## Coherence

### Upgrading

We're using Coherence to support registration, authorization, and other user management flows.
If you need to upgrade the version of Coherence that Ask uses, there are some steps that you need to mind.
Please check them out here: https://github.com/smpallen99/coherence#upgrading

### Coherence Mails

Coherence uses Swoosh as it's mailer lib. In development, we use Swoosh's local adapter, which
mounts a mini email client that displays sent emails at `{BASE_URL}/dev/mailbox`. That comes handy
to test flows which depend on email without having to send them in development.

## Intercom

Surveda supports Intercom as its CRM platform. To load the Intercom chat widget, simply start Surveda with the env variable `INTERCOM_APP_ID` set to your Intercom app id (https://www.intercom.com/help/faqs-and-troubleshooting/getting-set-up/where-can-i-find-my-workspace-id-app-id).

Surveda will forward any conversation with a logged user identifying them through their email address. Anonymous, unlogged users will also be able to communicate.

If you don't want to use Intercom, you can simply omit `INTERCOM_APP_ID` or set it to `''`.

To test the feature in development, add the `INTERCOM_APP_ID` variable and its value to the `environment` object inside the `app` service in `docker-compose.yml`.

## InSTEDD's url shortener

Surveda uses InSTEDD's [shorter](https://github.com/instedd/shorter) for sending urls to respondents when web-mobile mode is used.

Is necessary to configure an api-key in surveda to use this service. If no api-key is provided, surveda works fine but
full-urls are sent to respondents

For editing/creating a new api-key:
1. Go to AWS console
2. Go to API Gateway service
3. Select Usage-Plans
4. Select "Surveda Shorter" plan
5. Edit or create under "API Keys" tab

## Screen resolutions

The minimum supported screen resolution is 1366x768.
Mobile devices and screen resolutions less than 1366x768 are not supported.
