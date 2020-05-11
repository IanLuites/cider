# cider

[![Hex.pm](https://img.shields.io/hexpm/v/cider.svg "Hex")](https://hex.pm/packages/cider)
[![Build Status](https://travis-ci.org/IanLuites/cider.svg?branch=master)](https://travis-ci.org/IanLuites/cider)
[![Coverage Status](https://coveralls.io/repos/github/IanLuites/cider/badge.svg?branch=master)](https://coveralls.io/github/IanLuites/cider?branch=master)
[![Inline docs](http://inch-ci.org/github/IanLuites/cider.svg?branch=master)](http://inch-ci.org/github/IanLuites/cider)
[![Deps Status](https://beta.hexfaktor.org/badge/all/github/IanLuites/cider.svg)](https://beta.hexfaktor.org/github/IanLuites/cider)
[![Hex.pm](https://img.shields.io/hexpm/l/cider.svg "License")](LICENSE)

CIDR library for Elixer.

## Quick Start

```elixir
{:ok, whitelist} = Cider.whitelist("192.168.0.1-3, 192.168.2.0/24, ::1")
Cider.whitelisted?("192.168.0.2", whitelist) # true
```

```elixir
Cider.optimize!("192.168.0.0/31, 192.168.0.2-3")  |> Cider.to_string
"192.168.0.0/30"```

```elixir
Cider.optimize("192.168.0.0/31, 192.168.0.2-4") |> Cider.to_string
"192.168.0.0-4"```

```elixir
Cider.optimize("192.168.0.0-5, 192.168.0.2-3, 192.168.0.4-255") |> Cider.to_string
"192.168.0.0/24"```

```elixir
Cider.optimize("192.168.0.0-5, 192.168.0.2-3, 192.168.0.4-127") |> Cider.to_string
"192.168.0.0/25"```

## Installation

The package can be installed
by adding `cider` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:cider, "~> 0.3.0"}]
end
```

## Changelog

### v0.3.3 (2020-05-10)

- Add function to add CIDR or range to whitelist. (`Cider.whitelist/2`)
- Add function to remove CIDR or range from whitelist. (`Cider.blacklist/2`)

### v0.3.1 (2019-05-10)

- Add function to optimize whitelists. (`Cider.optimize/1`)
- Add ability to `to_string` to print whitelists.

### v0.3.0 (2019-05-09)

- Add ability to define ranges: `192.168.0.1-43`.
- Add function to create whitelist: `Cider.whitelist/1`.
- Add function to match IP to whitelist: `Cider.whitelisted?/2`.
