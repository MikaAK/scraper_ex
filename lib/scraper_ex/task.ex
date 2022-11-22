defmodule ScraperEx.Task do
  @moduledoc false

  defmodule Config.Navigate do
    @type t :: %__MODULE__{url: String.t, load_time: pos_integer}

    @enforce_keys [:url]
    defstruct [{:load_time, 100} | @enforce_keys]
  end

  defmodule Config.Input do
    @type t :: %__MODULE__{selector: Hound.Element.selector, input: String.t}

    @enforce_keys [:selector, :input]
    defstruct @enforce_keys
  end

  defmodule Config.Click do
    @type t :: %__MODULE__{selector: Hound.Element.selector, delay: pos_integer}

    @enforce_keys [:selector]
    defstruct [:delay | @enforce_keys]
  end

  defmodule Config.Screenshot do
    @type t :: %__MODULE__{path: String.t}
    defstruct [:path]
  end

  defmodule Config.Read do
    @type t :: %__MODULE__{selector: Hound.Element.selector, key: String.t | atom}

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

  defp maybe_prepare_config({:click, selector, delay}) do
    %Config.Click{selector: selector, delay: delay}
  end

  defp maybe_prepare_config(:screenshot) do
    %Config.Screenshot{}
  end

  defp maybe_prepare_config({:screenshot, path}) do
    %Config.Screenshot{path: path}
  end

  defp maybe_prepare_config({:read, key, selector}) do
    %Config.Read{key: key, selector: selector}
  end

  defp maybe_prepare_config(config) when is_struct(config) do
    config
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

  defp run_config(%Config.Input{selector: selector, input: input}) do
    try do
      Hound.Helpers.Element.fill_field(selector, input)
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

  defp run_config(%Config.Read{selector: {strategy, selector}, key: key}) do
    try do
      case Hound.Helpers.Page.find_all_elements(strategy, selector) do
        [] -> {:ok, {key, nil}}
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

  defp element_inner_text(element) do
    element
      |> Hound.Helpers.Element.inner_text
      |> String.normalize(:nfkc)
  end
end
