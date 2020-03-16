# If you change this also update dev.yml
FROM hexpm/elixir:1.10.1-erlang-22.2.7-alpine-3.11.3

RUN mix local.hex --force && mix local.rebar --force
WORKDIR /app
ADD mix.exs mix.lock ./
ENV MIX_ENV=test
RUN mix deps.get
RUN mix deps.compile
ADD . .
RUN mix compile
