FROM elixir:1.8

# Cleanup expired Let's Encrypt CA (Sept 30, 2021)
RUN sed -i '/^mozilla\/DST_Root_CA_X3/s/^/!/' /etc/ca-certificates.conf && update-ca-certificates -f

RUN \
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y default-mysql-client inotify-tools sox libsox-fmt-mp3 festival && \
  apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mix local.hex --force
RUN mix local.rebar --force
ENV MIX_ENV=prod

ADD mix.exs mix.lock /app/
ADD config /app/config
WORKDIR /app

RUN mix deps.get --only prod
RUN mix deps.compile

ADD . /app
RUN mix compile
RUN mix phx.digest

ENV PORT=80
EXPOSE 80

CMD elixir --sname server -S mix phx.server
