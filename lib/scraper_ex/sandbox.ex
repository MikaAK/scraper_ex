defmodule ScraperEx.Sandbox do
  @moduledoc """
  Sandboxing allows you to set the return value of a specific flow

  ```elixir
  ScraperEx.Sandbox.set_run_task_result(my_flow(), %{my_result: :ok})
  ```
  """
  @registry :scraper_ex_sandbox
  @keys :unique
  @sleep_for_sync 50

  @spec start_link :: {:error, any} | {:ok, pid}
  def start_link do
    Registry.start_link(keys: @keys, name: @registry)
  end

  @spec set_run_task_result(flow_config :: list(ScraperEx.task_config), {:ok, any} | {:error, any}) :: :ok
  @doc """
  Sets the result for a flow
  """
  def set_run_task_result(flow_config, result) do
    config_hash = :erlang.phash2(flow_config)
    res = case SandboxRegistry.register(@registry, "#{config_hash}", %{result: result}, @keys) do
      :ok -> :ok
      {:error, :registry_not_started} -> raise_not_started!()
    end

    Process.sleep(@sleep_for_sync)

    res
  end

  @spec run_task_result(flow_config :: list(ScraperEx.task_config)) :: any
  @doc """
  Gets the results for a flow
  """
  def run_task_result(flow_config) do
    config_hash = :erlang.phash2(flow_config)

    case SandboxRegistry.lookup(@registry, "#{config_hash}") do
      {:ok, %{result: result}} -> result

      {:error, :pid_not_registered} ->
        raise """
        No functions registered for #{inspect(self())}
        Config: #{inspect(flow_config, pretty: true)}

        ======= Use: =======
        #{format_example()}
        === in your test ===
        """

      {:error, :registry_not_started} ->
        raise """
        Registry not started for ScraperEx.Sandbox.
        Please add the line:

        ScraperEx.Sandbox.start_link()

        to test_helper.exs for the current app.
        """
    end
  end

  defp format_example do
    """
    setup do
      ScraperEx.Sandbox.set_run_task_result([
        {:navigate_to, "...url"},
        {:read, :my_res, {:css, ".value"}}
      ], %{my_res: 1})
    end
    """
  end

  defp raise_not_started! do
    raise """
    Registry not started for ScraperEx.Sandbox.
    Please add the line:

    ScraperEx.Sandbox.start_link()

    to test_helper.exs for the current app.
    """
  end
end
