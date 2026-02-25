class WorkoutKudosController < ApplicationController
  def create
    workout_log = WorkoutLog.find(params[:workout_log_id])
    return head :forbidden unless can_access_log?(workout_log)

    workout_log.workout_kudos.find_or_create_by!(giver: current_user)
    respond_to do |format|
      format.html { redirect_back fallback_location: buddies_path, notice: "Kudos sent." }
      format.turbo_stream
    end
  end

  def destroy
    workout_log = WorkoutLog.find(params[:workout_log_id])
    return head :forbidden unless can_access_log?(workout_log)

    workout_log.workout_kudos.where(giver: current_user).destroy_all
    respond_to do |format|
      format.html { redirect_back fallback_location: buddies_path, notice: "Kudos removed." }
      format.turbo_stream { render :create }
    end
  end

  private

  def can_access_log?(workout_log)
    return true if workout_log.user_id == current_user.id
    current_user.accepted_buddies.where(id: workout_log.user_id).exists? && workout_log.shared_with_buddies?
  end
end
