class MatchesController < ApplicationController
  def index
    @profile = current_user.profile
    @matches = current_user.matches.includes(:user_a, :user_b, :match_decisions)
    decided_matches = @matches.reject { |match| match.match_decisions.none? }
    matched_user_ids = decided_matches.flat_map { |match| [match.user_a_id, match.user_b_id] }.uniq
    @accepted_matches = @matches.select(&:status_accepted?)
    pending_matches = @matches.select(&:status_pending?)
    @incoming_requests = pending_matches.select { |match| incoming_request_for?(match) }
    @outgoing_requests = pending_matches.select { |match| outgoing_request_for?(match) }
    suggestion_matches = pending_matches.select { |match| match.match_decisions.none? }
    @upcoming_by_match = upcoming_bookings_for(@accepted_matches)
    skipped_user_ids = Array(session[:skipped_user_ids])

    candidates = User.where.not(id: matched_user_ids + skipped_user_ids + [current_user.id])
                     .includes(:profile, :availability_slots)

    radius = @profile&.match_radius_miles || 50
    if @profile&.gym_latitude.present? && @profile&.gym_longitude.present?
      candidates = candidates.select do |user|
        distance = @profile.distance_to(user.profile)
        distance.nil? || distance <= radius
      end
    end

    calculator = Matching::MatchCalculator.new(current_user)
    @suggestions = calculator.suggestions(candidates)
    if suggestion_matches.any?
      suggestion_by_user_id = suggestion_matches.index_by { |match| match.other_user(current_user).id }
      @suggestions = @suggestions.map do |suggestion|
        match = suggestion_by_user_id[suggestion.user.id]
        next suggestion unless match

        suggestion.score = match.score if match.score.present?
        if match.overlap_windows_json.present?
          suggestion.overlap_windows = match.overlap_windows_json
        end
        suggestion
      end.sort_by { |suggestion| -suggestion.score }
    end
  end

  def create
    candidate = User.find(params[:user_id])
    match = find_or_initialize_match(candidate)
    match.status = :pending unless match.status_accepted?
    match.score = params[:score] if params[:score].present?

    if match.save
      MatchDecision.find_or_create_by!(match: match, user: current_user, decision: :requested)

      if requested_by?(match, match.other_user(current_user))
        match.update!(status: :accepted)
        MatchDecision.create!(match: match, user: current_user, decision: :accepted)
        redirect_to matches_path, notice: "You are now training partners."
      else
        redirect_to matches_path, notice: "Request sent."
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

  def accept
    match = current_user.matches.find(params[:id])
    if incoming_request_for?(match)
      match.update!(status: :accepted)
      MatchDecision.create!(match: match, user: current_user, decision: :accepted)
      redirect_to matches_path, notice: "You are now training partners."
    else
      redirect_to matches_path, alert: "Request not available."
    end
  end

  def decline
    match = current_user.matches.find(params[:id])
    if incoming_request_for?(match)
      match.update!(status: :declined)
      MatchDecision.create!(match: match, user: current_user, decision: :declined)
      redirect_to matches_path, notice: "Request declined."
    else
      redirect_to matches_path, alert: "Request not available."
    end
  end

  def cancel
    match = current_user.matches.find(params[:id])
    if outgoing_request_for?(match)
      match.destroy
      redirect_to matches_path, notice: "Request cancelled."
    else
      redirect_to matches_path, alert: "Request not available."
    end
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

  def find_or_initialize_match(candidate)
    Match.where(user_a: current_user, user_b: candidate)
         .or(Match.where(user_a: candidate, user_b: current_user))
         .first || Match.new(user_a: [current_user, candidate].min_by(&:id),
                             user_b: [current_user, candidate].max_by(&:id))
  end

  def requested_by?(match, user)
    match.match_decisions.any? { |decision| decision.decision_requested? && decision.user_id == user.id }
  end

  def incoming_request_for?(match)
    match.status_pending? &&
      requested_by?(match, match.other_user(current_user)) &&
      !requested_by?(match, current_user)
  end

  def outgoing_request_for?(match)
    match.status_pending? &&
      requested_by?(match, current_user) &&
      !requested_by?(match, match.other_user(current_user))
  end
end
