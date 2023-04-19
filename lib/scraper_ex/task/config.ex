defmodule ScraperEx.Task.Config do
  defmodule Navigate do
    @moduledoc "Navigates to a page, can specify `load_time`"
    @type t :: %__MODULE__{url: String.t, load_time: pos_integer}

    @enforce_keys [:url]
    defstruct [{:load_time, 100} | @enforce_keys]
  end

  defmodule Input do
    @moduledoc "Inputs text into a input"
    @type t :: %__MODULE__{selector: Hound.Element.selector, input: String.t}

    @enforce_keys [:selector, :input]
    defstruct @enforce_keys
  end

  defmodule Click do
    @moduledoc "Clicks a element on the page"
    @type t :: %__MODULE__{selector: Hound.Element.selector, delay: pos_integer}

    @enforce_keys [:selector]
    defstruct [:delay | @enforce_keys]
  end

  defmodule Scroll do
    @moduledoc "Scrolls an element"
    @type t :: %__MODULE__{selector: Hound.Element.selector, x_offset: pos_integer, y_offset: pos_integer}
    @enforce_keys [:selector]
    defstruct [{:x_offset, 0}, {:y_offset, 0} | @enforce_keys]
  end

  defmodule Screenshot do
    @moduledoc "Takes a screenshot"
    @type t :: %__MODULE__{path: String.t}
    defstruct [:path]
  end

  defmodule Sleep do
    @moduledoc "Sleep for x period"
    @type t :: %__MODULE__{period: pos_integer}
    defstruct [:period]
  end

  defmodule SendKeys do
    @moduledoc "Sends amount of keys defined by `&Hound.Helpers.Page.send_keys/1`"
    @type t :: %__MODULE__{keys: list(atom) | atom}
    defstruct [:keys]
  end

  defmodule SendText do
    @moduledoc "Sleep for x period"
    @type t :: %__MODULE__{text: String.t}
    defstruct [:text]
  end

  defmodule Read do
    @moduledoc """
    Reads a value from the page and stores it under a key, this key will be used to build
    a map with all the read values
    """
    @type t :: %__MODULE__{selector: Hound.Element.selector, key: String.t | atom, html?: boolean}

    @enforce_keys [:selector, :key]
    defstruct [:value | @enforce_keys] ++ [html?: false]
  end

  defmodule Javascript do
    @moduledoc """
    Runs a JS function, if key is specified
    the return results make it back on the end map
    """

    @type t :: %__MODULE__{script: String.t, key: String.t | atom}

    @enforce_keys [:script]
    defstruct [:key | @enforce_keys]
  end
end
