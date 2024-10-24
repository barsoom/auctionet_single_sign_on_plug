defmodule AuctionetSingleSignOnPlug.Mixfile do
  use Mix.Project

  def project do
    [
      app: :auctionet_single_sign_on_plug,
      version: "0.1.0",
      elixir: "~> 1.3",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [mod: {AuctionetSingleSignOnPlug.Application, []}]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:plug, "> 1.0.0"},
      {:joken, "~> 2.6"},
      {:jason, "~> 1.3"}
    ]
  end
end
