class WorkoutCommentsController < ApplicationController
  def create
    workout_log = WorkoutLog.find(params[:workout_log_id])
    return head :forbidden unless can_access_log?(workout_log)

    @comment = workout_log.workout_comments.new(author: current_user, body: params[:body])
    if @comment.save
      respond_to do |format|
        format.html { redirect_back fallback_location: buddies_path, notice: "Comment added." }
        format.turbo_stream
      end
    else
      redirect_back fallback_location: buddies_path, alert: "Could not add comment."
    end
  end

  private

  def can_access_log?(workout_log)
    return true if workout_log.user_id == current_user.id
    current_user.accepted_buddies.where(id: workout_log.user_id).exists? && workout_log.shared_with_buddies?
  end
end
