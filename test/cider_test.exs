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
end
