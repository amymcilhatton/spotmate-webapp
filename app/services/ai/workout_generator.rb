require "json"

module Ai
  class WorkoutGenerator
    class Error < StandardError; end

    DEFAULT_MODEL = "claude-sonnet-4-6"
    MAX_RECENT_LOGS = 8
    PROMPT_TEMPLATE = <<~PROMPT
      You are a friendly strength & conditioning coach writing workouts for a recreational lifter.

      Using the information below, write a single workout for TODAY:

      - Goal / focus: %{goal}
      - Time available: %{time_available}
      - Equipment available: %{equipment}
      - Recent training and workout logs (if any): %{recent_workouts}

      Requirements:
      - Tone: warm, encouraging, and conversational, like a coach texting a client.
      - Start with 1–2 sentences summarizing what today's session will feel like.
      - Then break the workout into clear sections with simple headings:
        - "Warm-up"
        - "Main lifts"
        - "Accessory work"
        - "Cool-down"
        - "Key notes" (if helpful)
      - Use plain headings like "Warm-up (8–10 min)" and bullet points underneath.
      - Use full sentences where it helps clarity (e.g. "Rest 2–3 minutes between sets.").
      - Avoid heavy markdown decoration: no `##` or `###` heading syntax, and no `**bold**` markup.
      - Keep the workout realistic for the time available.
      - Where loads/intensity matter, describe them in human terms (e.g. "a challenging weight you could lift 5–6 times", "RPE 7–8") instead of percentages only.
      - Finish with 2–3 short "Key notes" bullets with reminders about recovery, form, or how to adjust if feeling tired.
      - Aim for a single screen: roughly 10–15 bullet items total, skimmable and not over-explained.

      Format the output as simple text with headings and bullet points, not as JSON or code.
    PROMPT

    def self.call(user:, goal: nil, time_available: nil, equipment: nil, model: DEFAULT_MODEL)
      new(user: user, goal: goal, time_available: time_available, equipment: equipment, model: model).call
    end

    def initialize(user:, goal: nil, time_available: nil, equipment: nil, model: DEFAULT_MODEL)
      @user = user
      @goal = goal
      @time_available = time_available
      @equipment = equipment
      @model = model
    end

    def call
      api_key = Rails.application.credentials.dig(:anthropic, :api_key)
      raise Error, "Missing Anthropic API key" if api_key.blank?

      # External API call to Anthropic for a single workout plan.
      response = ANTHROPIC_CLIENT.messages.create(
        model: @model,
        max_tokens: 800,
        messages: [
          { role: "user", content: prompt }
        ]
      )
      ai_output = response.content[0].text
      raise Error, "AI returned an empty response" if ai_output.blank?

      clean_output(ai_output)
    rescue Anthropic::Errors::Error => e
      raise Error, "AI response error: #{e.message}"
    rescue StandardError => e
      raise Error, "AI response error: #{e.message}"
    end

    private

    def prompt
      profile = @user.profile
      goals = Array(profile&.goals).presence || []
      experience = profile&.experience_band.presence || "unknown"
      recent_workouts = recent_workout_payload

      # Build the prompt from goals, equipment, and recent history.
      PROMPT_TEMPLATE % {
        goal: presence_or(@goal, goals.join(", ").presence || "none provided"),
        time_available: presence_or(@time_available, "not provided"),
        equipment: presence_or(@equipment, "not provided"),
        recent_workouts: "Experience level: #{experience}\n#{JSON.pretty_generate(recent_workouts)}"
      }
    end

    def recent_workout_payload
      @user.workout_logs.order(date: :desc).limit(MAX_RECENT_LOGS).map do |log|
        payload = log.payload_json.is_a?(Hash) ? log.payload_json : {}
        exercises = payload["exercises"] || log.exercises
        {
          date: log.date&.to_s,
          kind: log.kind,
          title: log.title,
          exercises: Array(exercises)
        }
      end
    end

    def clean_output(text)
      # Parse the model response into plain displayable text.
      text.to_s
          .gsub(/^\s*##?\s?/, "")
          .gsub(/\*\*(.*?)\*\*/, '\1')
          .gsub(/^-{3,}\s*$/, "")
          .gsub(/\n{3,}/, "\n\n")
          .strip
    end

    def presence_or(value, fallback)
      value.to_s.strip.presence || fallback
    end
  end
end
