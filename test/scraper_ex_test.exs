defmodule ScraperExTest do
  use ExUnit.Case

  @moduletag capture_log: true

  if !System.get_env("CI") do
    doctest ScraperEx
  end

  describe "sandbox mode" do
    test "returns specified values when mocked" do
      flow = [
        {:click, {:css, ".thing"}},
        {:value, :my_log, {:css, ".value"}}
      ]

      result = {:ok, %{my_log: "value"}}

      assert :ok === ScraperEx.Sandbox.set_run_task_result(flow, result)

      assert result === ScraperEx.run_task_in_window(flow, sandbox?: true)
    end
  end
end
