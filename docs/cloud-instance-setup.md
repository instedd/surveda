# Surveda Instance How-To

This guide is an always-draft script approximately stating how we use to set up new Surveda instances in the InSTEDD Cloud, together with their Guisso, Verboice, Nuntium and other collaborating tools. It is not an official installation guide, but a bunch of notes that helps us set up Surveda instances - and may help you set one up, too.

There probably are implicit requirements and assumptions throughout the doc, and maybe some inaccuracies. Whenever you find any issues with the process, please submit a PR rewritting that step, or at least raise an issue.

> **Note**: all configuration files mentioned here are located inside the `cloud-instance-configs` directory.

## Checklist

- [ ] Define the instance's name/code
- [ ] Check for fastest AWS region from within country
- [ ] Register domain
- [ ] Setup the domain in AWS SES
- [ ] Fire up an EC2 instance in the chosen AWS Region
- [ ] Enable VPC Hostnames resolution
- [ ] Add an Elastic IP to the server
- [ ] Connect to the server & copy your SSH keys
- [ ] Install Docker on the instance
- [ ] Configure Docker logs limits
- [ ] Create a new environment in Rancher
- [ ] Add the instance as a Host in the new Environment
- [ ] Add a Janitor stack
- [ ] Create NFS file system
- [ ] Attach NFS to Rancher
- [ ] Set up DB backups to S3
- [ ] Create DB stack
- [ ] Create DB users & databases
- [ ] Create SES Credentials
- [ ] Add Guisso
- [ ] Create reCaptcha credentials
- [ ] Add Route53 DNS Stack
- [ ] Create a Let's Encrypt stack
- [ ] Create proxy stack & set up HTTPS
- [ ] Add Prometheus Agents
- [ ] Configure GUISSO
- [ ] Add Nuntium
- [ ] Add Verboice
- [ ] Create project in Sentry
- [ ] Add Surveda
- [ ] Configure Prometheus
- [ ] Add Ona Connector (Optional)
- [ ] Add Adminer (Optional)

## Description

1. **Define the instance's name/code**
  We name installations as `surveda-xx`, where xx is the country's [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2#Officially_assigned_code_elements) country code. An installation in Argentina would be `surveda-ar`, while one in Turkmenistan would be `surveda-tm`. We'll refer to `surveda-xx` in every step of this guide - but you should use the one you're setting up.

1. **Check for fastest AWS region from within country**
  Nothing too precise, but having someone hit http://www.cloudping.info/ helps to get _some_ pointer

1. **Register domain**
  Go to InSTEDD's AWS account, and register `surveda-xx.org` in Route53.

1. **Setup the domain in AWS SES**
  Look for Simple Email Service in AWS, go to Domains, Verify a New Domain. Input `surveda-xx.org`, and check "Generate DKIM settings". Confirm the dialog. You'll get a list of records you should add, and the main button will be "Use Route53" - click it so Amazon sets everything up for us. Check the Domain Verification Record, DKIM Record Set & Hosted Zones. We can leave Email Receiving Record out, since we're not receiving e-mails. Confirm with Create Record Sets.
  Go back to the domains list, and click the new one. Expand the Notifications section, click Edit Configuration. Select the `ses-notifications` for both the Bounces, Complaints and Deliveries SNS Topics, Disable Email Feedback Forwarding, and click Save Config.
  Verification can take from minutes to hours, so come back from time to time to check.

