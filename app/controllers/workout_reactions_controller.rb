class WorkoutReactionsController < ApplicationController
  def create
    workout_log = WorkoutLog.find(params[:workout_log_id])
    return head :forbidden unless can_access_log?(workout_log)

    if reaction_params[:kind] == "kudos"
      workout_log.workout_reactions.find_or_create_by!(user: current_user, kind: "kudos")
      redirect_back fallback_location: buddies_path, notice: "Kudos sent."
    else
      @reaction = workout_log.workout_reactions.new(
        user: current_user,
        kind: "comment",
        body: reaction_params[:body]
      )

      if @reaction.save
        redirect_back fallback_location: buddies_path, notice: "Comment added."
      else
        redirect_back fallback_location: buddies_path, alert: "Could not add comment."
      end
    end
  end

  def destroy
    workout_log = WorkoutLog.find(params[:workout_log_id])
    return head :forbidden unless can_access_log?(workout_log)

    reaction = workout_log.workout_reactions.find_by!(id: params[:id], user: current_user)
    reaction.destroy

    redirect_back fallback_location: buddies_path, notice: "Reaction removed."
  end

  private

  def reaction_params
    params.require(:workout_reaction).permit(:kind, :body)
  end

  def can_access_log?(workout_log)
    return true if workout_log.user_id == current_user.id

    current_user.accepted_buddies.where(id: workout_log.user_id).exists? &&
      workout_log.shared_with_buddies?
  end
end
