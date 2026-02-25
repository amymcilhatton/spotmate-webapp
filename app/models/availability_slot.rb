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

  private

  def end_after_start
    return if start_min.nil? || end_min.nil?
    return if end_min > start_min

    errors.add(:end_min, "must be after start_min")
  end
end
