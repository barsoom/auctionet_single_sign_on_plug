# If you change this also update dev.yml
FROM hexpm/elixir:1.13.4-erlang-24.3.4-alpine-3.15.3

RUN mix local.hex --force && mix local.rebar --force
WORKDIR /app
ADD mix.exs mix.lock ./
ENV MIX_ENV=test
RUN mix deps.get
RUN mix deps.compile
ADD . .
RUN mix compile
