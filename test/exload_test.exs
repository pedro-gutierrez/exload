defmodule ExloadTest do
  use ExUnit.Case

  def start_sqs(_context) do
    {_, 0} = Mix.Tasks.Goaws.run([])
    :ok
  end

  describe "exload" do
    setup [:start_sqs]

    test "should start scenarios once" do
      assert :ok = Exload.run(:test, 1, 1)
      assert {:error, _} = Exload.run(:test, 1, 1)
    end

    test "should return scenario info" do
      assert :ok = Exload.run(:test, 1, 1)
      assert {:ok, [
        scenario: :test,
        vus: [
          total: 1,
          success: 0,
          running: 1,
          failed: 0
        ],
        iterations: 1,
      ]} = Exload.info(:test)
    end
  end

end
