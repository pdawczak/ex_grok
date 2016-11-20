defmodule ExGrok.NgrokLogParser do
  @moduledoc """
  Helps parsing ngrok logs that come from spawned port.

  Those logs consit of established connection parameters, but also will notify
  if something went wrong.
  """

  @type parsed :: map
  @type success :: {:ok, parsed}
  @type error :: :error

  @type result :: success | error

  @doc """
  Parses the string `str` provided.

  ## Examples

      iex> ExGrok.NgrokLogParser.parse("")
      {:ok, %{}}

      iex> log = ~s{t=2016-11-11T20:52:54+0000 msg="A message"}
      iex> ExGrok.NgrokLogParser.parse(log)
      {:ok, %{"t" => "2016-11-11T20:52:54+0000", "msg" => "A message"}}

  """
  @spec parse(String.t) :: result
  def parse(str) do
    str
    |> String.to_char_list()
    |> do_parse_key([], Map.new())
  end

  # It parses the key part of string provided.
  #
  # It terminates in two cases:
  #
  #   * by encountering `"="` which indicates key-value relation, in which case
  #     it will delegate furhter parsing to `do_start_parse_value`
  #   * due to lack of more data to process, in which case it returns accumulated
  #     `parsed` map.
  @spec do_parse_key(charlist, charlist, parsed) :: result
  defp do_parse_key(data_to_parse, key_acc, parsed)

  defp do_parse_key([], [], parsed), do: {:ok, parsed}
  # If no `=` encountered when parsing the key - :error, no matching value
  defp do_parse_key([], _k, _parsed), do: :error
  defp do_parse_key([?= | rest], k, parsed) do
    do_start_parse_value(rest, k, parsed)
  end
  defp do_parse_key([c | rest], k, parsed) do
    do_parse_key(rest, [c | k], parsed)
  end

  # It performs further parsing of the data.
  #
  # It is meant to take parsing over from `do_parse_key` key. It's main purpose is
  # to detect if the data to be parsed is an embedded string (delimited by `"`),
  # or just single word like string.
  @spec do_start_parse_value(charlist, charlist, parsed) :: result
  defp do_start_parse_value(data_to_parse, key_acc, parsed)

  defp do_start_parse_value([?" | rest], k, parsed) do
    do_parse_embedded_string(rest, k, [], parsed)
  end
  defp do_start_parse_value(rest, k, parsed) do
    do_parse_string(rest, k, [], parsed)
  end

  # It performs parsing of embedded string.
  #
  # Embedded strings are delimited by `"` which allows them to store white space,
  # thus it is important not to treat them as value delimiters.
  @spec do_parse_embedded_string(charlist, charlist, charlist, parsed) :: result
  defp do_parse_embedded_string(data_to_parse, key_acc, val_acc, parsed)

  defp do_parse_embedded_string([], _k, _v, _parsed), do: :error
  defp do_parse_embedded_string([?", ?\s | rest], k, v, parsed) do
    do_stop_parse_string_or_value(rest, k, v, parsed)
  end
  defp do_parse_embedded_string([?" | rest], k, v, parsed) do
    do_stop_parse_string_or_value(rest, k, v, parsed)
  end
  defp do_parse_embedded_string([c | rest], k, v, parsed) do
    do_parse_embedded_string(rest, k, [c | v], parsed)
  end

  # It performs parsing of one-word string.
  #
  # It treats whitespace as a delimiter of string parsed.
  @spec do_parse_string(charlist, charlist, charlist, parsed) :: result
  defp do_parse_string(data_to_parse, key_acc, val_acc, parsed)

  defp do_parse_string([], k, v, parsed) do
    do_stop_parse_string_or_value([], k, v, parsed)
  end
  defp do_parse_string([?\s | rest], k, v, parsed) do
    do_stop_parse_string_or_value(rest, k, v, parsed)
  end
  defp do_parse_string([c | rest], k, v, parsed) do
    do_parse_string(rest, k, [c | v], parsed)
  end

  # It is helper function that is used for repetitive task when parsing strings.
  @spec do_stop_parse_string_or_value(charlist, charlist, charlist, parsed) :: result
  defp do_stop_parse_string_or_value(rest, k, v, parsed) do
    new_parsed = put_in_parsed(parsed, k, v)

    do_parse_key(rest, [], new_parsed)
  end

  # It updates `parsed`.
  #
  # It uses parsed `k` as a key and `v` as a value of new element to be put in
  # `parsed` map.
  @spec put_in_parsed(parsed, charlist, charlist) :: parsed
  defp put_in_parsed(parsed, k, v) do
    Map.put(
      parsed,
      k |> Enum.reverse() |> to_string(),
      v |> Enum.reverse() |> to_string()
    )
  end
end
