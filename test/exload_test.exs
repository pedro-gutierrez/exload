defmodule ExloadTest do
  use ExUnit.Case

  setup_all do
    {_, 0} = Mix.Tasks.Goaws.run([])
    :ok
  end

  setup do
    :ok = Exload.kill_all()
  end

  describe "exload" do
    
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
          pending: 0,
          failed: 0
        ],
        iterations: 1,
      ]} = Exload.info(:test)
    end

    @tag :wip
    test "should report virtual user failures" do
      assert :ok = Exload.run(:test, 1, 1)
      assert {:ok, 1} = Exload.kill(:test, 1)
      :timer.sleep(50)
      assert {:ok, [
        scenario: :test,
        vus: [
          total: 1,
          success: 0,
          running: 0,
          pending: 0,
          failed: 1
        ],
        iterations: 1,
      ]} = Exload.info(:test)
    end
  end

end
