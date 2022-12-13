defmodule MLLParty.Helpers do
  @port_range 1..65535

  def valid_ip?(ip) when is_binary(ip) do
    case :inet.parse_address(String.to_charlist(ip)) do
      {:ok, _ip} -> true
      _ -> false
    end
  end

  def valid_ip?(_ip), do: false

  def valid_port?(port) when is_binary(port) do
    port
    |> String.to_integer()
    |> valid_port?()
  end

  def valid_port?(port) when is_integer(port), do: port in @port_range
end
