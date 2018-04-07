defmodule TzPeriodBuilderTest do
  use ExUnit.Case, async: true
  alias Tzdata.PeriodBuilder, as: TzPeriodBuilder

  @source_data_dir "test/tzdata_fixtures/source_data/"
  test "get periods for a zone" do
    {:ok, map} = Tzdata.BasicDataMap.from_files_in_dir(@source_data_dir)
    prds = TzPeriodBuilder.calc_periods(map, "Europe/Copenhagen")
    # First period. Based on Copenhagen 1st zone line
    assert hd(prds) == %{std_off: 0,
       from: %{utc: :min, wall: :min, standard: :min},
       until: %{standard: 59642697600, wall: 59642697600, utc: 59642694580},
       utc_off: 3020, zone_abbr: "LMT"}
    # Second period. Based on Copenhagen 2nd zone line
    assert prds |> Enum.at(1) == %{std_off: 0,
       from: %{standard: 59642697600, wall: 59642697600, utc: 59642694580},
       until: %{standard: 59768928000, wall: 59768928000, utc: 59768924980},
       utc_off: 3020, zone_abbr: "CMT"}
    # Third period. Based on Copenhagen 3rd zone line
    assert prds  |> Enum.at(2) == %{std_off: 0,
       from: %{standard: 59768928580, wall: 59768928580, utc: 59768924980},
       until: %{standard: 60474726000, wall: 60474726000, utc: 60474722400},
       utc_off: 3600, zone_abbr: "CET"}
    # Fourth period. Based on Copenhagen 3rd zone line
    # Summer time 1916
    assert prds |> Enum.at(3) == %{std_off: 3600,
       from: %{standard: 60474726000, wall: 60474729600, utc: 60474722400},
       until: %{standard: 60486732000, wall: 60486735600, utc: 60486728400},
       utc_off: 3600, zone_abbr: "CEST"}
    # Fifth period. Based on Copenhagen 3rd zone line. And rules line 2&3
    # Period without summer time. From Sep 30 1916 to May 15 1940
    assert prds |> Enum.at(4) == %{std_off: 0,
       from: %{standard: 60486732000, wall: 60486732000, utc: 60486728400},
       until: %{standard: 61232112000, wall: 61232112000, utc: 61232108400},
       utc_off: 3600, zone_abbr: "CET"}

    # Sixth period. Summer time from 1940 to 1942!
    assert prds |> Enum.at(5) == %{std_off: 3600,
       from: %{standard: 61232112000, wall: 61232115600, utc: 61232108400},
       until: %{standard: 61309965600, wall: 61309969200, utc: 61309962000},
       utc_off: 3600, zone_abbr: "CEST"}

    # Seventh period. Winter time from 1942 to 1943
    assert prds |> Enum.at(6) == %{std_off: 0,
       from: %{standard: 61309965600, wall: 61309965600, utc: 61309962000},
       until: %{standard: 61322666400, wall: 61322666400, utc: 61322662800},
       utc_off: 3600, zone_abbr: "CET"}

     # Eighteenth period. Wintertime from 1945 to 1980
    assert prds |> Enum.at(18) == %{std_off: 0,
       from: %{standard: 61491924000, wall: 61491924000, utc: 61491920400},
       until: %{standard: 62482752000, wall: 62482752000, utc: 62482748400},
       utc_off: 3600, zone_abbr: "CET"}

     # Twentyfourth period. Summertime in 1982
    assert prds |> Enum.at(24) == %{std_off: 3600,
       from: %{standard: 62553348000, wall: 62553351600, utc: 62553344400},
       until: %{standard: 62569072800, wall: 62569076400, utc: 62569069200},
       utc_off: 3600, zone_abbr: "CEST"}

    prds = TzPeriodBuilder.calc_periods(map, "Europe/Paris")
    assert hd(prds) == %{std_off: 0,
      from: %{utc: :min, wall: :min, standard: :min},
      until: %{standard: 59680540860, wall: 59680540860, utc: 59680540299},
      utc_off: 561, zone_abbr: "LMT"}
  end

  test "get periods for a zone with just one zone line" do
    {:ok, map} = Tzdata.BasicDataMap.from_files_in_dir(@source_data_dir)
    prds = TzPeriodBuilder.calc_periods(map, "Etc/UTC")
    assert hd(prds) == %{std_off: 0, from: %{utc: :min, standard: :min, wall: :min}, until: %{utc: :max, standard: :max, wall: :max}, utc_off: 0, zone_abbr: "UTC"}
    prds = TzPeriodBuilder.calc_periods(map, "Etc/GMT-10")
    assert hd(prds) == %{std_off: 0, from: %{utc: :min, standard: :min, wall: :min}, until: %{utc: :max, standard: :max, wall: :max}, utc_off: 36000, zone_abbr: "GMT-10"}
  end

  test "calculate periods for zone where last line has no rules" do
    {:ok, map} = Tzdata.BasicDataMap.from_files_in_dir(@source_data_dir)
    periods = TzPeriodBuilder.calc_periods(map, "Africa/Abidjan")
    assert length(periods) == 2
  end

  test "calculate periods for zone where last line has rules, but the rules do not continue forever" do
    {:ok, map} = Tzdata.BasicDataMap.from_files_in_dir(@source_data_dir)
    periods = TzPeriodBuilder.calc_periods(map, "Asia/Tokyo")
    assert periods|>Enum.at(11) == %{from: %{standard: 61589206800, utc: 61589174400, wall: 61589206800}, std_off: 0, until: %{standard: :max, utc: :max, wall: :max}, utc_off: 32400, zone_abbr: "JST"}
  end

  test "calculate periods for zone where in a zone line there is a rule which is an amount of time" do
    {:ok, map} = Tzdata.BasicDataMap.from_files_in_dir(@source_data_dir)
    periods = TzPeriodBuilder.calc_periods(map, "Africa/Ceuta")
    assert periods |> Enum.at(5) == %{from: %{standard: 60724767600, utc: 60724767600, wall: 60724771200}, std_off: 3600,
             until: %{standard: 60739542000, utc: 60739542000, wall: 60739545600}, utc_off: 0, zone_abbr: "WEST"}
  end

  test "calculates correct abbreviation when changing from a static offset" do
    {:ok, map} = Tzdata.BasicDataMap.from_files_in_dir(@source_data_dir)
    periods = TzPeriodBuilder.calc_periods(map, "America/Chihuahua")
    # changed from static CST to CST/CDT at the start of 1996
    assert %{zone_abbr: "CST"} = periods |> Enum.at(7)
  end

  test "calculate periods for zone where there are multiple changes within a year" do
    {:ok, map} = Tzdata.BasicDataMap.from_files_in_dir(@source_data_dir)
    periods = TzPeriodBuilder.calc_periods(map, "America/Chihuahua")
    # changed from CST/CDT back to CST at the start of 1998, then to MST/MDT
    # at the end of 1998
    assert %{until: %{utc: 63050853600}} = Enum.at(periods, 11)
    assert %{from: %{utc: 63050853600}} = Enum.at(periods, 12)
  end
end
