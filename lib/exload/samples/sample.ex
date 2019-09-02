defmodule Exload.Samples.Sample do
  @moduledoc """
  A sample load test scenario
  """

  def init() do
    millis = :rand.uniform(30)
    {:ok, millis}
  end

  def run(millis) do
    :timer.sleep(millis)
    :done
  end

end
