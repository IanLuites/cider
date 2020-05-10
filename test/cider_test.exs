defmodule CiderTest do
  use ExUnit.Case
  doctest Cider

  describe "parse" do
    test "from string with subnetmask" do
      assert Cider.parse("192.168.0.0/24") == {3_232_235_520, 4_294_967_040}
    end

    test "from string without subnetmask" do
      assert Cider.parse("192.168.0.1") == {3_232_235_521, 4_294_967_295}
    end

    test "from string with range" do
      assert Cider.parse("192.168.0.1-23") == 3_232_235_521..3_232_235_543
    end

    test "from string with range (ipv6)" do
      assert Cider.parse("2001:0db8:85a3:0000:0000:8a2e:0370:7334-8000") ==
               42_540_766_452_641_154_071_740_215_577_757_643_572..42_540_766_452_641_154_071_740_215_577_757_622_080
    end

    test "from arguments with subnetmask" do
      assert Cider.parse(192, 168, 0, 0, 24) == {3_232_235_520, 4_294_967_040}
    end

    test "from arguments without subnetmask" do
      assert Cider.parse(192, 168, 0, 1) == {3_232_235_521, 4_294_967_295}
    end

    test "from ip and subnetmask" do
      assert Cider.parse({192, 168, 0, 0}, 24) == {3_232_235_520, 4_294_967_040}
    end

    test "from ip and subnetmask with non %8 bit mask" do
      assert Cider.parse({192, 168, 0, 0}, 3) == {3_221_225_472, 3_758_096_384}
    end
  end

  describe "contains?" do
    test "with non %8 bit mask" do
      cidr = Cider.parse({192, 168, 0, 0}, 30)

      assert Cider.contains?({192, 168, 0, 2}, cidr)
      refute Cider.contains?({192, 168, 0, 4}, cidr)
    end

    test "with full 32 bit mask" do
      cidr = Cider.parse({192, 168, 0, 5}, 32)

      assert Cider.contains?({192, 168, 0, 5}, cidr)
      refute Cider.contains?({192, 168, 0, 4}, cidr)
    end

    test "with full range bit mask" do
      cidr = Cider.parse("192.168.0.3-12")

      refute Cider.contains?({192, 168, 0, 2}, cidr)

      Enum.each(3..12, fn last ->
        assert Cider.contains?({192, 168, 0, last}, cidr)
      end)

      refute Cider.contains?({192, 168, 0, 13}, cidr)
    end

    @tag :cider_full
    test "correct for whole ip range" do
      cidr = Cider.parse("192.168.0.0/24")

      for octet1 <- 191..193,
          do:
            for(
              octet2 <- 0..255,
              do:
                for(
                  octet3 <- 0..255,
                  do:
                    for(
                      octet4 <- 0..255,
                      do:
                        assert(
                          Cider.contains?({octet1, octet2, octet3, octet4}, cidr) ==
                            (octet1 == 192 && octet2 == 168 && octet3 == 0)
                        )
                    )
                )
            )
    end
  end

  describe "whitelist/1" do
    test "from single string" do
      assert Cider.whitelist("192.168.0.1-32, 192.168.1.0/24     ::1") ==
               {:ok,
                [
                  {1, 340_282_366_920_938_463_463_374_607_431_768_211_455},
                  {3_232_235_776, 4_294_967_040},
                  3_232_235_521..3_232_235_552
                ]}
    end

    test "from mixed list" do
      assert Cider.whitelist([Cider.parse("192.168.0.1-32"), Cider.parse("192.168.1.0/24"), "::1"]) ==
               {:ok,
                [
                  {1, 340_282_366_920_938_463_463_374_607_431_768_211_455},
                  {3_232_235_776, 4_294_967_040},
                  3_232_235_521..3_232_235_552
                ]}
    end
  end

  describe "whitelisted?/2" do
    setup do
      {:ok, whitelist} = Cider.whitelist("192.168.0.1-32, 192.168.1.0/24")
      [whitelist: whitelist]
    end

    test "based on string IP", %{whitelist: whitelist} do
      assert Cider.whitelisted?("192.168.0.23", whitelist)
      assert Cider.whitelisted?("192.168.1.23", whitelist)
      refute Cider.whitelisted?("192.168.2.23", whitelist)
    end

    test "based on tuple IP", %{whitelist: whitelist} do
      assert Cider.whitelisted?({192, 168, 0, 23}, whitelist)
      assert Cider.whitelisted?({192, 168, 1, 23}, whitelist)
      refute Cider.whitelisted?({192, 168, 2, 23}, whitelist)
    end

    test "based on integer IP", %{whitelist: whitelist} do
      assert Cider.whitelisted?(3_232_235_543, whitelist)
      assert Cider.whitelisted?(3_232_235_799, whitelist)
      refute Cider.whitelisted?(3_232_236_055, whitelist)
    end
  end

  defp optimize(value), do: value |> Cider.optimize!() |> Cider.to_string()

  describe "optimize/1" do
    test "sorts based on range, largest first" do
      assert optimize("192.168.0.1,192.168.1.0/24,192.168.2.3-6") ==
               "192.168.1.0/24, 192.168.2.3/30, 192.168.0.1/32"

      assert optimize("192.168.0.1-5,192.168.0.21-41, 192.168.0.11-16") ==
               "192.168.0.21-41, 192.168.0.11-16, 192.168.0.1-5"

      assert optimize("192.168.2.0/31, 192.168.0.0/28, 192.168.1.0/30") ==
               "192.168.0.0/28, 192.168.1.0/30, 192.168.2.0/31"

      assert optimize("192.168.2.0/31, ::ffff:ffff:ffff/128, 192.168.1.0/30") ==
               "192.168.1.0/30, 192.168.2.0/31, 0:0:0:0:0:FFFF:FFFF:FFFF/128"

      assert optimize("192.168.2.0-5, ::ffff:ffff:ffff/100, 192.168.1.0/30") ==
               "0:0:0:0:0:FFFF:F000:0/100, 192.168.2.0-5, 192.168.1.0/30"
    end
  end

  describe "optimize!/1" do
    test "raise on failure" do
      assert_raise RuntimeError, fn -> optimize(":1") end
    end
  end

  describe "blacklist" do
    defp blacklist(whitelist, cidr) do
      assert new = Cider.blacklist(whitelist, cidr)
      Cider.to_string(new)
    end

    test "range - range" do
      # Disjoint
      assert blacklist("192.168.0.9-21", "192.168.0.25-35") == "192.168.0.9-21"

      # Inside
      assert blacklist("192.168.0.9-21", "192.168.0.14-18") == "192.168.0.9-13, 192.168.0.19-21"

      # Outside
      assert blacklist("192.168.0.9-21", "192.168.0.9-22") == ""

      # Lower
      assert blacklist("192.168.0.9-21", "192.168.0.5-15") == "192.168.0.16-21"

      # Higher
      assert blacklist("192.168.0.9-20", "192.168.0.15-25") == "192.168.0.9-14"

      # Sneakies
      assert blacklist("192.168.0.9-21", "192.168.0.5-20") == "192.168.0.21/32"
      assert blacklist("192.168.0.9-20", "192.168.0.10-25") == "192.168.0.9/32"
      assert blacklist("192.168.0.9-20", "192.168.0.10-19") == "192.168.0.9/32, 192.168.0.20/32"
    end

    test "cidr - cidr" do
      # Disjoint
      assert blacklist("10.0.0.0/16", "10.1.0.0/16") == "10.0.0.0/16"
      assert blacklist("10.0.0.0/16", "10.1.0.0/24") == "10.0.0.0/16"
      assert blacklist("10.0.0.0/24", "10.1.0.0/16") == "10.0.0.0/24"

      # Outside
      assert blacklist("192.168.1.0/24", "192.168.0.0/16") == ""

      # Inside
      assert blacklist("192.168.0.0/16", "192.168.0.0/24") ==
               "192.168.128.0/17, 192.168.64.0/18, 192.168.32.0/19, 192.168.16.0/20, 192.168.8.0/21, 192.168.4.0/22, 192.168.2.0/23, 192.168.1.0/24"

      assert blacklist("192.168.0.0/16", "192.168.1.0/24") ==
               "192.168.128.0/17, 192.168.64.0/18, 192.168.32.0/19, 192.168.16.0/20, 192.168.8.0/21, 192.168.4.0/22, 192.168.2.0/23, 192.168.0.0/24"
    end

    test "range - cidr" do
      assert blacklist("192.168.0.9-21", "192.168.0.14/31") == "192.168.0.16-21, 192.168.0.9-13"
    end

    test "cidr - range" do
      assert blacklist("192.168.0.0/24", "192.168.0.5-32") ==
               "192.168.0.128/25, 192.168.0.64/26, 192.168.0.32/27, 192.168.0.0-4"
    end
  end
end
