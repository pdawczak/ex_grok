# ExGrok

Low dependencies ngrok wrapper.

Tiny wrapper that will take care about ngrok connection for your Phoenix web
applications you're working on and want to share with broader audience without
need of deploying it.

## Installation

The package can be installed as:

  1. Add `ex_grok` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:ex_grok, "~> 0.1.0"}]
    end
    ```

  2. Ensure `ex_grok` is started before your application:

    ```elixir
    def application do
      [applications: [:ex_grok]]
    end
    ```

## Configuration

By default `ex_grok` will try to establish connection only in `dev` environment.
It is easy to change this behaviour by enabling it in `config/config.exs` file:

```elixir
config :ex_grok, enabled: true
```

ngrok provides couple possible connection options, `ex_grok` however, makes use
of `http` only at the moment.

It will try to use global `ngrok` command exposing port `4000` (default port
that Phoenix uses in development), but it can be changed in `config/config.exs`:

```elixir
config :ex_grok, :command,
  executable: "path/to/ngrok",
  port: "3040"
```

## Usage

Once your application is up and running, and ngrok connection has been
established successfully, the available urls will be reported in logs:

```
20:48:28.447 [info]  ngrok connection established - http://12345678.ngrok.io, https://12345678.ngrok.io
```

The same information can be obtained with `ExGrok.connection/1`:

```
iex> ExGrok.connection()
%ExGrok.Connection{http: "http://12345678.ngrok.io",
                   https: "https://12345678.ngrok.io"}
```
