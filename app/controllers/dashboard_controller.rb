class DashboardController < ApplicationController
  def index
    @profile = current_user.profile
    matches = current_user.matches.includes(:user_a, :user_b)
    @accepted_matches = matches.select(&:status_accepted?)
    @has_buddies = current_user.buddies.exists?

    @upcoming_bookings = Booking
                         .joins(:match)
                         .where("matches.user_a_id = :id OR matches.user_b_id = :id", id: current_user.id)
                         .where("start_at >= ?", Time.current)
                         .order(:start_at)
                         .limit(3)
    @today_booking = @upcoming_bookings.find { |booking| booking.start_at.to_date == Date.current }
    @next_booking = @today_booking || @upcoming_bookings.first

    week_start = Time.current
    week_end = 7.days.from_now
    @bookings_this_week = Booking
                          .joins(:match)
                          .where("matches.user_a_id = :id OR matches.user_b_id = :id", id: current_user.id)
                          .where(start_at: week_start..week_end)
    @sessions_booked_count = @bookings_this_week.count
    @sessions_completed_count = Booking.where(status: 1).where(id: @bookings_this_week.select(:id)).count
    @prs_this_week_count = current_user.prs.where("date >= ?", 7.days.ago.to_date).count

    @recent_log = current_user.workout_logs.order(date: :desc).first
    @recent_pr = current_user.prs.where("date >= ?", 7.days.ago.to_date).order(date: :desc).first

    @profile_ready = profile_ready?(@profile)
    @availability_ready = current_user.availability_slots.any?
    @suggested_buddy = top_suggestion(matches)
    @matches_ready = @accepted_matches.any? || @suggested_buddy.present?
    @hero_subtitle = hero_subtitle
    load_buddy_activity
  end

  private

  def profile_ready?(profile)
    profile.present? && profile.age.present? && profile.gender.present? && profile.experience_band.present?
  end

  def hero_subtitle
    if @accepted_matches.any? && @sessions_booked_count.positive?
      "You have #{@sessions_booked_count} sessions booked with buddies this week."
    elsif @profile_ready && @availability_ready
      if @has_buddies
        "You're all set to train with your buddies."
      else
        "You're ready to find your first training partner."
      end
    else
      "Finish setting up your profile to start getting matches."
    end
  end

  def top_suggestion(matches)
    matched_user_ids = matches.flat_map { |match| [match.user_a_id, match.user_b_id] }.uniq
    skipped_user_ids = Array(session[:skipped_user_ids])
    candidates = User.where.not(id: matched_user_ids + skipped_user_ids + [current_user.id])
                     .includes(:profile, :availability_slots)
    Matching::MatchCalculator.new(current_user).suggestions(candidates).first
  end

  def load_buddy_activity
    buddy_ids = current_user.buddies.select(:id)
    shared_workouts = WorkoutLog
                      .shared_with_buddies
                      .where(user_id: buddy_ids)
                      .includes(:user)
                      .order(shared_at: :desc, date: :desc)
                      .limit(10)

    kudos_received = WorkoutKudo
                     .joins(:workout_log)
                     .where(workout_logs: { user_id: current_user.id })
                     .includes(:giver, :workout_log)
                     .order(created_at: :desc)
                     .limit(10)

    latest_shared_by_user = {}
    shared_workouts.each do |log|
      latest_shared_by_user[log.user_id] ||= log
    end

    activity = []
    shared_workouts.each do |log|
      activity << {
        type: :shared_workout,
        log: log,
        actor: log.user,
        at: log.shared_at || log.created_at
      }
    end
    kudos_received.each do |kudo|
      activity << {
        type: :kudos,
        log: kudo.workout_log,
        actor: kudo.giver,
        at: kudo.created_at,
        kudos_back_log: latest_shared_by_user[kudo.giver_id]
      }
    end

    @buddy_activity = activity.sort_by { |item| item[:at] || Time.at(0) }.reverse.first(6)
  end
end
