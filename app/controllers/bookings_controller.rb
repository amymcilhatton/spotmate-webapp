class BookingsController < ApplicationController
  def index
    @bookings = Booking
                .joins(:match)
                .where("matches.user_a_id = :id OR matches.user_b_id = :id", id: current_user.id)
                .order(start_at: :asc)

    @upcoming_bookings = @bookings.select { |booking| booking.start_at && booking.start_at >= Time.current }
    @past_bookings = @bookings.select { |booking| booking.end_at && booking.end_at < Time.current }
    @next_booking = @upcoming_bookings.first
    @this_week_booking = @upcoming_bookings.find { |booking| booking.start_at <= 7.days.from_now }

    @calendar_days = (Date.current..(Date.current + 6.days)).to_a
    @bookings_by_day = @upcoming_bookings.group_by { |booking| booking.start_at.to_date }
    @streak_count = streak_count(current_user)
  end

  def show
    @booking = Booking
               .joins(:match)
               .where("matches.user_a_id = :id OR matches.user_b_id = :id", id: current_user.id)
               .find(params[:id])

    respond_to do |format|
      format.html
      format.ics do
        calendar = Icalendar::Calendar.new
        calendar.event do |event|
          event.summary = "SpotMate workout"
          event.dtstart = @booking.start_at
          event.dtend = @booking.end_at
        end
        calendar.publish
        render plain: calendar.to_ical, content_type: "text/calendar"
      end
    end
  end

  def new
    @booking = Booking.new
    @matches = current_user.matches
    @suggestions_by_match = suggestions_by_match(@matches)
  end

  def create
    match_id = params[:match_id] || params.dig(:booking, :match_id)
    unless match_id.present?
      redirect_to bookings_path, alert: "Select a match first."
      return
    end
    match = current_user.matches.find(match_id)
    @booking = match.bookings.new(booking_params)
    if @booking.save
      redirect_to bookings_path, notice: "Booking created."
    else
      @matches = current_user.matches
      @suggestions_by_match = suggestions_by_match(@matches)
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    booking = Booking
              .joins(:match)
              .where("matches.user_a_id = :id OR matches.user_b_id = :id", id: current_user.id)
              .find(params[:id])
    booking.destroy
    redirect_to bookings_path, notice: "Booking cancelled."
  end

  private

  def booking_params
    params.require(:booking).permit(:start_at, :end_at, :status, :reminder_enabled, :reminder_minutes_before)
  end

  def suggestions_by_match(matches)
    calculator = Matching::MatchCalculator.new(current_user)
    matches.each_with_object({}) do |match, memo|
      memo[match.id] = calculator.overlap_windows_for(match.other_user(current_user))
    end
  end

  def streak_count(user)
    dates = user.workout_logs.where.not(date: nil).order(date: :desc).pluck(:date).uniq
    return 0 if dates.empty?

    streak = 1
    dates.each_cons(2) do |current, previous|
      break unless current - previous == 1

      streak += 1
    end
    streak
  end
end
