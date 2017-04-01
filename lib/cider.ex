defmodule Cider do
  @moduledoc """
  Parsing and matching of CIDRs with ips.
  """

  if :erlang.system_info(:wordsize) < 8,
    do: raise "Cider: 32-bit Architecture not supported."

  @typedoc "A cidr made out of {`ip`, `subnet_mask`}."
  @type t :: {integer, integer}
  @typedoc "A tuple with each octet of the ip."
  @type ip :: {integer, integer, integer, integer}

  @doc ~S"""
  Parses a CIDR in list representation.
  The first 4 items are the octets of the ip.
  THe last item is the bit mask.

  Example:
      iex> Cider.parse 192, 168, 0, 0, 24
      {3232235520, 4294967040}
  """
  @spec parse(integer, integer, integer, integer, integer) :: t
  def parse(a, b, c, d, bit_mask \\ 32) do
    parse({a, b, c, d}, bit_mask)
  end

  @doc ~S"""
  Parses a CIDR in string representation.

  Example:
      iex> Cider.parse "192.168.0.0/24"
      {3232235520, 4294967040}
  """
  @spec parse(String.t) :: t
  def parse(cidr) do
    :erlang.apply Cider,
                  :parse,
                  cidr
                  |> String.split(~r/\.|\//)
                  |> Enum.map(&String.to_integer/1)
  end

  @doc ~S"""
  Creates a CIDR based on an ip and bit mask.

  The ip is represented by an octet tuple.

  Example:
      iex> Cider.parse {192, 168, 0, 0}, 24
      {3232235520, 4294967040}
  """
  @spec parse(ip, integer) :: t
  def parse(ip, bit_mask) do
    ip = ip_to_int(ip)
    subnet_mask = create_mask(bit_mask)

    {:erlang.band(ip, subnet_mask), subnet_mask}
  end

  @doc ~S"""
  Checks whether a given `ip` falls within a `cidr` range.
  """
  @spec contains?(ip, t) :: boolean
  def contains?(ip, {cidr, subnet_mask}) do
    (
      ip
      |> ip_to_int()
      |> :erlang.band(subnet_mask)
      |> :erlang.bxor(cidr)
    ) == 0
  end

  @spec ip_to_int(ip) :: integer
  defp ip_to_int({a, b, c, d}) do
    d
    |> :erlang.bor(:erlang.bsl(c, 8))
    |> :erlang.bor(:erlang.bsl(b, 16))
    |> :erlang.bor(:erlang.bsl(a, 24))
  end

  @spec create_mask(integer) :: integer
  defp create_mask(bit_mask) do
    shift = 32 - bit_mask

    4_294_967_295 # 0xffffffff (32 bits)
    |> :erlang.bsr(shift)
    |> :erlang.bsl(shift)
  end
end
