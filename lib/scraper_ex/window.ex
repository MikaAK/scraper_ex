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

    GenServer.start_link(Window, opts, opts)
  end

  def init(opts) do
    session_id = if !opts[:sandbox?] do
      id = Hound.Helpers.Session.start_session(user_agent: @supported_ua)

      Process.flag(:trap_exit, true)

      Logger.info("Hound window #{id} started")

      id
    else
      :not_started_due_to_sandbox
    end

    opts = Keyword.put(opts, :session_id, session_id)

    {:ok, opts, {:continue, opts[:start_fn]}}
  end

  def handle_continue(start_fn, opts) do
    if not is_nil(start_fn) do
      Logger.debug("Executing start_fn with session #{opts[:session_id]}")
      start_fn.()
    end

    {:noreply, opts}
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

  def handle_call(:remake_session, _from, opts) do
    if not opts[:sandbox?] do
      Hound.Helpers.Session.end_session()

      Process.sleep(100)
      new_session_id = Hound.Helpers.Session.start_session()
      Process.sleep(100)
      Logger.debug("Remaking session #{opts[:session_id]} into #{new_session_id}")

      {:reply, new_session_id, Keyword.put(opts, :session_id, new_session_id)}
    else
      {:reply, opts[:session_id], opts}
    end
  end

  def handle_call({:run_in_window, function}, _from, opts) do
    {:reply, function.(opts[:session_id]), opts}
  end

  def terminate(reason, opts) do
    session_id = opts[:session_id]

    if reason !== :normal do
      Logger.error("Hound window #{session_id} terminating because of #{inspect reason, pretty: true}")
    else
      Logger.info("Hound window #{session_id} terminating")
    end

    Hound.Helpers.Session.change_session_to(session_id)
    Hound.Helpers.Session.end_session()
  end
end
