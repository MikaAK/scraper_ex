defmodule ScraperEx do
  @external_resource "./README.md"
  @moduledoc "#{File.read!("./README.md")}"

  @type window_opts :: [
    name: String.t(),
    start_fn: (() -> any),
    sandbox?: boolean
  ]

  @type task_opts :: [
    sandbox?: boolean
  ]

  @type task_atom_config :: {:navigate_to, url :: String.t} |
                            {:navigate_to, url :: String.t, load_time :: pos_integer} |
                            {:input, Hound.Element.selector} |
                            {:value, key :: String.t | atom, Hound.Element.selector} |
                            {:click, Hound.Element.selector} |
                            :screenshot |
                            {:screenshot, path :: String.t} |
                            {:scroll, x :: pos_integer} |
                            {:scroll, x :: pos_integer, y :: pos_integer} |
                            {:sleep, period :: pos_integer} |
                            {:send_text, text :: String.t} |
                            {:send_keys, keys :: list(atom) | atom} |
                            {:javascript, script :: String.t} |
                            {:javascript, key :: atom | String.t, script :: String.t}

  @type task_module_config :: ScraperEx.Task.Config.Screenshot.t |
                              ScraperEx.Task.Config.Navigate.t |
                              ScraperEx.Task.Config.Input.t |
                              ScraperEx.Task.Config.Click.t |
                              ScraperEx.Task.Config.Scroll.t |
                              ScraperEx.Task.Config.Read.t

  @type task_config :: task_atom_config | task_module_config | {:allow_error, task_atom_config | task_module_config}

  alias ScraperEx.Window

  @spec run_task_in_window(list(task_config), window_opts) :: ErrorMessage.t_res(map)
  @doc """
  This function allows you to run a task and a window is started for you,
  good for times where you have a short running task to open and close a web page

  ### Example

      iex> ScraperEx.run_task_in_window([
      ...>   {:navigate_to, "https://example.com/", :timer.seconds(1)},
      ...>   {:click, {:css, "a"}, :timer.seconds(1)},
      ...>   {:read, :page_title, {:css, "h1"}},
      ...> ])
      {:ok, %{page_title: "IANA-managed Reserved Domains"}}
  """
  def run_task_in_window(configs, window_opts \\ []) do
    if window_opts[:sandbox?] do
      ScraperEx.Sandbox.run_task_result(configs)
    else
      with {:ok, pid} <- Window.start_link(window_opts) do
        pid
          |> Window.run_in_window(fn _ -> ScraperEx.Task.run(configs) end)
          |> tap(fn _ -> Window.shutdown(pid) end)
      end
    end
  end

  @spec run_task(list(task_config)) :: ErrorMessage.t_res(map)
  @spec run_task(list(task_config), task_opts) :: ErrorMessage.t_res(map)
  @doc """
  This function allows you to run a task within a window you control, good for times
  where you have a long running window you need to run multiple tasks on

  ### Example

      iex> Hound.start_session()
      iex> ScraperEx.run_task([
      ...>   {:navigate_to, "https://example.com/", :timer.seconds(1)},
      ...>   {:click, {:css, "a"}, :timer.seconds(1)},
      ...>   {:read, :page_title, {:css, "h1"}},
      ...> ])
      {:ok, %{page_title: "IANA-managed Reserved Domains"}}
      iex> Hound.end_session()
  """
  def run_task(configs, opts \\ []) do
    if opts[:sandbox?] do
      ScraperEx.Sandbox.run_task_result(configs)
    else
      ScraperEx.Task.run(configs)
    end
  end

  @spec allow_error(task_config) :: {:allow_error, task_atom_config | task_module_config}
  def allow_error(config) do
    {:allow_error, config}
  end
end
