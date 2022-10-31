# If you change this also update dev.yml
FROM hexpm/elixir:1.14.1-erlang-25.1.2-alpine-3.16.2

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
