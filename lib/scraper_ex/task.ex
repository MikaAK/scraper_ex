defmodule ScraperEx.Task do
  require Logger

  alias ScraperEx.Task.{Config, ShortcutRemapper}

  @moduledoc false

  def run(task_configs) do
    task_configs
      |> ShortcutRemapper.remap
      |> Enum.reduce_while(%{}, fn
        {:allow_error, config}, acc ->
          case run_config(config) do
            :ok -> {:cont, acc}
            {:ok, {key, value}} -> {:cont, Map.put(acc, key, value)}
            {:error, e} -> {:cont, Map.update(acc, :errors, [e], &[e | &1])}
          end

        config, acc ->
          case run_config(config) do
            :ok -> {:cont, acc}
            {:ok, {key, value}} -> {:cont, Map.put(acc, key, value)}
            {:error, e} ->
              {:halt, {:error, put_in(e.details[:error], e)}}
          end
      end)
      |> then(fn
        {:error, _} = e -> e
        res -> {:ok, res}
      end)
  end

  defp run_config(%Config.Screenshot{path: path}) do
    if is_nil(path) do
      Hound.Helpers.Screenshot.take_screenshot()
    else
      Hound.Helpers.Screenshot.take_screenshot(path)
    end

    :ok
  end

  defp run_config(%Config.Navigate{url: url, load_time: load_time}) do
    Hound.Helpers.Navigation.navigate_to(url)

    if load_time do
      Process.sleep(load_time)
    end

    :ok
  end

  defp run_config(%Config.Scroll{selector: selector, x_offset: x, y_offset: y}) do
    Hound.Helpers.Element.move_to(selector, x, y)

    :ok
  end

  defp run_config(%Config.Input{selector: selector, input: input}) do
    try do
      Hound.Helpers.Element.fill_field(selector, input)

      :ok
    rescue
      error ->
        {:error, ErrorMessage.failed_dependency("hound failed to fill field", %{
          error: error,
          selector: selector,
          input: input
        })}
    end
  end

  defp run_config(%Config.Click{selector: selector, delay: delay}) do
    try do
      Hound.Helpers.Element.click(selector)

      if delay do
        Logger.debug("[ScraperEx.Task] Sleeping for #{delay}ms after click")
        Process.sleep(delay)
      end

      :ok

    rescue
      error ->
        {:error, ErrorMessage.failed_dependency(
          "hound failed to click field",
          %{error: error, selector: selector, delay: delay}
        )}
    end
  end

  defp run_config(%Config.Read{selector: {strategy, selector}, key: key, html?: html?}) do
    try do
      Logger.debug("[ScraperEx.Task] Reading from selector into #{key}, returning html?: #{html?}")

      case Hound.Helpers.Page.find_all_elements(strategy, selector) do
        [] -> {:ok, {key, nil}}
        [element] when html? -> {:ok, {key, element_html(element)}}
        elements when html? -> {:ok, {key, Enum.map(elements, &element_html/1)}}
        [element] -> {:ok, {key, element_inner_text(element)}}
        elements -> {:ok, {key, Enum.map(elements, &element_inner_text/1)}}
      end
    rescue
      error ->
        {:error, ErrorMessage.failed_dependency("hound failed to read field", %{
          error: error,
          key: key,
          selector: selector
        })}
    end
  end

  defp run_config(%Config.SendText{text: text}) do
    Hound.Helpers.Page.send_text(text)

    :ok
  end

  defp run_config(%Config.SendKeys{keys: keys}) do
    Hound.Helpers.Page.send_keys(keys)

    :ok
  end

  defp run_config(%Config.Sleep{period: period}) do
    Logger.debug("[ScraperEx.Task] Sleeping for #{period}ms")

    Process.sleep(period)
  end

  defp run_config(%Config.Javascript{key: nil, script: script}) do
    Logger.debug("[ScraperEx.Task] Execute JS script")

    Hound.Helpers.ScriptExecution.execute_script_async(script)

    :ok
  end

  defp run_config(%Config.Javascript{key: key, script: script}) do
    Logger.debug("[ScraperEx.Task] Execute JS script and returning #{key}")

    script = if String.starts_with?(script, "return "), do: script, else: "return #{script}"

    {:ok, {key, Hound.Helpers.ScriptExecution.execute_script(script)}}
  end

  defp element_inner_text(element) do
    element
      |> Hound.Helpers.Element.inner_text
      |> String.normalize(:nfkc)
  end

  defp element_html(element) do
    element
      |> Hound.Helpers.Element.outer_html
      |> String.normalize(:nfkc)
  end
end
