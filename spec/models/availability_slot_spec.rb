require "rails_helper"

RSpec.describe AvailabilitySlot, type: :model do
  describe ".covers_range?" do
    it "returns true when the range fits within a slot" do
      user = User.create!(email: "slot@example.com", password: "password")
      start_at = Time.zone.local(2026, 2, 26, 9, 0)
      end_at = Time.zone.local(2026, 2, 26, 10, 0)
      slot = AvailabilitySlot.create!(
        user: user,
        dow: start_at.wday,
        start_min: 8 * 60,
        end_min: 11 * 60
      )

      expect(AvailabilitySlot.covers_range?([slot], start_at, end_at)).to be(true)
    end

    it "returns false when the range is outside a slot" do
      user = User.create!(email: "slot2@example.com", password: "password")
      start_at = Time.zone.local(2026, 2, 26, 9, 0)
      end_at = Time.zone.local(2026, 2, 26, 10, 0)
      slot = AvailabilitySlot.create!(
        user: user,
        dow: start_at.wday,
        start_min: 11 * 60,
        end_min: 12 * 60
      )

      expect(AvailabilitySlot.covers_range?([slot], start_at, end_at)).to be(false)
    end
  end
end
