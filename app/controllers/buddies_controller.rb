class BuddiesController < ApplicationController
  def index
    @buddies = current_user.accepted_buddies
    @buddy = @buddies.first
    load_feed if @buddy.present?
  end

  def show
    @buddies = current_user.accepted_buddies
    @buddy = @buddies.find { |buddy| buddy.id == params[:id].to_i }
    redirect_to buddies_path, alert: "Buddy not found." and return if @buddy.nil?

    load_feed
  end

  private

  def load_feed
    @logs = @buddy.workout_logs
                  .where(shared_with_buddies: true)
                  .includes(:workout_comments, :workout_kudos)
                  .order(date: :desc)
  end
end
