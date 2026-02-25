class PrsController < ApplicationController
  def index
    @prs = current_user.prs.order(date: :desc)
  end

  def new
    @pr = current_user.prs.new
    load_suggestions
  end

  def create
    @pr = current_user.prs.new(pr_params)
    if @pr.save
      redirect_to prs_path, notice: "PR saved."
    else
      load_suggestions
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    pr = current_user.prs.find(params[:id])
    pr.destroy
    redirect_to prs_path, notice: "PR deleted."
  end

  private

  def pr_params
    params.require(:pr).permit(:exercise, :value, :unit, :date)
  end

  def load_suggestions
    presets_strength = ["Bench", "Squat", "Deadlift", "Overhead press", "Hip thrust", "Weighted pull-up"]
    presets_endurance = ["1 mile", "1 km", "5k", "10k", "Row 2k", "Cycle 10k"]

    strength_units = %w[kg lb reps]
    endurance_units = %w[sec]

    strength_names = current_user.prs.where(unit: strength_units).pluck(:exercise)
    endurance_names = current_user.prs
                                 .where(unit: endurance_units)
                                 .or(current_user.prs.where("lower(exercise) SIMILAR TO ?", "%(run|row|bike|cycle|swim|5k|10k|mile|km)%"))
                                 .pluck(:exercise)

    @strength_suggestions = (strength_names + presets_strength).map(&:to_s).map(&:strip).reject(&:blank?).uniq.first(10)
    @endurance_suggestions = (endurance_names + presets_endurance).map(&:to_s).map(&:strip).reject(&:blank?).uniq.first(10)
  end
end
