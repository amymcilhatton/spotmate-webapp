module AvailabilitySlotsHelper
  DAY_ORDER = [
    ["Mon", 1],
    ["Tue", 2],
    ["Wed", 3],
    ["Thu", 4],
    ["Fri", 5],
    ["Sat", 6],
    ["Sun", 0]
  ].freeze

  TIME_WINDOWS = {
    "morning" => [7 * 60, 9 * 60],
    "lunchtime" => [12 * 60, 13 * 60],
    "afternoon" => [15 * 60, 17 * 60],
    "evening" => [18 * 60, 20 * 60],
    "late_night" => [20 * 60 + 30, 22 * 60]
  }.freeze

  def day_label(dow)
    DAY_ORDER.find { |_label, value| value == dow }&.first || "Day #{dow}"
  end

  def time_label(minutes)
    return "" if minutes.nil?

    hour = minutes / 60
    min = minutes % 60
    format("%02d:%02d", hour, min)
  end

  def time_field_value(minutes)
    return "" if minutes.nil?

    hour = minutes / 60
    min = minutes % 60
    format("%02d:%02d", hour, min)
  end

  def duration_label(start_min, end_min)
    return "" if start_min.nil? || end_min.nil?

    minutes = end_min - start_min
    return "" if minutes <= 0

    hours = minutes / 60.0
    hours_label = hours % 1 == 0 ? hours.to_i : hours.round(1)
    "#{hours_label}h"
  end

  def time_of_day_label(start_min)
    return "" if start_min.nil?

    case start_min
    when 300..599 then "Morning"
    when 600..839 then "Lunchtime"
    when 840..1019 then "Afternoon"
    when 1020..1259 then "Evening"
    else "Late night"
    end
  end
end
