defmodule ScraperEx.Task.ShortcutRemapper do
  @moduledoc false

  alias ScraperEx.Task.Config

  def remap(shortcuts) do
    Enum.map(shortcuts, &maybe_short_to_config/1)
  end

  defp maybe_short_to_config({:allow_error, config}) do
    {:allow_error, maybe_short_to_config(config)}
  end

  defp maybe_short_to_config({:navigate_to, url}) do
    %Config.Navigate{url: url}
  end

  defp maybe_short_to_config({:navigate_to, url, load_time}) do
    %Config.Navigate{url: url, load_time: load_time}
  end

  defp maybe_short_to_config({:input, selector, input}) do
    %Config.Input{selector: selector, input: input}
  end

  defp maybe_short_to_config({:click, selector}) do
    %Config.Click{selector: selector}
  end

  defp maybe_short_to_config({:click, selector, delay}) do
    %Config.Click{selector: selector, delay: delay}
  end

  defp maybe_short_to_config(:screenshot) do
    %Config.Screenshot{}
  end

  defp maybe_short_to_config({:screenshot, path}) do
    %Config.Screenshot{path: path}
  end

  defp maybe_short_to_config({:scroll, selector, x}) do
    %Config.Scroll{selector: selector, x_offset: x}
  end

  defp maybe_short_to_config({:scroll, selector, x, y}) do
    %Config.Scroll{selector: selector, x_offset: x, y_offset: y}
  end

  defp maybe_short_to_config({:read, key, selector}) do
    %Config.Read{key: key, selector: selector}
  end

  defp maybe_short_to_config({:sleep, period}) do
    %Config.Sleep{period: period}
  end

  defp maybe_short_to_config({:send_text, text}) do
    %Config.SendText{text: text}
  end

  defp maybe_short_to_config({:send_keys, keys}) when is_list(keys) do
    %Config.SendKeys{keys: keys}
  end

  defp maybe_short_to_config({:send_keys, key}) when is_atom(key) or is_binary(key) do
    %Config.SendKeys{keys: [key]}
  end

  defp maybe_short_to_config({:javascript, script}) do
    %Config.Javascript{script: script}
  end

  defp maybe_short_to_config({:javascript, key, script}) do
    %Config.Javascript{key: key, script: script}
  end

  defp maybe_short_to_config(config) when is_struct(config) do
    config
  end
end
