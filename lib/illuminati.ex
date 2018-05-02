defmodule Illuminati do
  @moduledoc """
  Documentation for Illuminati.
  """

  require Logger

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
  def simplify_logs(some), do: some

  @doc """

  Macro returns result of given block of code and
  log its result + elapsed time (in ms).

  """
  defmacro tc(source_code, logger_metadata \\ [], logger_message \\ "", statsd_metric_postfix \\ "")
  defmacro tc(source_code, logger_metadata, logger_message, statsd_metric_postfix) do
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
              String.trim("#{function_fullname} #{unquote(logger_message)}"),
              Keyword.merge([elapsed_time: elapsed_time_milliseconds, result: IhCore.Utils.simplify_logs(result)], unquote(logger_metadata)))

        _ = ExStatsD.timer(
              elapsed_time_milliseconds,
              full_statsd_metric)

        result
      )
    end
  end

end
