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
end
