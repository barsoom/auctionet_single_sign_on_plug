# If you change this also update dev.yml
FROM elixir:1.7.3-alpine

RUN mix local.hex --force && mix local.rebar --force
WORKDIR /app
ADD mix.exs mix.lock ./
ENV MIX_ENV=test
RUN mix deps.get
RUN mix deps.compile
ADD . .
RUN mix compile