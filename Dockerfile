# If you change this also update dev.yml
FROM hexpm/elixir:1.19.4-erlang-28.2-alpine-3.22.2

# Add git, to ensure "mix" supports fetching git packages.
RUN apk add --no-cache git
RUN mix local.hex --force && mix local.rebar --force
WORKDIR /app
ADD mix.exs mix.lock ./
ENV MIX_ENV=test
RUN mix deps.get
RUN mix deps.compile
ADD . .
RUN mix compile
