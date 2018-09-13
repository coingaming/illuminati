# Illuminati

Utilities for logging and monitoring. Includes Logstash and StatsD applications.

<img src="priv/icon.png" alt="Logo" width="200"/>

## Installation

Add `illuminati` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:illuminati, "heathmont/illuminati"}
  ]
end
```

## Configuration

Logstash and StatsD applications should be configured in your application `config/*.exs` files like this:

```elixir
config :logger,
  backends: [
    :console,
    {LogstashJson.Console, :json}
  ]

config :ex_statsd,
  host: "your.statsd.host.com",
  port: 1234,
  namespace: "your-app",
  tags: ["env:#{Mix.env}"]
```

## Usage

Add on top of the file

```elixir
use Illuminati
```

and use **&Illuminati.tc/6** macro to log result and elapsed time for any expression

```elixir
(
  %HTTPoison.Response{body: body, status_code: 200} =
    args
    |> remote_call

  body
  |> decode
  |> process
)
|> Illuminati.tc(result_label,
                 logger_message,
                 logger_metadata,
                 statsd_options,
                 statsd_metric_postfix)
```

also **&Illuminati.tc/6** macro provides default values

```elixir
defmacro tc(source_code,
            result_label          \\ :result,
            logger_message        \\ "",
            logger_metadata       \\ [],
            statsd_options        \\ [],
            statsd_metric_postfix \\ "")
```
