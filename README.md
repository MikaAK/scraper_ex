# ScraperEx

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
Tasks are defined by configs, you can either use the struct form using `ScraperEx.Task.Config` modules or use the short forms

The following actions are currently implemented:
- `:navigate_to` or `ScraperEx.Task.Config.Navigate`
- `:input` or `ScraperEx.Task.Config.Input`
- `:click` or `ScraperEx.Task.Config.click`
- `:read` or `ScraperEx.Task.Config.Read`

#### Example
```elixir
iex> ScraperEx.run_task_in_window([
...>   {:navigate_to, "http://mysite.gg"},
...>   {:read, :username, {:css, ".my_username-selector"}},
...>   {:read, :rank, {:id, "my-id"}},
...>   {:navigate_to, "http://mysite.gg"},
...>   {:click, {:css, ".my-button-forward"}},
...>   {:read, :item_url, {:css, ".my-item-url"}},
...> ])
%{username: "MyUsername", rank: "Gold", item_url: "https://google.com"}
```
