class Booking < ApplicationRecord
  belongs_to :match

  validates :start_at, :end_at, presence: true
  validate :end_after_start

  private

  def end_after_start
    return if start_at.nil? || end_at.nil?
    return if end_at > start_at

    errors.add(:end_at, "must be after start_at")
  end
end
