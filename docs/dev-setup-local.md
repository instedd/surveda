# HOW-TO: setup dev environment with local services

Surveda requires some external services to work properly:

- [Guisso](https://github.com/instedd/guisso) for single-sign-on across the services;
- [Verboice](https://github.com/instedd/verboice) for making phone calls (IVR);
- [Nuntium](https://github.com/instedd/nuntium) for sending and receiving text messages (SMS).

They can be used from the cloud (see [dev-setup-cloud.md](dev-setup-cloud.md))
or be installed and configured locally.


## Setup


### Install [dockerdev](https://github.com/waj/dockerdev)

This isn't necessary, but installing [dockerdev](https://github.com/waj/dockerdev)
will greatly improve your experience, by using the `*.lvh.me` domain to access
services and for services to talk between themselves.


### Install [Guisso](https://github.com/instedd/guisso)

1. Checkout the repository and build the Docker images:

  ```console
  $ git clone git@github.com:instedd/guisso.git
  $ cd guisso/
  $ docker-compose run --rm web bundle
  $ docker-compose run --rm web rake db:create db:setup
  $ docker-compose up web
  ```

2. Navigate to <http://web.guisso.lvh.me> and create an account;

3. We now need to create three applications:

  ```
  app=Nuntium  host=web.nuntium.lvh.me
  app=Verboice host=web.verboice.lvh.me
  app=Surveda  host=app.surveda.lvh.me
  ```

  Make sure to configure each application with the same two redirect URIs (one
  per line). They must be on each application, because Surveda will create
  access tokens for Verboice and Nuntium on their behalf:

  ```
  http://app.surveda.lvh.me/session/oauth_callback
  http://app.surveda.lvh.me/oauth_client/callback
  ```


### Install [Verboice](https://github.com/instedd/verboice)

1. Checkout the repository and build the Docker images:

  ```console
  $ git clone git@github.com:instedd/verboice.git
  $ cd verboice/
  $ docker-compose run --rm web bundle
  $ docker-compose run --rm web rake db:create db:setup
  ```

2. Enable Guisso by editing (or creating) `config/guisso.yml`, copying the
  client id and secret from http://web.guisso.lvh.me for the Verboice app:

  ```yaml
  enabled: true
  url: "http://web.guisso.lvh.me"
  client_id: ""
  client_secret: ""
  ```

3. Startup verboice:

  ```console
  $ docker-compose up web broker asterisk
  ```

4. Navigate to <http://web.verboice.lvh.me> and authenticate using Guisso.

5. You may create a Project, but I don't know whether this is required. Maybe
   Surveda creates one automatically, or doesn't need any.

   You'll need a project and a call flow if you want Verboice to answer calls;
   this may be out-of-scope for Surveda that will configure outgoing calls
   with their own call graphs and callbacks, which can be seen live in
   Verboice!


### Install [Nuntium](https://github.com/instedd/nuntium)

1. Checkout the repository and build the Docker images:

   ```console
   $ git clone git@github.com:instedd/nuntium.git
   $ cd nuntium/
   $ docker-compose run --rm web bundle
   $ docker-compose run --rm web rake db:create db:setup
   ```

2. Enable Guisso by editing (or creating) `config/guisso.yml`, copying the
   client id and secret from <http://web.guisso.lvh.me> for the Nuntium app:

   ```yaml
   enabled: true
   url: "http://web.guisso.lvh.me"
   client_id: ""
   client_secret: ""
   ```

3. Startup Nuntium:

   ```console
   $ docker-compose up web workerfast workerslow cron sched
   ```

4. Navigate to <http://web.nuntium.lvh.me> and authenticate using Guisso.

5. TODO: missing Nuntium configuration steps!

   I didn't delve into Nuntium yet, and don't know how to configure it for local
   development; with a sandbox or something.

   Help most welcomed!


### Install [Surveda](https://github.com/instedd/surveda)

1. Checkout the repository and build the Docker images:

  ```console
  $ git clone git@github.com:instedd/verboice.git
  $ cd verboice/
  $ ./dev-setup.sh
  ```

2. Configure Surveda by editing or creating `config/locals.exs`, using the
   client id and secret from <http://web.guisso.lvh.me> for the Surveda app:

   ```elixir
   use Mix.Config

   config :alto_guisso,
     enabled: true,
     base_url: "http://web.guisso.lvh.me",
     client_id: "",
     client_secret: ""

   config :ask, Ask.Endpoint,
     url: [host: "app.surveda.lvh.me"]
   ```

4. Configure Verboice by editing `config/locals.exs`, using the client id and
   client id and secret from <http://web.guisso.lvh.me> for the Verboice app:

   ```elixir
   config :ask, Verboice,
     base_url: "http://web.verboice.lvh.me",
     base_callback_url: "http://app.surveda.lvh.me",
     channel_ui: true,
     guisso: [
       base_url: "http://web.guisso.lvh.me",
       client_id: "",
       client_secret: "",
       app_id: "web.verboice.lvh.me"
     ]
   ```

5. Configure Nuntium by editing `config/locals.exs`, using the client id and
   client id and secret from <http://web.guisso.lvh.me> for the Nuntium app:

   ```elixir
   config :ask, Nuntium,
     base_url: "http://web.nuntium.lvh.me",
     base_callback_url: "http://app.surveda.lvh.me",
     channel_ui: true,
     guisso: [
       base_url: "http://web.guisso.lvh.me",
       client_id: "",
       client_secret: "",
       app_id: "web.nuntium.lvh.me"
     ]
   ```

6. Startup Surveda:

   ```console
   $ docker-compose up app webpack
   ```

7. Navigate to <http://app.surveda.lvh.me> and authenticate using Guisso.


## Register channels

You should now be able to enable both the Verboice and Nuntium services through
your account on Guisso.

### Register a Verboice channel

Please watch <https://www.youtube.com/watch?v=CkJsub2YnWo> for help on creating
and configuring a callcentric account and installing a soft phone client (such
as [Zopier5](https://www.callcentric.com/support/device/zoiper/v5) or
[Linphone](http://www.linphone.org/) for example).

Once you have created your callcentric account, and both extensions, you can use
the default extension (100) to make calls from Surveda through Verboice, and the
second extension (101) for receiving calls in your soft phone client.

1. Navigate to <http://app.surveda.lvh.me/channels>
2. Enable the Verboice service.
3. Click on the `>` icon to create a channel on Verboice.

**NOTE**: you must create the channel from Surveda! If you created the channel in
Verboice manually, you'll may have a duplicate issue (same callcentric number)
which can be fixed be deleting the channel in Verboice, then recreate it directly
in Surveda.

### Register a Nuntium channel

Please watch <https://youtu.be/pYsZLLOZ4Ks> which demonstrates the use of a QST
client in Nuntium... but I still have to understand how to interact (maybe using
the QST gateway on mobile?) with it from Surveda.

Help is most welcomed!
