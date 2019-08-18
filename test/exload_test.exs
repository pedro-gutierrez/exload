defmodule ExloadTest do
  use ExUnit.Case

  def start_sqs(_context) do
    {_, 0} = Mix.Tasks.Goaws.run([])
    :ok
  end

  describe "exload" do
    setup [:start_sqs]

    test "should start scenarios once" do
      assert :ok = Exload.Scenarios.run(:test, 1, 1)
      assert {:error, _} = Exload.Scenarios.run(:test, 1, 1)
    end
  end

end
