module ApplicationHelper
  def human_distance(distance_miles)
    return "Same gym as you" if distance_miles.nil? || distance_miles < 0.1
    return "Less than 1 mile from your gym" if distance_miles < 1

    "About #{distance_miles.round(1)} miles from your gym"
  end

  def workout_highlight_tags(workout_log)
    text = if workout_log.respond_to?(:notes) && workout_log.notes.present?
             workout_log.notes.to_s
           elsif workout_log.respond_to?(:ai_notes) && workout_log.ai_notes.present?
             workout_log.ai_notes.to_s
           else
             ""
           end

    # 1) Structured tags
    if workout_log.respond_to?(:highlight_tags) && workout_log.highlight_tags.present?
      return workout_log.highlight_tags.compact_blank
    end

    # 2) Exercises list
    if workout_log.respond_to?(:exercises) && workout_log.exercises.present?
      tags = workout_log.exercises.map do |ex|
        if ex.respond_to?(:label)
          ex.label
        elsif ex.respond_to?(:name) && ex.respond_to?(:sets) && ex.respond_to?(:reps)
          "#{ex.name} #{ex.sets}x#{ex.reps}"
        elsif ex.respond_to?(:name)
          ex.name
        else
          ex.to_s
        end
      end
      return tags.compact_blank if tags.any?
    end

    # 3) Bullet lines
    bullet_lines = text.lines
                       .map(&:strip)
                       .select { |line| line.start_with?("-", "•") }
                       .map { |line| line.sub(/^[-•]\s*/, "") }
                       .reject(&:blank?)
    tags = bullet_lines.first(3)
    return tags.compact_blank if tags.any?

    # 4) Section headers
    section_headers = text.lines
                          .map(&:strip)
                          .select { |line| line.match?(/(Warm|Main|Accessory|Cool|Key)/i) }
                          .first(3)
    return section_headers.compact_blank if section_headers.any?

    # 5) Last resort: short sentence snippets
    sentences = text.split(/[\.\n]/)
                    .map(&:strip)
                    .reject(&:blank?)
                    .first(3)
    tags = sentences.map { |sentence| sentence.length > 30 ? "#{sentence[0..30]}…" : sentence }
    tags = tags.compact_blank
    tags = ["Workout logged"] if tags.empty?

    tags
  end

  def pr_value_with_unit(pr)
    value = pr_display_value(pr)
    unit = pr_display_unit(pr)
    [value, unit].compact.map(&:to_s).reject(&:blank?).join(" ")
  end

  def pr_delta_display(change, unit)
    return nil if change.nil?

    unit_key = unit.to_s.downcase
    sign = change.positive? ? "+" : "-"
    case unit_key
    when "sec"
      "#{sign}#{format_duration(change.abs)}"
    when "min"
      "#{sign}#{format_number(change.abs)} min"
    else
      "#{sign}#{format_number(change.abs)} #{unit}"
    end
  end

  def endurance_change_label(change, unit)
    return nil if change.nil?

    faster = change.negative?
    amount = endurance_delta_display(change.abs, unit)
    suffix = faster ? "quicker" : "slower"
    "#{amount} #{suffix}"
  end

  def endurance_change_class(change)
    return nil if change.nil?

    change.negative? ? "pos" : "neg"
  end

  def endurance_badge_class(change)
    return nil if change.nil?

    change.negative? ? "" : "badge-muted"
  end

  def endurance_chart_values(values)
    max = values.max || 1
    min = values.min || 0
    values.map { |val| max - (val - min) }
  end

  def endurance_delta_display(amount, unit)
    unit_key = unit.to_s.downcase
    case unit_key
    when "sec"
      format_duration(amount)
    when "min"
      format_minutes_seconds(amount)
    else
      format_number(amount)
    end
  end

  private

  def pr_display_value(pr)
    unit_key = pr.unit.to_s.downcase
    return format_duration(pr.value) if unit_key == "sec"

    format_number(pr.value)
  end

  def pr_display_unit(pr)
    unit_key = pr.unit.to_s.downcase
    return "" if unit_key == "sec"

    unit_key
  end

  def format_duration(value)
    return "" if value.blank?

    total_seconds = value.to_i
    hours = total_seconds / 3600
    minutes = (total_seconds % 3600) / 60
    seconds = total_seconds % 60
    return format("%d:%02d", minutes, seconds) if hours.zero?

    format("%d:%02d:%02d", hours, minutes, seconds)
  end

  def format_minutes_seconds(minutes_value)
    return "" if minutes_value.blank?

    total_seconds = (minutes_value.to_f * 60).round
    return "#{total_seconds} sec" if total_seconds < 60

    minutes = total_seconds / 60
    seconds = total_seconds % 60
    "#{minutes} min #{seconds} sec"
  end

  def format_number(value)
    return "" if value.blank?

    value % 1 == 0 ? value.to_i : value.round(2)
  end
end
