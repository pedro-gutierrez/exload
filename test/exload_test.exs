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
    
    test "should not allow unknown scenarios" do
      assert {:error, :unknown_scenario} = Exload.run(:unknown, 1, 1)
    end

    test "should not allow scenarios with unknown modules" do
      assert {:error, :unknown_scenario_module} = Exload.run(:bad, 1, 1)
    end

    test "should start scenarios once" do
      assert :ok = Exload.run(:sample, 1, 1)
      assert {:error, _} = Exload.run(:sample, 1, 1)
    end
    
    test "should return scenario info" do
      assert :ok = Exload.run(:sample, 1, 1)
      :timer.sleep(10)
      assert {:ok, [
        scenario: :sample,
        vus: [
          total: 1,
          success: 0,
          running: 1,
          pending: 0,
          failed: 0
        ],
        iterations: 1,
        latency: [
          ms10: _,
          ms25: _,
          ms50: _, 
          ms100: _,
          ms250: _,
          ms500: _,
          ms1000: _,
          inf: _
        ]
      ]} = Exload.info(:sample)
    end

    test "should report virtual user failures" do
      assert :ok = Exload.run(:sample, 1, 1)
      :timer.sleep(10)
      assert {:ok, 1} = Exload.kill(:sample, 1)
      :timer.sleep(10)
      assert {:ok, [
        scenario: :sample,
        vus: [
          total: 1,
          success: 0,
          running: 0,
          pending: 0,
          failed: 1
        ],
        iterations: 1,
        latency: _
      ]} = Exload.info(:sample)
    end

  end

end
