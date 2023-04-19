# ScraperEx
 [![Hex version badge](https://img.shields.io/hexpm/v/scraper_ex.svg)](https://hex.pm/packages/scraper_ex)
<!-- [![Coverage](https://github.com/MikaAK/scraper_ex/actions/workflows/coverage.yml/badge.svg)](https://github.com/MikaAK/scraper_ex/actions/workflows/coverage.yml) -->
[![Credo](https://github.com/MikaAK/scraper_ex/actions/workflows/credo.yml/badge.svg)](https://github.com/MikaAK/scraper_ex/actions/workflows/credo.yml)
[![Dialyzer](https://github.com/MikaAK/scraper_ex/actions/workflows/dialyzer.yml/badge.svg)](https://github.com/MikaAK/scraper_ex/actions/workflows/dialyzer.yml)
<!-- [![Test](https://github.com/MikaAK/scraper_ex/actions/workflows/test.yml/badge.svg)](https://github.com/MikaAK/scraper_ex/actions/workflows/test.yml) -->

This library exists to make scraping a bit easier for business use cases

## Installation

[Available in Hex](https://hex.pm/scraper_ex), the package can be installed
by adding `scraper_ex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:scraper_ex, "~> 0.1.0"}
  ]
end
```

The docs can be found at <https://hexdocs.pm/scraper_ex>.


## Usage
`ScraperEx` uses Hound under the hood, which means you can configure hound to use any browser/runner you'd like. By default we use chrome_headless


#### `ScraperEx.Window`
This module exists to manage windows with Hound. Hounds window management by default doesn't help very much with session management, which leads to
zombie windows hanging around and can really start to eat up memory. To avoid this we can use `ScraperEx.Window` to run and interact with a
individual session

#### `ScraperEx`
The two useful functions in here are `ScraperEx.run_task_in_window` and
`ScraperEx.run_task`, run task allows you to input various steps for a
scraper while run_in_window will also start a window for you, the bare
version won't and you will need to manage your own `ScraperEx.Window`


### Tasks
Tasks (Flows) are defined by configs, you can either use the struct form using `ScraperEx.Task.Config` modules or use the short forms

The following actions are currently implemented:
- `:navigate_to` or `ScraperEx.Task.Config.Navigate`
- `:input` or `ScraperEx.Task.Config.Input`
- `:click` or `ScraperEx.Task.Config.Click`
- `:read` or `ScraperEx.Task.Config.Read`
- `:screenshot` or `ScraperEx.Task.Config.Screenshot`
- `:scroll` or `ScraperEx.Task.Config.Scroll`
- `:sleep` or `ScraperEx.Task.Config.Sleep`
- `:send_text` or `ScraperEx.Task.Config.SendText`
- `:send_keys` or `ScraperEx.Task.Config.SendKeys`
- `:javascript` or `ScraperEx.Task.Config.Javascript`

You can allow errors by wrapping a command in
```elixir
  ScraperEx.allow_error({:click, {:css, ".thing"}})
```

#### Example
```elixir
iex> ScraperEx.run_task_in_window([
...>   {:navigate_to, "https://en.wikipedia.org/wiki/Example.com"},
...>   {:read, :references, {:css, ".reference-text"}},
...>   {:read, :page_title, {:id, "firstHeading"}},
...>   {:read, :external_link_4, {:css, "#bodyContent ul:nth-child(21) li:nth-child(4)"}},
...>   {:click, {:css, "h2:has(#External_links) + ul li:nth-of-type(3) a"}, :timer.seconds(1)},
...>   {:read, :clicked_url, {:css, "h1"}},
...> ])
{:ok, %{ \
  page_title: "example.com", \
  external_link_4: "example.edu", \
  clicked_url: "Example Domain", \
  references: [ \
    "\"IANA WHOIS Service\". IANA. Retrieved 2022-10-25.", \
    "\"IANA-managed Reserved Domains\". IANA. Retrieved 2020-06-20.", \
    "RFC 2606, Reserved Top Level DNS Names, D. Eastlake, A. Panitz, The Internet Society (June 1999), Section 3.", \
    "RFC 6761, S. Cheshire, M. Krochmal, Special-Use Domain Names, IETF (February 2013)" \
  ] \
}}
```

### Testing
We can test and mock out specific flow responses by using `ScraperEx.Sandbox`

First we must call `ScraperEx.Sandbox.start_link()` in our `test_helpers.ex` file, then
Inside our test, we can do

```elixir
  ScraperEx.Sandbox.set_run_task_result(my_flow(), %{my_result: :ok})
```

in each test to set the response of a specific flow.
