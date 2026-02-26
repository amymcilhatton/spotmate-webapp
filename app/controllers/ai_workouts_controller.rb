class AiWorkoutsController < ApplicationController
  def preview
    plan_text = Ai::WorkoutGenerator.call(
      user: current_user,
      goal: params[:goal],
      time_available: params[:time_available],
      equipment: params[:equipment]
    )

    render partial: "ai_workouts/preview",
           locals: { plan_text: plan_text },
           layout: false
  rescue Anthropic::Errors::Error => e
    Rails.logger.error("Anthropic error: #{e.message}")
    @error_message = "AI workout generation is temporarily unavailable."
    render partial: "ai_workouts/error",
           locals: { error_message: @error_message },
           status: :unprocessable_entity,
           layout: false
  end
end
