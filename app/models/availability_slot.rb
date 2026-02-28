class AvailabilitySlot < ApplicationRecord
  belongs_to :user

  validates :dow, inclusion: { in: 0..6 }
  validates :start_min, :end_min, numericality: { greater_than_or_equal_to: 0 }
  validate :end_after_start

  def overlap_minutes(other)
    return 0 unless dow == other.dow

    overlap_start = [start_min, other.start_min].max
    overlap_end = [end_min, other.end_min].min
    [overlap_end - overlap_start, 0].max
  end

  def self.covers_range?(slots, start_at, end_at)
    return false if start_at.blank? || end_at.blank?
    return false if end_at <= start_at
    return false if start_at.to_date != end_at.to_date

    range_slot = AvailabilitySlot.new(
      dow: start_at.wday,
      start_min: (start_at.hour * 60) + start_at.min,
      end_min: (end_at.hour * 60) + end_at.min
    )
    range_duration = range_slot.end_min - range_slot.start_min

    slots.any? { |slot| slot.overlap_minutes(range_slot) >= range_duration }
  end

  private

  def end_after_start
    return if start_min.nil? || end_min.nil?
    return if end_min > start_min

    errors.add(:end_min, "must be after start_min")
  end
end
