class BookingsController < ApplicationController
  def index
    @pending_requests = Booking
                        .where(buddy_id: current_user.id, buddy_status: :pending)
                        .order(start_at: :asc)

    @bookings = Booking
                .where(creator_id: current_user.id)
                .where("buddy_id IS NULL OR buddy_status != ?", Booking.buddy_statuses[:declined])
                .or(Booking.where(buddy_id: current_user.id, buddy_status: :accepted))
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
               .where("creator_id = :id OR buddy_id = :id", id: current_user.id)
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
    @buddies = current_user.buddies
    @buddy_flow = params[:buddy] == "true"
    @buddy_slots_by_id = buddy_slots_by_id(@buddies)
  end

  def create
    buddy_id = params.dig(:booking, :buddy_id)
    match = if buddy_id.present?
              current_user.matches.find_by("user_a_id = :id AND user_b_id = :buddy OR user_a_id = :buddy AND user_b_id = :id",
                                           id: current_user.id,
                                           buddy: buddy_id)
            end
    @booking = match.present? ? match.bookings.new(booking_params) : Booking.new(booking_params)
    @booking.creator = current_user
    assign_buddy(@booking)
    @booking.buddy_status = :pending if @booking.buddy.present?
    assign_match(@booking, match)
    set_availability_warning(@booking)
    if @booking.save
      redirect_to bookings_path, notice: "Booking created."
    else
      @matches = current_user.matches
      @buddies = current_user.buddies
      @buddy_flow = @booking.buddy_id.present?
      @buddy_slots_by_id = buddy_slots_by_id(@buddies)
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    booking = Booking
              .where(creator_id: current_user.id)
              .find(params[:id])
    booking.destroy
    redirect_to bookings_path, notice: "Booking cancelled."
  end

  def accept
    booking = Booking.find(params[:id])
    unless booking.buddy_id == current_user.id
      redirect_to bookings_path, alert: "You can only respond to your own invitations."
      return
    end

    booking.update!(buddy_status: :accepted)
    redirect_to bookings_path, notice: "Session accepted."
  end

  def decline
    booking = Booking.find(params[:id])
    unless booking.buddy_id == current_user.id
      redirect_to bookings_path, alert: "You can only respond to your own invitations."
      return
    end

    booking.update!(buddy_status: :declined)
    redirect_to bookings_path, notice: "Session declined."
  end

  private

  def booking_params
    params.require(:booking).permit(:start_at, :end_at, :status, :reminder_enabled, :reminder_minutes_before, :buddy_id)
  end

  def buddy_slots_by_id(buddies)
    buddies.includes(:availability_slots).each_with_object({}) do |buddy, memo|
      memo[buddy.id] = buddy.availability_slots.order(:dow, :start_min).map do |slot|
        {
          id: slot.id,
          dow: slot.dow,
          start_min: slot.start_min,
          end_min: slot.end_min,
          location_name: slot.location_name
        }
      end
    end
  end

  def assign_buddy(booking)
    return if booking.buddy_id.blank?

    booking.buddy = current_user.buddies.find_by(id: booking.buddy_id)
  end

  def assign_match(booking, match)
    return if booking.match.present?
    return if match.blank?

    booking.match = match
  end

  def set_availability_warning(booking)
    return if booking.buddy.blank?
    return if booking.start_at.blank? || booking.end_at.blank?

    user_ok = AvailabilitySlot.covers_range?(current_user.availability_slots, booking.start_at, booking.end_at)
    buddy_ok = AvailabilitySlot.covers_range?(booking.buddy.availability_slots, booking.start_at, booking.end_at)

    if user_ok && buddy_ok
      booking.availability_warning = "This fits both of your usual availability."
      booking.availability_warning_ok = true
    elsif user_ok && !buddy_ok
      booking.availability_warning = "This time is outside your buddy's usual availability."
      booking.availability_warning_ok = false
    elsif !user_ok && buddy_ok
      booking.availability_warning = "This time is outside your usual availability."
      booking.availability_warning_ok = false
    else
      booking.availability_warning = "This time is outside both of your usual availability."
      booking.availability_warning_ok = false
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
