class MatchesController < ApplicationController
  def index
    @matches = current_user.matches.includes(:user_a, :user_b, :match_decisions)
    matched_user_ids = @matches.flat_map { |match| [match.user_a_id, match.user_b_id] }.uniq
    @accepted_matches = @matches.select(&:status_accepted?)
    @upcoming_by_match = upcoming_bookings_for(@accepted_matches)
    skipped_user_ids = Array(session[:skipped_user_ids])

    @suggestions = Matching::MatchCalculator
                   .new(current_user)
                   .suggestions(
                     User.where.not(id: matched_user_ids + skipped_user_ids + [current_user.id])
                         .includes(:profile, :availability_slots)
                   )
  end

  def create
    candidate = User.find(params[:user_id])
    match = Match.find_or_initialize_by(user_a: current_user, user_b: candidate)
    match.status ||= params[:status].presence || :pending
    match.score = params[:score]
    if match.save
      if match.status_declined?
        MatchDecision.create!(match: match, user: current_user, decision: :declined)
        redirect_to matches_path, notice: "Skipped for now."
      else
        redirect_to matches_path, notice: "Match saved. Waiting for confirmation."
      end
    else
      redirect_to matches_path, alert: "Could not save match."
    end
  end

  def skip
    candidate_id = params[:user_id].to_i
    session[:skipped_user_ids] ||= []
    session[:skipped_user_ids] = (session[:skipped_user_ids] + [candidate_id]).uniq
    redirect_to matches_path, notice: "Noted. We'll show other suggestions."
  end

  def update
    match = current_user.matches.find(params[:id])
    if match.update(status: params[:status])
      if %w[accepted declined].include?(params[:status])
        MatchDecision.create!(match: match, user: current_user, decision: params[:status])
      end
      redirect_to matches_path, notice: "Match updated."
    else
      redirect_to matches_path, alert: "Could not update match."
    end
  end

  def rematch
    match = current_user.matches.find(params[:id])
    MatchDecision.create!(match: match, user: current_user, decision: :rematch)
    match.destroy
    redirect_to matches_path, notice: "Match removed. We'll find new suggestions."
  end

  def chat
    @match = current_user.matches.find(params[:id])
  end

  def kudos
    match = current_user.matches.find(params[:id])
    redirect_to chat_match_path(match), notice: "Kudos sent. Nice work."
  end

  private

  def upcoming_bookings_for(matches)
    match_ids = matches.map(&:id)
    return {} if match_ids.empty?

    Booking.where(match_id: match_ids)
           .where("start_at >= ?", Time.current)
           .order(:start_at)
           .group_by(&:match_id)
           .transform_values(&:first)
  end
end
