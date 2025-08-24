FROM elixir:1.10 AS dev

# Cleanup expired Let's Encrypt CA (Sept 30, 2021)
RUN sed -i '/^mozilla\/DST_Root_CA_X3/s/^/!/' /etc/ca-certificates.conf && update-ca-certificates -f

RUN sed -i s/deb.debian.org/archive.debian.org/g /etc/apt/sources.list

RUN apt-get -q update && \
    apt-get -q install -y default-mysql-client inotify-tools festival && \
    apt-get -q install -y --no-install-recommends ffmpeg libaacs0 && \
    apt-get -q clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mix local.hex --force
RUN mix local.rebar --force

ENV MIX_ENV=prod

ADD mix.exs mix.lock /app/
ADD config /app/config
WORKDIR /app

RUN mix deps.get
RUN mix deps.compile

ADD . /app
RUN mix compile
RUN mix phx.digest

FROM node:10 as js

COPY --from=dev /deps /deps
ADD . /app
WORKDIR /app

RUN yarn install --no-progress
RUN yarn deploy

FROM dev AS release

COPY --from=js /app/assets /app/

ENV MIX_ENV=prod
ENV PORT=80

WORKDIR /app
EXPOSE 80

CMD elixir --sname server -S mix phx.server
