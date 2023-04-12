FROM elixir:1.10 AS dev

# Cleanup expired Let's Encrypt CA (Sept 30, 2021)
RUN sed -i '/^mozilla\/DST_Root_CA_X3/s/^/!/' /etc/ca-certificates.conf && update-ca-certificates -f

RUN apt -q update && \
    apt -q install -y default-mysql-client inotify-tools festival yarnpkg && \
    apt -q install -y --no-install-recommends ffmpeg libaacs0 && \
    apt -q clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mix local.hex --force
RUN mix local.rebar --force

FROM dev AS release

ENV MIX_ENV=prod

ADD mix.exs mix.lock /app/
ADD config /app/config
WORKDIR /app

RUN mix deps.get
RUN mix deps.compile

ADD . /app
RUN mix compile
RUN mix phx.digest

RUN yarnpkg install --no-progress
RUN yarnpkg deploy

ENV PORT=80
EXPOSE 80

CMD elixir --sname server -S mix phx.server
