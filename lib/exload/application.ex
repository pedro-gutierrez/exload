defmodule Exload.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    # Build a consumer per configured queue
    children = Exload.Sqs.consumers()
      |> Enum.map(fn [name: q, opts: opts] ->
        worker(Exload.Sqs.Consumer, [q|opts], name: q)
      end)

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Exload.Supervisor]
    Supervisor.start_link([
      ExloadWeb.Endpoint,
      Exload.Scenarios
    ] ++ children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    ExloadWeb.Endpoint.config_change(changed, removed)
    :ok
  end


  def print_sqs(queue, messages) do
    IO.puts "messages from " <> queue
    IO.inspect messages
  end
end
