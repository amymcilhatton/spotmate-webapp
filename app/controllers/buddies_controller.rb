class BuddiesController < ApplicationController
  def index
    @buddies = current_user.accepted_buddies
    @buddy = @buddies.first
    load_shared_feed
    load_feed if @buddy.present?
  end

  def show
    @buddies = current_user.accepted_buddies
    @buddy = @buddies.find { |buddy| buddy.id == params[:id].to_i }
    redirect_to buddies_path, alert: "Buddy not found." and return if @buddy.nil?

    load_shared_feed
    load_feed
  end

  private

  def load_feed
    @logs = @buddy.workout_logs
                  .shared_with_buddies
                  .includes(workout_reactions: :user)
                  .order(shared_at: :desc, date: :desc)
  end

  def load_shared_feed
    @my_shared_workouts = current_user.workout_logs
                                     .shared_with_buddies
                                     .includes(workout_reactions: :user)
                                     .order(date: :desc)
                                     .limit(10)

    buddy_ids = current_user.buddies.select(:id)
    @buddy_shared_workouts = WorkoutLog
                             .includes(:user, workout_reactions: :user)
                             .where(user_id: buddy_ids)
                             .shared_with_buddies
                             .order(date: :desc)
                             .limit(20)
  end
end
