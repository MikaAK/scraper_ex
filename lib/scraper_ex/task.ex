defmodule ScraperEx.Task do
  @moduledoc false

  defmodule Config.Navigate do
    @enforce_keys [:url]
    defstruct [{:load_time, 100} | @enforce_keys]
  end

  defmodule Config.Input do
    @enforce_keys [:selector, :input]
    defstruct @enforce_keys
  end

  defmodule Config.Click do
    @enforce_keys [:selector]
    defstruct @enforce_keys
  end

  defmodule Config.Read do
    @enforce_keys [:selector, :key]
    defstruct [:value | @enforce_keys]
  end

  def run(task_configs) do
    task_configs
      |> Enum.map(&maybe_prepare_config/1)
      |> Enum.reduce(%{}, fn config, acc ->
        case run_config(config) do
          :ok -> acc
          {:ok, {key, value}} -> Map.put(acc, key, value)
          {:error, e} -> Map.update(acc, :errors, [e], &[e | &1])
        end
      end)
  end

  defp maybe_prepare_config({:navigate_to, url}) do
    %Config.Navigate{url: url}
  end

  defp maybe_prepare_config({:navigate_to, url, load_time}) do
    %Config.Navigate{url: url, load_time: load_time}
  end

  defp maybe_prepare_config({:input, selector, input}) do
    %Config.Input{selector: selector, input: input}
  end

  defp maybe_prepare_config({:click, selector}) do
    %Config.Click{selector: selector}
  end

  defp maybe_prepare_config({:read, key, selector}) do
    %Config.Read{key: key, selector: selector}
  end

  defp maybe_prepare_config(config) when is_struct(config) do
    config
  end

  defp run_config(%Config.Navigate{url: url, load_time: load_time}) do
    Hound.Helpers.Navigation.navigate_to(url)

    if load_time do
      Process.sleep(load_time)
    end

    :ok
  end

  defp run_config(%Config.Input{selector: selector, input: input}) do
    Hound.Helpers.Element.fill_field(selector, input)
  end

  defp run_config(%Config.Click{selector: selector}) do
    Hound.Helpers.Element.click(selector)
  end

  defp run_config(%Config.Read{selector: selector, key: key}) do
    {:ok, {key, Hound.Helpers.Element.inner_text(selector)}}
  end
end
