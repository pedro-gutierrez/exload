defmodule Mix.Tasks.Goaws do
  @moduledoc """
  Custom mix task to manage GoAws
  """

  use Mix.Task

  @shortdoc "Restart GoAws"
  def run(_) do
    System.cmd("docker", [ "stop", "goaws"])
    System.cmd("docker", [ "rm", "goaws"])
    System.cmd("docker", [ "run", "-d", "--name", "goaws", "-p", "7890:4100", "pafortin/goaws"])
  end


end
