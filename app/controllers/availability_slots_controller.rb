class AvailabilitySlotsController < ApplicationController
  def index
    @availability_slots = current_user.availability_slots.order(:dow, :start_min)
    @slots_by_day = AvailabilitySlotsHelper::DAY_ORDER.map do |_label, dow|
      [dow, @availability_slots.select { |slot| slot.dow == dow }]
    end.to_h
    @summary_text = summary_text(@availability_slots)
    @availability_suggestions = availability_suggestions(@availability_slots)
    @overlapping_slot_ids = overlapping_slot_ids(@slots_by_day)
    @partner_overlap_by_slot_id = partner_overlap_map(@availability_slots)
    @home_gym_name = current_user.profile&.home_gym_name
    @new_slot = current_user.availability_slots.new(default_slot_attributes)
  end

  def new
    @availability_slot = current_user.availability_slots.new(default_slot_attributes)
  end

  def create
    @availability_slot = current_user.availability_slots.new(availability_slot_params)
    if @availability_slot.save
      redirect_to availability_slots_path, notice: "Availability added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @availability_slot = current_user.availability_slots.find(params[:id])
  end

  def update
    @availability_slot = current_user.availability_slots.find(params[:id])
    if @availability_slot.update(availability_slot_params)
      redirect_to availability_slots_path, notice: "Availability updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    slot = current_user.availability_slots.find(params[:id])
    slot.destroy
    redirect_to availability_slots_path, notice: "Availability removed."
  end

  private

  def availability_slot_params
    permitted = params.require(:availability_slot).permit(:dow, :location_name, :start_time, :end_time)
    permitted[:start_min] = minutes_from_time(permitted.delete(:start_time))
    permitted[:end_min] = minutes_from_time(permitted.delete(:end_time))
    permitted
  end

  def minutes_from_time(value)
    return nil if value.blank?

    parts = value.split(":").map(&:to_i)
    (parts[0] * 60) + parts[1]
  end

  def summary_text(slots)
    return "No weekly slots yet" if slots.empty?

    days = slots.map(&:dow).uniq
    day_labels = AvailabilitySlotsHelper::DAY_ORDER.select { |_label, dow| days.include?(dow) }
                                                   .map(&:first)
    time_bucket = dominant_time_bucket(slots)
    total_minutes = slots.sum { |slot| (slot.end_min || 0) - (slot.start_min || 0) }
    hours = total_minutes / 60.0
    hours_label = hours % 1 == 0 ? hours.to_i : hours.round(1)
    "#{slots.size} weekly slots · #{day_labels.join(' · ')} · #{time_bucket} · #{hours_label} hours total"
  end

  def dominant_time_bucket(slots)
    buckets = slots.map { |slot| time_bucket_for(slot.start_min) }.compact
    return "Mixed times" if buckets.empty?

    buckets.tally.max_by { |_k, v| v }&.first&.humanize || "Mixed times"
  end

  def time_bucket_for(start_min)
    return nil if start_min.nil?

    case start_min
    when 300..599 then "morning"
    when 600..839 then "lunchtime"
    when 840..1019 then "afternoon"
    when 1020..1259 then "evening"
    else "late night"
    end
  end

  def availability_suggestions(slots)
    suggestions = []
    profile = current_user.profile
    return suggestions if profile.nil?

    if slots.size < 2
      suggestions << "Add at least one more weekly slot for better matches."
    end

    preferred_days = profile.preferred_buddy_days
    if preferred_days.present?
      missing_day = preferred_days.find do |day|
        dow = AvailabilitySlotsHelper::DAY_ORDER.find { |label, _| label.downcase.start_with?(day) }&.last
        dow && slots.none? { |slot| slot.dow == dow }
      end
      suggestions << "Add a #{missing_day.capitalize} slot to improve your match results." if missing_day.present?
    end

    preferred_times = profile.preferred_buddy_times
    if preferred_times.present?
      missing_time = preferred_times.find do |time_key|
        slots.none? { |slot| time_bucket_for(slot.start_min) == time_key }
      end
      suggestions << "Add at least one #{missing_time.humanize.downcase} slot for better flexibility." if missing_time.present?
    end

    suggestions
  end

  def overlapping_slot_ids(slots_by_day)
    overlaps = []
    slots_by_day.each_value do |slots|
      ordered = slots.sort_by(&:start_min)
      ordered.each_cons(2) do |slot_a, slot_b|
        next if slot_a.end_min.nil? || slot_b.start_min.nil?
        next if slot_a.end_min <= slot_b.start_min

        overlaps << slot_a.id
        overlaps << slot_b.id
      end
    end
    overlaps.uniq
  end

  def partner_overlap_map(slots)
    accepted_matches = current_user.matches.select(&:status_accepted?)
    return {} if accepted_matches.empty?

    partner_slots = accepted_matches.map do |match|
      partner = match.other_user(current_user)
      [partner, partner.availability_slots]
    end

    slots.each_with_object({}) do |slot, memo|
      names = []
      partner_slots.each do |partner, slots_for_partner|
        next if slots_for_partner.none? { |other| overlap?(slot, other) }

        names << (partner.name || partner.email)
      end
      memo[slot.id] = names if names.any?
    end
  end

  def overlap?(slot_a, slot_b)
    return false unless slot_a.dow == slot_b.dow
    return false if slot_a.start_min.nil? || slot_a.end_min.nil?
    return false if slot_b.start_min.nil? || slot_b.end_min.nil?

    slot_a.start_min < slot_b.end_min && slot_b.start_min < slot_a.end_min
  end

  def default_slot_attributes
    profile = current_user.profile
    return {} if profile.nil?

    default_day = profile.preferred_buddy_days.first
    default_time = profile.preferred_buddy_times.first

    dow = AvailabilitySlotsHelper::DAY_ORDER.find { |label, _| label.downcase.start_with?(default_day.to_s) }&.last
    start_min, end_min = AvailabilitySlotsHelper::TIME_WINDOWS[default_time] if default_time.present?

    {
      dow: dow,
      start_min: start_min,
      end_min: end_min,
      location_name: profile.home_gym_name
    }.compact
  end
end
