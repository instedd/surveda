# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "ubuntu/trusty64"
  config.vm.hostname = "ask.local"

  config.vm.network :forwarded_port, guest: "80", host: "8084", host_ip: "127.0.0.1"
  config.vm.network :public_network, ip: '192.168.1.14'

  config.vm.provider :virtualbox do |vb|
    vb.customize ["modifyvm", :id, "--memory", "4096"]
  end

  config.vm.provision :shell do |s|
    s.privileged = false
    s.args = [ENV['REVISION'] || "0.7.0"]
    s.inline = <<-SH

    export DEBIAN_FRONTEND=noninteractive

    # Install required packages including elixir 1.3.2
    wget https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb && sudo dpkg -i erlang-solutions_1.0_all.deb
    sudo apt-get update
    sudo -E apt-get -y install git \
      libxml2-dev libxslt1-dev libzmq3-dbg libzmq3-dev libzmq3 mysql-client libmysqlclient-dev \
      libcurl4-openssl-dev apache2-threaded-dev libapr1-dev libaprutil1-dev libyaml-dev postfix curl \
      build-essential pkg-config libncurses5-dev uuid-dev libjansson-dev \
      inotify-tools mailutils \
      esl-erlang elixir=1.3.2-1

    # Install yarn
    curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
    sudo apt-get update && sudo apt-get install -y nodejs yarn

    # Create logs folder
    sudo mkdir -p /var/log/ask
    sudo chown `whoami` /var/log/ask

    # Setup application
    sudo mkdir -p /u/apps/ask
    sudo chown `whoami` /u/apps/ask
    git clone /vagrant /u/apps/ask
    cd /u/apps/ask
    if [ "$1" != '' ]; then
      git checkout $1;
      echo $1 > VERSION;
    fi

    # Config SMTP
    sudo sed -i 's/inet_interfaces = all/inet_interfaces = loopback-only/g' /etc/postfix/main.cf
    sudo /etc/init.d/postfix restart

    # Setup environment
    echo "
export HOME=$HOME
export PORT=80
export MIX_ENV=prod
export BROKER_BATCH_SIZE=1000
export DATABASE_HOST=mysql.local
export DATABASE_USER=root
export DATABASE_PASS=
export DATABASE_NAME=ask
export EMAIL_FROM_EMAIL=no-reply@example.com
export EMAIL_FROM_NAME=InSTEDD Ask
export GZIP_COMPRESSION_TYPE=\"text/html text/plain text/css application/javascript text/javascript\"
export HOST=ask.example.com
export NUNTIUM_APP_ID=nuntium.example.com
export NUNTIUM_BASE_URL=http://nuntium.example.com
export NUNTIUM_CLIENT_ID=
export NUNTIUM_CLIENT_SECRET=
export NUNTIUM_GUISSO_BASE_URL=https://login.example.com
export SECRET_KEY_BASE=092921f10cd8a53943fbef07228f37679cc5740cd04ab0b06314b47d1865a729c2448863abaa680cb4b76479f60348e0aff3db15585dfd2d0ad39757b2d28aad
export SMTP_USER=
export SMTP_PASS=
export SMTP_PORT=25
export SMTP_SERVER=localhost
export VERBOICE_APP_ID=verboice.example.com
export VERBOICE_BASE_URL=http://verboice.example.com
export VERBOICE_CLIENT_ID=
export VERBOICE_CLIENT_SECRET=
export VERBOICE_GUISSO_BASE_URL=https://login.example.com
    " > /u/apps/ask/.env
    chmod 0600 /u/apps/ask/.env

    # Static assets path
    mkdir -p /u/apps/ask/priv/static

    # Install and compile
    export MIX_ENV=prod
    mix local.hex --force
    mix deps.get --only prod
    mix local.rebar --force
    mix deps.compile
    mix compile
    yarn install
    ./node_modules/brunch/bin/brunch build -p
    mix phoenix.digest

    # Register ask server in upstart
    sudo sh -c 'echo "start on runlevel [2345]
stop on runlevel [!2345]
respawn

setuid `whoami`
chdir /u/apps/ask

script
  set -a
  . /u/apps/ask/.env
  mix phoenix.server >> /var/log/ask/app.log 2>&1
end script
" > /etc/init/ask.conf'

    sudo start ask
  SH
  end
end
