defmodule Cider do
  @moduledoc """
  Parsing and matching of CIDRs with ips.
  """

  if :erlang.system_info(:wordsize) < 8,
    do: raise("Cider: 32-bit Architecture not supported.")

  @default_mask [
    ipv4: 32,
    ipv6: 128
  ]

  @typedoc "A cidr made out of {`ip`, `subnet_mask`}."
  @type t :: {integer, integer} | Range.t()

  @typedoc "A tuple with each octet of the ip."
  @type ip ::
          {integer, integer, integer, integer}
          | {integer, integer, integer, integer, integer, integer, integer, integer}

  @typedoc ~S"An IP represented as integer"
  @type raw_ip :: integer

  @doc ~S"""
  Parses a CIDR in list representation.
  The first 4 items are the octets of the ip.
  The last item is the bit mask.

  ## Examples

  ```elixir
  iex> Cider.parse 192, 168, 0, 0, 24
  {3232235520, 4294967040}
  ```
  """
  @spec parse(integer, integer, integer, integer, integer | nil) :: t
  def parse(a, b, c, d, bit_mask \\ nil) do
    parse({a, b, c, d}, bit_mask)
  end

  @doc ~S"""
  Parses a CIDR in string representation.

  ## Examples

  ```elixir
  iex> Cider.parse "192.168.0.0/24"
  {3232235520, 4294967040}
  ```

  ```elixir
  iex> Cider.parse "192.168.0.1-24"
  3232235521..3232235544
  ```
  """
  @spec parse(String.t()) :: t
  def parse(cidr) do
    if String.contains?(cidr, "-") do
      [ip, range] = String.split(cidr, "-")
      range = String.to_integer(range)

      case ip |> String.to_charlist() |> :inet.parse_address() do
        {:ok, ip = {a, b, c, _}} -> ip!(ip)..ip!({a, b, c, range})
        {:ok, ip = {a, b, c, d, e, f, g, _}} -> ip!(ip)..ip!({a, b, c, d, e, f, g, range})
      end
    else
      [ip | mask] = String.split(cidr, "/")
      {:ok, ip_tuple} = ip |> String.to_charlist() |> :inet.parse_address()
      mask = if mask == [], do: nil, else: mask |> List.first() |> String.to_integer()

      parse(ip_tuple, mask)
    end
  end

  @doc ~S"""
  Creates a CIDR based on an ip and bit_mask.

  The ip is represented by an octet tuple.

  ## Examples

  ```elixir
  iex> Cider.parse {192, 168, 0, 0}, 24
  {3232235520, 4294967040}
  iex> Cider.parse {0, 0, 0, 0, 0, 65535, 49320, 10754}, 128
  {281473913989634, 340282366920938463463374607431768211455}
  ```
  """
  @spec parse(ip, integer | nil) :: t
  def parse(ip, bit_mask) do
    {ip, format} = ip_to_int(ip)
    subnet_mask = create_mask(bit_mask || @default_mask[format], format)

    {:erlang.band(ip, subnet_mask), subnet_mask}
  end

  @doc ~S"""
  Checks whether a given `ip` falls within a `cidr` range.

  ## Example
  ```elixir
  iex> Cider.contains?({192, 168, 0, 1}, Cider.parse({192, 168, 0, 0}, 24))
  true
  iex> Cider.contains?(3232235520, Cider.parse({192, 168, 0, 0}, 24))
  true
  iex> Cider.contains?({192, 168, 254, 1}, Cider.parse({192, 168, 0, 0}, 24))
  false
  ```
  """
  @spec contains?(ip | raw_ip, t) :: boolean
  def contains?(ip, {cidr, subnet_mask}) when is_integer(ip) do
    ip
    |> :erlang.band(subnet_mask)
    |> :erlang.bxor(cidr) == 0
  end

  def contains?(ip, range = _.._) when is_integer(ip), do: ip in range

  def contains?(ip, match), do: ip |> ip!() |> contains?(match)

  @doc ~S"""
  Returns the raw numeric IP.

  ## Examples
  ```elixir
  iex> Cider.ip!("192.168.1.1")
  3_232_235_777
  iex> Cider.ip!({192, 168, 1, 1})
  3_232_235_777
  ```
  """
  @spec ip!(binary | tuple) :: raw_ip | no_return
  def ip!(ip) when is_binary(ip) do
    {:ok, ip} = ip |> String.to_charlist() |> :inet.parse_address()
    ip |> ip_to_int() |> elem(0)
  end

  def ip!(ip) do
    ip |> ip_to_int() |> elem(0)
  end

  @spec ip_to_int(ip) :: {raw_ip, :ipv4 | :ipv6}
  defp ip_to_int({a, b, c, d, e, f, g, h}) do
    {
      h
      |> :erlang.bor(:erlang.bsl(g, 16))
      |> :erlang.bor(:erlang.bsl(f, 32))
      |> :erlang.bor(:erlang.bsl(e, 48))
      |> :erlang.bor(:erlang.bsl(d, 64))
      |> :erlang.bor(:erlang.bsl(c, 80))
      |> :erlang.bor(:erlang.bsl(b, 96))
      |> :erlang.bor(:erlang.bsl(a, 112)),
      :ipv6
    }
  end

  defp ip_to_int({a, b, c, d}) do
    {
      d
      |> :erlang.bor(:erlang.bsl(c, 8))
      |> :erlang.bor(:erlang.bsl(b, 16))
      |> :erlang.bor(:erlang.bsl(a, 24)),
      :ipv4
    }
  end

  @spec create_mask(integer, :ipv4 | :ipv6) :: integer
  defp create_mask(bit_mask, :ipv4) do
    shift = 32 - bit_mask

    # 0xffffffff (32 bits)
    4_294_967_295
    |> :erlang.bsr(shift)
    |> :erlang.bsl(shift)
  end

  defp create_mask(bit_mask, :ipv6) do
    shift = 128 - bit_mask

    # 0xf..f (128 bits)
    340_282_366_920_938_463_463_374_607_431_768_211_455
    |> :erlang.bsr(shift)
    |> :erlang.bsl(shift)
  end

  ### Convenience ###

  @doc ~S"""
  Convert a tuple or numeric IP to string.

  ## Examples

  ```elixir
  iex> Cider.to_string({192, 168, 1, 1})
  "192.168.1.1"
  iex> Cider.to_string(3_232_235_777)
  "192.168.1.1"
  iex> Cider.to_string({0, 0, 0, 0, 0, 65535, 49320, 10754})
  "0:0:0:0:0:FFFF:C0A8:2A02"
  iex> Cider.to_string(281_473_913_989_634)
  "0:0:0:0:0:FFFF:C0A8:2A02"
  ```
  """
  @spec to_string(tuple | integer) :: String.t()
  def to_string({a, b, c, d}), do: "#{a}.#{b}.#{c}.#{d}"

  def to_string(ip) when is_tuple(ip) do
    ip
    |> Tuple.to_list()
    |> Enum.map(&Integer.to_string(&1, 16))
    |> Enum.join(":")
  end

  def to_string(ip) do
    if ip <= 4_294_967_295 do
      1..4
      |> Enum.reduce({ip, []}, &ip_reduce_ipv4/2)
      |> elem(1)
      |> Enum.join(".")
    else
      1..8
      |> Enum.reduce({ip, []}, &ip_reduce_ipv6/2)
      |> elem(1)
      |> Enum.join(":")
    end
  end

  defp ip_reduce_ipv4(_, {ip, acc}) do
    {
      :erlang.bsr(ip, 8),
      [:erlang.band(ip, 255) | acc]
    }
  end

  defp ip_reduce_ipv6(_, {ip, acc}) do
    {
      :erlang.bsr(ip, 16),
      [Integer.to_string(:erlang.band(ip, 65_535), 16) | acc]
    }
  end

  ### Whitelisting ###

  @doc ~S"""
  Generate an IP whitelist.


  ## Examples

  ```elixir
  iex> Cider.whitelist("192.168.0.1-3, 192.168.1.0/32")
  {:ok, [{3232235776, 4294967295}, 3232235521..3232235523]}
  ```
  """
  @spec whitelist(String.t() | [String.t() | t]) :: {:ok, [t]} | {:error, atom}
  def whitelist(whitelist) when is_binary(whitelist) do
    whitelist
    |> String.split(~r/(,| )\ */, trim: true)
    |> do_whitelist()
  end

  def whitelist(ips) when is_list(ips), do: do_whitelist(ips)
  def whitelist(_), do: {:error, :invalid_whitelist}

  @spec do_whitelist([String.t() | t]) :: {:ok, [t]} | {:error, atom}
  defp do_whitelist(ips, acc \\ [])
  defp do_whitelist([], acc), do: {:ok, acc}
  defp do_whitelist([ip = {_, _} | ips], acc), do: do_whitelist(ips, [ip | acc])
  defp do_whitelist([ip = _.._ | ips], acc), do: do_whitelist(ips, [ip | acc])

  defp do_whitelist([ip | ips], acc) do
    do_whitelist(ips, [parse(ip) | acc])
  rescue
    _ -> {:error, :invalid_whitelist_cidr}
  end

  @doc ~S"""
  Check whether a given IP is whitelisted.

  An empty whitelist will always return `false`.

  ## Examples

  ```elixir
  iex> Cider.whitelisted?("192.168.0.2", "192.168.0.1-3, 192.168.1.0/24")
  true
  iex> Cider.whitelisted?("192.168.1.2", "192.168.0.1-3, 192.168.1.0/24")
  true
  iex> Cider.whitelisted?("192.168.2.2", "192.168.0.1-3, 192.168.1.0/24")
  false
  ```
  """
  @spec whitelisted?(String.t() | ip | raw_ip, String.t() | [t]) :: boolean
  def whitelisted?(ip, whitelist) when is_binary(whitelist) do
    case whitelist(whitelist) do
      {:ok, wl} -> whitelisted?(ip, wl)
      _ -> false
    end
  end

  def whitelisted?(ip, whitelist) when is_integer(ip),
    do: Enum.find_value(whitelist, false, &Cider.contains?(ip, &1))

  def whitelisted?(ip, whitelist), do: ip |> ip! |> whitelisted?(whitelist)
end
