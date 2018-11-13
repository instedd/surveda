# Ask

## Dockerized development

To get started checkout the project, then execute `./dev-setup.sh`

To run the app: `docker-compose up`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

To open a shell in a container: `docker exec -it ask_db_1 bash`, where `ask_db_1` is a container name. You can list containers with `docker ps`.

To start an Elixir console in your running Phoenix app container: `docker exec -it ask_app_1 iex -S mix`.

## Exposing your containers as *.ask.dev

You can use [dockerdev](https://github.com/waj/dockerdev) to access the web app at `app.ask.dev` and ngrok at `ngrok.ask.dev`.

Just follow the instructions at the README of dockerdev.

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