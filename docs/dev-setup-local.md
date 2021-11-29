# HOW-TO: setup dev environment with local services

Surveda requires some external services to work properly:

- [Guisso](https://github.com/instedd/guisso) for single-sign-on across the services;
- [Verboice](https://github.com/instedd/verboice) for making phone calls (IVR);
- [Nuntium](https://github.com/instedd/nuntium) for sending and receiving text messages (SMS).

They can be used from a [cloud installation](dev-setup-cloud.md) or locally as we will see in this document.

## Setup

### Install [dockerdev](https://github.com/waj/dockerdev)

This isn't necessary, but installing [dockerdev](https://github.com/waj/dockerdev)
will greatly improve your experience, by using the [`*.lvh.me`](https://nickjanetakis.com/blog/ngrok-lvhme-nipio-a-trilogy-for-local-development-and-testing#lvh-me) domain to access
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

2. Navigate to <http://web.guisso.lvh.me> and create an account.

  **Note:** If the browser returns a DNS error when navigating to `http://web.guisso.lvh.me` (or any `lvh.me` domain) then we could [try this solution](#lvh-dns-error).


3. Now we need to create three applications:

  ```
  app=Nuntium  host=web.nuntium.lvh.me
  app=Verboice host=web.verboice.lvh.me
  app=Surveda  host=app.surveda.lvh.me
  ```

  Make sure to configure each application with the same two redirect URIs (**one per line**):

  ```
  http://app.surveda.lvh.me/session/oauth_callback
  http://app.surveda.lvh.me/oauth_client/callback
  ```

  **Important:** They must be set on each application, because Surveda will create access tokens for Verboice and Nuntium on their behalf.

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

4. Navigate to <http://web.verboice.lvh.me> and we should be authenticated automatically because we are using Guisso.

  **Note:** If the browser returns a `502 Bad Gateway` error [try this solution](#bad-gateway-error).

5. You may create a Project, but I don't know whether this is required. Maybe
   Surveda creates one automatically, or doesn't need any?

   You'll need a project and a call flow if you want Verboice to answer calls.
   This may be out-of-scope for Surveda that will configure outgoing calls
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
   $ docker-compose up web workerfast workerslow cron sched smpp
   ```

4. Navigate to <http://web.nuntium.lvh.me> and we should be authenticated automatically because we are using Guisso.

   No need to create anything for the time being. We'll create a channel
   directly from Surveda, and the application will also be created by Surveda
   the first time you create a Survey.

  **Note:** If the browser returns a `502 Bad Gateway` error [try this solution](#bad-gateway-error).

### Install [Surveda](https://github.com/instedd/surveda)

1. Checkout the repository and build the Docker images:

  ```console
  $ git clone git@github.com:instedd/surveda.git
  $ cd surveda/
  $ ./dev-setup.sh
  ```

2. Configure Surveda's `config/local.exs`. If not present then create the file and:
   1. Configure Guisso using the client id and secret from <http://web.guisso.lvh.me> for the Surveda app:

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

   2. Add Verboice using the client id and secret from <http://web.guisso.lvh.me> for the Verboice app:

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

   3. Add Nuntium using the client id and secret from <http://web.guisso.lvh.me> for the Nuntium app:

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

   4. The final `config/local.exs` should look like this:
    ```elixir
    use Mix.Config

      config :alto_guisso,
        enabled: true,
        base_url: "http://web.guisso.lvh.me",
        client_id: "",
        client_secret: ""

      config :ask, Ask.Endpoint,
        url: [host: "app.surveda.lvh.me"]

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

3. Startup Surveda:

   ```console
   $ docker-compose up app webpack
   ```

4. Navigate to <http://app.surveda.lvh.me> and we should be authenticated automatically because we are using Guisso.

  **Note:** If the browser returns a `502 Bad Gateway` error [try this solution](#bad-gateway-error).

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

Another solution is to use a QST server and the Android QST Gateway to actually
send the text messages through an Android phone.

Last but not least, we can setup a SMPP channel to send & receive SMS messages:

1. Navigate to <http://app.surveda.lvh.me/channels>

2. Enable the Nuntium service.

3. Click on the `>` icon to create a SMPP channel on Nuntium. If you have access
   to a SMPP server that will relay SMS messages from and to your mobile phone,
   you can configure it now.

   Or you can use a SMSC simulator (see below) that will be running on your
   machine. For example:

   - `host` should be an IP of your host machine (for example `192.168.1.2`);
   - `port` can be 2775;
   - `user` can be `surveda`;
   - `password` can be `secret`.

4. Navigate to <http://web.nuntium.lvh.me/channels>

5. You should see your channel. Click on `edit`:

   1. You can specify the `from` field with the phone number that is supposed to
      send and receive messages (to ask questions and receive responses). I use
      the callcentric number with ext 100.

   2. Add an AO rule to automatically set the `from` to sent messages, otherwise
      it may be left empty (no idea why it doesn't use the `from` phone number
      we configure above by default. The following rule works for me:

      - Condition: `To starts with sms://`
      - Action: `From = sms://17xxxxxxxxx100`

6. Create a Survey, using whatever questionnaire and respondents. Don't forget
   to start your SMSC simulator (see below) if your channel is configured to use
   it.

   :warning: Make sure to _create a Survey_ first, because Surveda currently
   doesn't configure the Nuntium application and channel. You must first run a
   simple Survey for Surveda to properly setup the application and the channel,
   especially callbacks from Nuntium into Surveda (statuses & replies)!

   Once you have run at least one survey you should be able to run panel survey
   waves at will.

7. Start the survey. You should see AO messages being queued on
   <http://web.nuntium.lvh.me/ao_messages> and then delivered to your phone (or
   simulator).

   If AO messages are kept in queue, make sure that the `smpp` container is
   running. You can also tail `nuntium/log/smpp_service_daemon.log` to see debug
   information.

   ```console
   $ cd nuntium
   $ docker-compose up smpp
   ```

8. You should now be able to reply from your mobile or simulator. You should see
   AO messages being queued on <http://web.nuntium.lvh.me/ao_messages>, then be
   delivered to Surveda, which will in turn send the next question as an AO
   message, and so on until the questionnaire is terminated (or aborted).

   If AT messages are kept in queue, check the Nuntium application was properly
   setup by Surveda. It should be:
   - HTTP get callback <http://app.surveda.lvh.me/callbacks/nuntium>
   - HTTP GET <http://app.surveda.lvh.me/callbacks/nuntium/status>

   You may also make sure that the `workerfast` container is running. You can
   tail `nuntium/log/generic_worker_daemon_fast_1000.log` to see debug
   information.

   ```console
   $ cd nuntium
   $ docker-compose up workerfast
   ```

   You may get issues with the `workerfast` container not being able to resolve
   `app.surveda.lvh.me` to the actual container (ECONNREFUSED errors), thus
   failing to deliver AT messages back to Surveda. This is because the container
   isn't added to the `shared` network created by dockerdev, which can be
   verified with:

   ```console
   $ docker inspect nuntium_workerfast_1
   ```

   In that case you must destroy and recreate the container until it's properly
   added to the `shared` network:

   ```console
   $ docker kill nuntium_workerfast_1
   $ docker container rm nuntium_workerfast_1
   $ docker-compose up workerfast
   ```

#### SMSC Simulator (SMPP)

The [OpenSMPP](https://github.com/OpenSmpp/opensmpp) project implements SMPP and
SMSC in Java and provides a nice simulator, with SMPP debugging, the ability to
receive messages and to send messages back, hence simulating a regular SMS
interaction.

Start by cloning or downloading a tarball of the
<https://github.com/OpenSmpp/opensmpp> project locally. Make sure to install a
JDK (e.g. OpenJDK 11) and maven.

Apply the following patch, to enable configuring the source (from mobile) and
dest (to surveda) phone numbers to send messages which are required so Nuntium
won't reject the message:

```diff
diff --git a/pom.xml b/pom.xml
index 9b76dbc..092c3af 100644
--- a/pom.xml
+++ b/pom.xml
@@ -202,8 +202,8 @@
 				<artifactId>maven-compiler-plugin</artifactId>
 				<version>3.0</version>
 				<configuration>
-					<source>1.5</source>
-					<target>1.5</target>
+					<source>1.6</source>
+					<target>1.6</target>
 					<encoding>UTF-8</encoding>
 				</configuration>
 			</plugin>
diff --git a/sim/src/main/java/org/smpp/smscsim/Simulator.java b/sim/src/main/java/org/smpp/smscsim/Simulator.java
index d066542..135040a 100644
--- a/sim/src/main/java/org/smpp/smscsim/Simulator.java
+++ b/sim/src/main/java/org/smpp/smscsim/Simulator.java
@@ -73,6 +73,8 @@ public class Simulator {
 	 * Name of file with user (client) authentication information.
 	 */
 	static String usersFileName = System.getProperty("usersFileName", "etc/users.txt");
+	static String sourceAddr = System.getProperty("sourceAddr", "111111111");
+	static String destAddr = System.getProperty("destAddr", "222222222");

 	/**
 	 * Directory for creating of debug and event files.
@@ -369,6 +371,8 @@ public class Simulator {
 							String message = keyboard.readLine();
 							DeliverSM request = new DeliverSM();
 							try {
+								request.setSourceAddr(this.sourceAddr);
+								request.setDestAddr(this.destAddr);
 								request.setShortMessage(message);
 								proc.serverRequest(request);
 								System.out.println("Message sent.");
```

Compile and package the OpenSMPP JARs. On my Ubuntu 18.04 based Linux, I had to
export `JAVA_HOME`, too. Check whether you need it, and if needed try to find
the actual value for your system.

```console
$ export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
$ mvn package
```

When all JARs have been built, create an `etc/users.txt` file, that will act as
a user/password database to allow connections (or not). For example:

```text
name=surveda
password=surveda
timeout=unlimited
```

You can finally start the simulator. I use the following script (`simulator.sh`):

```sh
#! /usr/bin/env sh
VERSION="3.0.3-SNAPSHOT"
CHARSET="charset/target/opensmpp-charset-${VERSION}.jar"
CORE="core/target/opensmpp-core-${VERSION}.jar"
SIM="sim/target/opensmpp-sim-${VERSION}.jar"

exec java -DsourceAddr=17xxxxxxxxx101 -DdestAddr=17xxxxxxxxx100 \
  -cp $CHARSET:$CORE:$SIM org.smpp.smscsim.Simulator
```

Simply type `1` to start the simulation. Once the SMPP channel is created, you
should see debug messages about nuntium connecting. When running a survey, you
should eventually see incoming messages. You can list them with `5`.

You should also be able to send messages with `4`. If there are multiple clients
connected, just kill and restart the simulator, then wait for the Nuntium SMPP
service to reconnect (a few seconds) so there is only one (we can easily end up
with multiple clients connected after editing a channel for example).


## Troubleshooting

### lvh DNS error
If you are facing a DNS error when navigating to any `lvh.me` domain maybe the problem is your ISP's DNS.
Try adding public DNS servers to your network configuration. For example:
- Google:
  - 8.8.8.8
  - 8.8.4.4
- Cloudflare:
  - 1.1.1.1
  - 1.0.0.1

More public [DNS servers](https://www.lifewire.com/free-and-public-dns-servers-2626062).

### Bad Gateway error
If the browser returns a `502 Bad Gateway` error when trying to navigate to `http://web.verboice.lvh.me`, `http://web.nuntium.lvh.me`, `http://app.surveda.lvh.me` (or any other app using a `*.lvh.me` domain) then the error could be related to the app's container not being added to the `shared` network created by `dockerdev`.

First, let's see if this is actually the error.
For example, if we can't browse `Verboice`, in a terminal run:
```console
$ docker inspect verboice_web_1 | jq '.[].NetworkSettings.Networks | keys'
```
If this command returns something like this:
```console
[
  "verboice_default"
]
```
without `shared` then we need to add the container to this network. For this, we must destroy and recreate the container until it's properly added to the `shared` network:

```console
$ docker kill verboice_web_1
$ docker container rm verboice_web_1
$ docker-compose up web
```

Running the `inspect` command should return:

```
[
  "shared",
  "verboice_default"
]
```
