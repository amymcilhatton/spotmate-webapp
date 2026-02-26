class WorkoutLogsController < ApplicationController
  before_action :set_workout_log, only: %i[edit update destroy]

  def index
    @workout_logs = current_user.workout_logs.order(date: :desc)
    @latest_prs = current_user.prs
                                .select("DISTINCT ON (exercise) *")
                                .order("exercise, date DESC")
  end

  def new
    @workout_log = current_user.workout_logs.new
    @mode = params[:mode]

    if @mode == "ai"
      render :new_ai
    else
      render :new
    end
  end

  def create
    if params[:ai_plan_confirmed].present? && params[:ai_plan_confirmed] != "1"
      redirect_to new_workout_log_path(mode: :ai), alert: "Please click 'Use this plan' before saving."
      return
    end

    @workout_log = current_user.workout_logs.new(workout_log_params)
    if @workout_log.save
      redirect_to workout_logs_path, notice: "Workout saved."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @workout_log.update(workout_log_params)
      redirect_to workout_logs_path, notice: "Workout updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @workout_log.destroy
    redirect_to workout_logs_path, notice: "Workout deleted."
  end

  private

  def workout_log_params
    permitted = params.require(:workout_log).permit(:date, :kind, :payload_json, :title, :exercises,
                                                    :shared_with_buddies, :contains_pr, :notes)
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

  def set_workout_log
    @workout_log = current_user.workout_logs.find(params[:id])
  end
end
