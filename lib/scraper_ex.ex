defmodule ScraperEx do
  @external_resource "../README.md"
  @moduledoc "#{File.read!("./README.md")}"

  alias ScraperEx.Window

  def run_task_in_window(configs, window_opts \\ []) do
    with {:ok, pid} <- Window.start_link(window_opts) do
      pid
        |> Window.run_in_window(fn _ -> ScraperEx.Task.run(configs) end)
        |> tap(fn _ -> Window.shutdown(pid) end)
    end
  end

  defdelegate run_task(configs), to: ScraperEx.Task, as: :run
end
