defmodule ScraperEx.Window do
  @moduledoc """
  This module exists to manage Hound sessions. One session is started per window
  and you can run functions on this window. To start multiple windows you
  create multiple of these processes.

  ### Example

  ```elixir
  import Hound.Helpers

  {:ok, pid} = ScraperEx.Window.start_link()

  ScraperEx.Window.run_in_window(pid, fn session_id ->
    navigate_to("https://mysite.com")
    fill_field({:css, ".selector"}, "Hello World")
  end)
  ```
  """

  require Logger

  use GenServer

  alias ScraperEx.Window

  @supported_ua "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/105.0.0.0 Safari/537.36"

  def child_spec(opts) do
    %{
      id: :"scraper_ex_window_#{Enum.random(1..100_000_000_000)}",
      start: {Window, :start_link, [opts]}
    }
  end

  def start_link(opts \\ []) do
    opts = Keyword.update(opts, :name, nil, &server_name/1)

    GenServer.start_link(Window, opts[:start_fn], opts)
  end

  def init(start_fn) do
    session_id = Hound.Helpers.Session.start_session(user_agent: @supported_ua)

    Process.flag(:trap_exit, true)

    {:ok, session_id, {:continue, start_fn}}
  end

  def handle_continue(start_fn, session_id) do
    if not is_nil(start_fn) do
      Logger.debug("Executing start_fn with session #{session_id}")
      start_fn.()
    end

    {:noreply, session_id}
  end

  defp server_name(name), do: :"#{name}_scraper_ex"

  def close_and_reopen_window(pid) do
    GenServer.call(pid, :remake_session)
  end

  def shutdown(pid) do
    GenServer.stop(pid)
  end

  def run_in_window(pid, function) when is_pid(pid) do
    GenServer.call(pid, {:run_in_window, function}, :timer.hours(2))
  end

  def run_in_window(name, function) do
    GenServer.call(server_name(name), {:run_in_window, function}, :timer.hours(2))
  end

  def handle_call(:remake_session, _from, session_id) do
    Hound.Helpers.Session.end_session()

    Process.sleep(100)
    new_session_id = Hound.Helpers.Session.start_session()
    Process.sleep(100)
    Logger.debug("Remaking session #{session_id} into #{new_session_id}")

    {:reply, new_session_id, new_session_id}
  end

  def handle_call({:run_in_window, function}, _from, session_id) do
    {:reply, function.(session_id), session_id}
  end

  def terminate(reason, session_id) do
    if reason !== :normal do
      Logger.error("Hound window #{session_id} terminating because of #{inspect reason, pretty: true}")
    else
      Logger.info("Hound window #{session_id} terminating")
    end

    Hound.Helpers.Session.change_session_to(session_id)
    Hound.Helpers.Session.end_session()
  end
end
