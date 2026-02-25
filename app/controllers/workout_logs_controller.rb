class WorkoutLogsController < ApplicationController
  def index
    @workout_logs = current_user.workout_logs.order(date: :desc)
    @latest_prs = current_user.prs
                                .select("DISTINCT ON (exercise) *")
                                .order("exercise, date DESC")
  end

  def new
    @workout_log = current_user.workout_logs.new
  end

  def create
    @workout_log = current_user.workout_logs.new(workout_log_params)
    if @workout_log.save
      redirect_to workout_logs_path, notice: "Workout logged."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def workout_log_params
    permitted = params.require(:workout_log).permit(:date, :kind, :payload_json, :title, :exercises,
                                                    :shared_with_buddies, :contains_pr)
    if permitted[:payload_json].is_a?(String) && permitted[:payload_json].present?
      permitted[:payload_json] = JSON.parse(permitted[:payload_json])
    end
    if permitted[:exercises].is_a?(String) && permitted[:exercises].present?
      permitted[:exercises] = permitted[:exercises].split(",").map(&:strip).reject(&:blank?)
    end
    permitted
  rescue JSON::ParserError
    permitted[:payload_json] = {}
    permitted
  end
end
