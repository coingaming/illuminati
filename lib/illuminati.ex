defmodule Illuminati do
  @moduledoc """
  Documentation for Illuminati.
  """

  defmacro __using__(_) do
    quote do
      require Logger
      require Illuminati
    end
  end

  @doc """

  Function trims extra data from list of maps/structs

  ## Example

  iex> Illuminati.simplify_logs([%{foo: 123}, %{foo: 321}])
  [%{foo: 123}, "..."]
  """

  def simplify_logs(struct = %_{}) do
    struct
    |> Map.from_struct
    |> Map.delete(:__meta__)
    |> simplify_logs
  end
  def simplify_logs(map = %{}) do
    Enum.reduce(map, %{}, fn
      ({_, nil}, acc = %{}) -> acc
      ({k, v}, acc = %{}) -> Map.put(acc, simplify_logs(k), simplify_logs(v))
    end)
  end
  def simplify_logs([head = %{} | _]), do: [simplify_logs(head), "..."]
  def simplify_logs(list) when is_list(list), do:  Enum.map(list, &simplify_logs/1)
  def simplify_logs(bin) when is_binary(bin) do
    bin
    |> String.valid?
    |> case do
      true -> bin
      false -> inspect(bin)
    end
  end
  def simplify_logs(pid) when is_pid(pid) do
    pid
    |> :erlang.pid_to_list
    |> to_string
  end
  def simplify_logs(ref) when is_reference(ref) do
    ref
    |> :erlang.ref_to_list
    |> to_string
  end
  def simplify_logs(some), do: some

  @doc """

  Macro returns result of given block of code and
  log its result + elapsed time (in ms).

  ## Example

  iex> use Illuminati
  Illuminati
  iex> (1 + 1) |> Illuminati.tc(:arithmetics, "function plus")
  2
  """

  defmacro tc(source_code,
              result_label          \\ :result,
              logger_message        \\ "",
              logger_metadata       \\ [],
              statsd_options        \\ [],
              statsd_metric_postfix \\ "",
              illuminati_opts       \\ [simplify_logs: false]) do

    {opts, []} =
      illuminati_opts
      |> Code.eval_quoted([], __CALLER__)

    logged_result =
      opts
      |> case do
        [simplify_logs: true] ->
          quote do
            Illuminati.simplify_logs(result)
          end
        [simplify_logs: false] ->
          quote do
            result
          end
      end

    quote do
      (

        {elapsed_time_microseconds, result} = :timer.tc(fn() -> unquote(source_code) end)
        elapsed_time_milliseconds = div(elapsed_time_microseconds, 1000)

        {function_name, _}  = __ENV__.function

        function_fullname   = __MODULE__
                              |> Atom.to_string
                              |> String.trim_leading("Elixir.")
                              |> Kernel.<>(".#{function_name}")

        full_statsd_metric  = [function_fullname, unquote(statsd_metric_postfix)]
                              |> Stream.map(&String.trim/1)
                              |> Stream.filter(&(&1 != ""))
                              |> Enum.join(".")
                              |> String.replace(" ", "_")
                              |> String.replace(".", "_")
                              |> String.downcase

        _ = Logger.info(
              unquote(logger_message),
              Keyword.merge([
                  {:elapsed_time, elapsed_time_milliseconds},
                  {:function_fullname, function_fullname},
                  {unquote(result_label), unquote(logged_result)}
                ],
                unquote(logger_metadata)))

        _ = ExStatsD.timer(
              elapsed_time_milliseconds,
              full_statsd_metric,
              unquote(statsd_options))

        result
      )
    end
  end

end