1. **Fire up an EC2 instance in the chosen AWS Region**
  Pick the newest [Ubuntu Minimal image](https://ap-northeast-1.console.aws.amazon.com/ec2/v2/home?region=ap-northeast-1#Images:visibility=public-images;name=ubuntu-minimal/images/hvm-ssd/ubuntu-;ownerAlias=099720109477;sort=desc:name) that's LTS (be sure to change to your chosen region!). `t3.large` if will include Verboice (else, `t3.medium` will do).
  Create a new VPC called `surveda-xx-vpc` with a IPv4 CIDR block `172.yy.0.0/16`, and a new subnet called `surveda-xx-subnet` with IPv4 CIDR block `172.yy.0.0/20`.
  Protect against accidental termination.
  Change to a 30GB gp2 storage, don't delete on termination.
  Add a Name tag whose value is `surveda-xx`.
  Create a security group `surveda-xx-host` that allows SSH (TCP port 22), HTTP (TCP port 80), HTTPS (TCP port 443), UDP (port 500), UDP (port 4500), UDP port 5060 (label it `SIP`), UDP ports 10000-20000 (label it `RDP`), All ICMP IPv4 (ICMP ports 0-65535), All ICMP IPv6 (IPV6 ICMP, All ports) - all of them from Any Source (`0.0.0.0/0, ::/0`). Then add an extra rule allowing TCP (port 9999) from our Prometheus instance IP (currently, `34.224.89.68/32`), and another one allowing our office's public IP.
  Use any key pair that you have available, or create a new one. You'll add your private key in a moment, but for that you'll need this keypair.

1. **Enable VPC Hostnames resolution**.
  Go to VPC, select the `surveda-xx-vpc`, click `Actions`, then `Edit DNS hostnames`. Check the `Enable` checkbox, then `Save changes`.

1. **Add an Elastic IP to the server**
  Go to VPC, select Internet Gateways, crate an Internet Gateway called `surveda-xx-gw`. Right-click it, Attach to VPC, select your `surveda-xx-vpc` and Attach.
  Select Route Tables, select the one attached to your VPC, Edit its Routes to add the Destination `0.0.0.0/0` through your Internet Gateway.
  In EC2, go to Elastic IPs, and Allocate new address. Then right-click it, and Associate address to your instance.

1. **Connect to the server & copy your SSH keys**
  Go to Instances list, select your new instance, copy its IP address. `chmod 600 ~/Downloads/your-keypair.pem` and then `ssh ubuntu@${INSTANCE_IP} -i ~/Downloads/your-keypair.pem` to connect.
  Copy your computer's `~/.ssh/id_ed25519.pub`'s content (if you only have a `~/.ssh/id_rsa.pub`, you should DEFINITELY create an ED25519 one) into the server's `~/.ssh/authorized_keys`. Logout, `ssh` once again without using the `.pem` key, and remove the initial public key that was in the server's `~/.ssh/authorized_keys`.
  Add whatever public keys you know from your relevant teammates.

1. **Install Docker on the instance**
    In Ubuntu 18.04, you should run `curl https://releases.rancher.com/install-docker/18.06.sh | sh`. Then, you have to change the host's DNS resolver [as per Rancher's documentation](https://rancher.com/docs/rancher/v1.6/en/hosts/#hosts-running-a-local-caching-nameserver). Run `sudo systemctl mask systemd-resolved && sudo rm /etc/resolv.conf && sudo touch /etc/resolv.conf`. Fill it with this three lines: `domain ${region-code}.compute.internal`, `search ${region-code}.compute.internal` and `nameserver 172.yy.0.2` (with `yy` being your network's one).
  `curl https://releases.rancher.com/install-docker/17.12.sh | sh` should do in Ubuntu 16.04.

1. **Configure Docker logs limits**
  Create an `/etc/docker/daemon.json` file with the contents of `etc-docker-daemon.json` to limit Docker's disk space usage. Restart the daemon by running `sudo service docker restart`.

1. **Create a new environment in Rancher**
  Log into Rancher, select Manage Environments in the upper left menu, then Add Environment. Create a `surveda-xx` Cattle environment (with `Surveda ${Country Name} - ${AWS region name}` description), add relevant teammates as members/owners.

1. **Add the instance as a Host in the new Environment**
  In your Rancher Environment, go to Infrastructure -> Hosts, Add Host. Copy the `sudo docker ...` command from step 5 & run it on the instance. Go to Hosts and you should see it in a few moments.

1. **Add a Janitor stack**
  Go to Rancher, add a new stack from Catalog. Search for Janitor, pick the latest template version. Leave every parameter as is, launch.

1. **Create NFS file system**
  Go to EC2, create a new Security Group `surveda-xx-nfs` on the `surveda-xx-vpc` with a single incoming rule allowing NFS (TCP 2049) from the `surveda-xx-host` security group Source.
  Go to EFS, create a new File System in the `surveda-xx-vpc` in every availability zone, but replace the default security group with the `surveda-xx-nfs` one. Name it `surveda-xx-efs`. General Purpose, Bursted, No encryption is OK.
  **Note:** If your AWS region doesn't support EFS, *don't try creating an EFS in another region*. It won't work. Trust me.

1. **Attach NFS to Rancher**
  Go to Rancher, add a new stack from Catalog. Search for Rancher NFS, pick the latest template version. Fill EFS's `DNS Name` as `NFS Server`, `/` as base directory, set `noresvport` as Mount Options, pick `retain` On Remove, launch.
  Go to Infrastructure, and Add Volume to the `rancher-nfs` driver. Call it `verboice-data`. Add another one called `nuntium-rabbitmq-data`, then `verboice-asterisk-config` & `verboice-sounds`.

1. **Create DB data volume in EBS**
  Go to IAM, create a new user called `surveda-xx-ebs` with Programmatic access, don't add any policy, role nor permission. Select the user in IAM, then `Add inline policy`. Copy the `iam.ebs-volume-user-policy.json` contents, replacing the placeholder in the JSON for the region's code (`${region-code}`). Create an access key for the user and take note of it.
  Go to Rancher, `Add from Catalog`, look for `Rancher EBS` and add it with the access key and secret you just got from IAM.
  In Rancher, go to Infrastructure -> Storage, look for the EBS driver, `Add Volume` named `mysql-data` with Driver Options `size`=`50` and `volumeType`=`gp3`.

1. **Set up DB backups to S3**
  We'll backup the DB on S3. Create a `surveda-xx` directory inside `instedd-backups` S3 bucket.
  Go to IAM, create a new user called `surveda-xx-backup` with Programmatic access, don't add any policy, role nor permission, and take note of its Access Key ID & Secret access key for next step. Close the wizad, select the user, then `Add inline policy`. Copy the `iam.s3-backup-user-policy.json` contents, replacing the placeholder in the JSON for `surveda-xx` (the bucket you just created). Name the policy `surveda-xx-backups`.

1. **Create DB stack**
  Create a new stack in Rancher named `db`, using the `db.docker-compose.yml` and `db.rancher-compose.yml` files as a base. Generate a really secure password for the DB, copy it to both the `mysql` & `mysql-backup` services' config, and then fill in the S3 user's access key secret (you can copy it from another running instance).

1. **Create DB users & databases**
  Get into the `mysql` service of your `db` stack, click the contextual menu of your container, and open `Execute Shell`. Log into your DB (`mysql -p`, and input your root password when prompted). For each user you'll need, run `CREATE USER 'service-name'@'%' IDENTIFIED BY 'new-secure-password';`, then `CREATE DATABASE service-name CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;`, `GRANT ALL PRIVILEGES ON service-name.* to 'service-name'@'%';`, with `service-name` being `guisso`, `nuntium`, & `verboice`. Take note of each of the passwords you generate - you'll need them later.
  Use the same procedure to create `surveda`'s user & database, but create the database with `CREATE DATABASE surveda CHARACTER SET utf8 COLLATE utf8_unicode_ci;` instead (different charset & collation).
  **TODO**: we should [not use `utf8` & `utf8_unicode_ci`](https://mathiasbynens.be/notes/mysql-utf8mb4), but [we're hitting some index limit otherwise](https://stackoverflow.com/a/38749112/641451). This is a bug in Surveda.

1. **Create SES Credentials**
  Go to SES, SMTP Settings, Create My SMTP Credentials, name it `surveda-xx-ses-smtp`. Save the credentials - you'll use them latter. Go to IAM (you may end up there after the wizard), Users, search for the one you've created. Expand its Inline Policy, Edit it in JSON to match `iam.ses-smtp-user-policy.json` (remember to replace the domain's country code!).

1. **Create reCaptcha credentials**
  Go to [reCaptcha Admin Console](https://www.google.com/recaptcha/admin/), create a new site. Label it `Guisso Surveda xx - login.surveda-xx.org`, choose `reCAPTCHA v2` `"I'm not a robot" Checkbox` challenge type. Add `login.surveda-xx.org` as domain, add relevant coworkers' emails as Owners, `Accept the reCAPTCHA Terms of Service`, keep the `Send alerts to owners` enabled and `SUBMIT` the form. Take note of the Site key and Secret key for next step.

1. **Add Guisso**
  Add a new stack From Catalog. Look for Guisso, and add it. Choose the newest Guisso tag [from Docker Hub](https://hub.docker.com/r/instedd/guisso/tags/) - just fill in the tag name (ie, `1.3-pre6`). Fill in your DB's credentials (Host should be `mysql.db` - aka `service.stack`), SES credentials (check if the Host's zone is OK), Devise email address (`no-reply@surveda-xx.org`). Secret Token & Devise secret key have to be random strings (not sure if mandatory, but it seems customary to use a SHA256 hash which you can generate with `shasum -a 256` on the command line hashing a randomly generated string). Leave Google client ID & secret empty (unless you need Google SSO - please document those steps here), let the coookie name as-is (`guisso`), and change the cookie domain to `surveda-xx.org`. Then, `Launch`!

1. **Add Route53 DNS Stack**
  Go to Amazon IAM, create a new `surveda-xx-route53-rancher` user with programmatic access, copy `rancher-route53` permissions. Copy the credentials, close the wizard, look for your new user, detach it's managed policy, add an inline one like `iam.route53-rancher-user-policy.json` replacing it's hosted zone ID with the one you see in the URL when accessing your `surveda-xx.org` zone in Route53. Create the policy calling it `surveda-xx-route53-rancher-user-policy`.
  Go to Rancher Stacks, Add from Catalog `Route53 DNS`. Input the credentials from the new user. Fill in `surveda-xx.org` as your hosted zone name, leave the zone ID blank (unless needed), change the name template to `%{{service_name}}.%{{stack_name}}`. Then Launch.

1. **Create a Let's Encrypt stack**
  Add a `Let's Encrypt` Stack from Catalog. Call it `letsencrypt`, agree to the ToS, set your e-mail, and call your cert `surveda-xx`. Initialize Domain Names as `surveda-xx.org, login.surveda-xx.org, nuntium.surveda-xx.org, verboice.surveda-xx.org`. Change the Domain Validation Method to HTTP, change the Renewal Grace Period to 26, and leave the rest of the fields unchanged. Uncheck `Start services after creating`, then `Launch`.

1. **Create proxy stack & set up HTTPS**
  Create a Stack called `proxy` using `proxy.docker-compose.yml` & `proxy.rancher-compose.yml` (replace both occurences of `surveda-xx` in the `rancher-compose` file).
  Go to Route53, pick your `surveda-xx.org.` Hosted Zone. Create a Record Set with an empty name (so it's `surveda-xx.org`), make it an alias of your `lb.proxy.surveda-xx.org`. Do the same for the names `login`, `nuntium` & `verboice`.
  After that, go back to Rancher and Activate the `letsencrypt` stack. Wait for it to create the cert (you can check the container's console).
  Upgrade the `lb` service in the `proxy` stack. Add a new Service Rule with HTTPS protocol, for `login.surveda-xx.org` on port 443 that target's the `guisso` on port 80. Choose `surveda-xx` certificate, and confirm the changes.

1. **Add Prometheus Agents**
  Add a Stack from Catalog. Search for "Prometheus Agents", use `surveda-xx` as Environment name, and launch it.
  Upgrade your proxy configuration to add a new `Selector Rule` at the end, with HTTP protocol, empty Request Host, port 9000, empty path, Target `proxy=stats` and Port 9000. Go to the `Custom haproxy.cfg` tab and update the config to match the `haproxy.cfg` file here.

1. **Configure GUISSO**
  Visit https://login.surveda-xx.org/ and you should see GUISSO working 🎉
  Create a new account using your e-mail, confirm it via e-mail, log into your account.
  Execute a Shell in the `guisso` container in Rancher, execute `bundle exec rails c`. Make yourself an admin by doing `user = User.first; user.role = :admin; user.save!`.
  Create a `Nuntium` application that is trusted, with `nuntium.surveda-xx.org` hostname and empty Redirect URLs. Copy the identifier and secret.
  Create a `Verboice` trusted application with hostname `verboice.surveda-xx.org` and empty Redirect URLs. Copy the identifier & secret.
  Create a `Surveda` trusted application with hostname `surveda-xx.org`, and two Redirect URIs: `https://surveda-xx.org/oauth_client/callback` & `https://surveda-xx.org/session/oauth_callback`. Copy the identifier & secret.

1. **Add Nuntium**
  Add a Nuntium Stack from Catalog. [Newest version available](https://hub.docker.com/r/instedd/nuntium/tags/), `https` scheme, `nuntium.surveda-xx.org` hostname, `mysql.db` database host, `nuntium` user & db name, fill in the password you have created earlier, set Use GUISSO to True, `https://login.surveda-xx.org` GUISSO URL, and the identifier & secret you previously copied when registering the app in GUISSO.
  Upgrade the `Memory limit (web process)` to `1024m`, the `Memory limit (worker process)` to `512m`, the `Memory limit (memcached process)` to `256m`, and the `Memory limit (rabbitmq process)` to `1024m`. Upgrade the `Memory reservation (rabbitmq process)` to `256m`.
  Launch it.
  Upgrade the `proxy`'s `lb`, add a new HTTPS Service Rule for host `nuntium.surveda-xx.org` on port 443 that target's `nuntium`'s `web` container on port 80.
  If you plan to run SMS-heavy surveys on this instance, visit the `workerfast` service and increase its scale to 3 or 4 (we've tested it with up to 6 already).
  Visit `https://nuntium.surveda-xx.org`, accept GUISSO's authorization, create an account, configure Telemetry.

1. **Add Verboice**
  Add a new Stack called `verboice` using `verboice.docker-compose.yml` & `verboice.rancher-compose.yml`. On the `docker-compose`, replace the 3 occurences of `YOUR_VERBOICE_DB_PASSWORD` with your DB's `verboice` user password, the 2 occurences of `YOUR_VERBOICE_CLIENT_ID_IN_GUISSO` & `YOUR_VERBOICE_CLIENT_SECRET_IN_GUISSO`, and the 5 occurences of `surveda-xx`. You should **not** change the `CRYPT_SECRET` value for now.
  You can also pick a [different docker image tag](https://hub.docker.com/r/instedd/verboice/tags/) - but be sure to replace it everywhere in the `docker-compose`. On Advanced Options, be sure to uncheck `Start services after creating`, then `Create` them.
  Start the `web` container, `Execute Shell` in it, and run `bundle exec rake db:setup`. Deactivate the service, then activate the whole Stack.
  Upgrade the `proxy`'s `lb`, add a new HTTPS Service Rule for host `verboice.surveda-xx.org` on port 443 with path `/twilio` that target's `verboice`'s `broker` container on port 8080. Add another one like that, but with path `/africas_talking`.
  Add a third rule with an empty path targeting `verboice`'s `web` container on port 80.
  Make sure **the rule without `path` comes after the ones with it** and confirm the changes.
  Visit `https://verboice.surveda-xx.org`, accept GUISSO's authorization, go to Configure Telemetry with your e-mail.
  **NOTE**: When you submit, you may see a Rails error. Ignore it, go back, hit Dismiss to Telemetry. This may be some missing ENV variable or something else. We should investigate further.
  **TODO**: we should create a Catalog template for Verboice, and make the `CRYPT_SECRET` configurable on the broker.

1. **Create project in Sentry**
  Go to sentry.io and create a new Elixir `surveda-xx` project. Copy the Sentry DSN for later.

1. **Add Surveda**
  Add a new Stack from Catalog - Surveda. Choose [the newest image version](https://hub.docker.com/r/instedd/ask/tags/), `surveda-xx.org` hostname, `mysql.db` database host, `surveda` user & db name, fill in the password, `no-reply@surveda-xx.org` email address, `email-smtp.us-east-1.amazonaws.com` SMTP Server Host, same username & password than GUISSO, generate a new secret key base and hash it, fill both Sentry DSN & Sentry Public DSN with the DSN you got earlier (same value in both fields), Enable GUISSO, fill `https://login.surveda-xx.org` as base URL, fill client id & secret, put `https://nuntium.surveda-xx.org` as Nuntium base URL, copy the GUISSO base url as Guisso base URL to access Nuntium, `nuntium.surveda-xx.org` as "Surveda APP ID in Guisso to access Nuntium" (yeap, totally confusing), Surveda's guisso client ID & secret in Surveda Client ID/Secret in Guisso to Access Nuntium (the ID & Secret you got when you created the Surveda app), leave Friendly name empty. Put `https://verboice.surveda-xx.org` as Verboice base URL, `https://login.surveda-xx.org` again as Guiso base url to access Verboice, `verboice.surveda-xx.org` as Surveda App ID to Verboice, the same Client ID & Secret for Guisso to access Verboice (you've used them 3 times in this template already), and leave the Friendly name empty. Launch it.
  Upgrade the `proxy`'s `lb`, add a new HTTPS Service Rule for host `surveda-xx.org` on port 443 that target's `surveda`'s `app` container on port 80.
  Visit `https://surveda-xx.org`, approve GUISSO's authorization, go to Channels, click the `+` sign and enable both Verboice & Nuntium, accepting the Guisso's requests.

1. **Configure Prometheus**
  In Rancher, switch to the Zabbix environment. Navigate to the `blackbox` service in the `prometheus` stack, and `Execute shell` on its container. `cd /etc/prometheus`, and `vi prometheus.yml`, and add `- proxy.prom.surveda-xx.org` or `- lb.proxy.surveda-xx.org` lines where it seems suitable, then save. Run the `restart` container once, and you should see the new jobs [in Prometheus](https://prometheus.instedd.org/targets#job-surveda).

1. (Optional) **Add Ona Connector**
  Go to Rancher, Infrastructure -> Storage and create a new Volume called `surveda-ona-connector-data` on the Rancher NFS driver. Go to Guisso, create a new app `Surveda Ona Connector` with hostname `ona.surveda-xx.org` and redirect URI `https://ona.surveda-xx.org/session/oauth_callback` that's trusted. Copy the ID & secret. Then create a new Stack called `surveda-ona-connector` using `ona.docker-compose.yml` & `ona.rancher-compose.yml`. Create a new, secure password for the DB and fill it in both the DB & app configuration, create a new secret by hashing a random string, fill in the GUISSO details you just got, and replace every `surveda-xx` occurrence, then start it.
  Go to Route53, into the `surveda-xx.org` hosted zone. Create a new Record set for `ona.surveda-xx.org` to be an A Alias of `lb.proxy.surveda-xx.org`. Update your Rancher's `lb` service of the `proxy` to create a new HTTPS Service Rule for `ona.surveda-xx.org` on port 443 to go to the connector's `app` on port 80. Upgrade your `letsencrypt` service and add `ona.surveda-xx.org` to the list of `DOMAINS`. Wait 120 secs for it to update the certs, then try `https://ona.surveda-xx.org`, approve the GUISSO permission, and you're done!

1. (Optional) **Add Adminer**
  Go to Route53, create a new A record `adminer.surveda-xx.org` which is an A alias of `lb.proxy.surveda-xx.org`.
  In Rancher, upgrade your `letsencrypt` service to add `adminer.surveda-xx.org` on the list of `DOMAINS`.
  Go to Github, Settings -> Developer Settings -> OAuth Apps -> Create new app. Call it "Adminer Surveda XX", homepage `https://adminer.surveda-xx.org`, callback URL `https://adminer.surveda-xx.org/oauth2/callback`. Copy client ID & secret.
  In Rancher, add the `Adminer` Stack from Catalog. Put `instedd` as the Github org, `manas` as the team, generate the cookie secret, and paste the client id & secret from the Github app; then launch.
  In Rancher, update the Proxy to point HTTPs `adminer.surveda-xx.org`'s port 443 to the `adminer/oauth2-proxy`'s port 80.
