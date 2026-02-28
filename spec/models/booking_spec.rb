require "rails_helper"

RSpec.describe Booking, type: :model do
  describe "#buddy_session?" do
    it "returns true when a buddy is present" do
      user = User.create!(email: "owner@example.com", password: "password")
      buddy = User.create!(email: "buddy@example.com", password: "password")
      match = Match.create!(user_a: user, user_b: buddy, status: :accepted)

      booking = match.bookings.create!(
        start_at: Time.zone.local(2026, 2, 26, 9, 0),
        end_at: Time.zone.local(2026, 2, 26, 10, 0),
        buddy: buddy,
        creator: user
      )

      expect(booking.buddy_session?).to be(true)
    end

    it "returns false when no buddy is assigned" do
      user = User.create!(email: "owner2@example.com", password: "password")
      buddy = User.create!(email: "buddy2@example.com", password: "password")
      match = Match.create!(user_a: user, user_b: buddy, status: :accepted)

      booking = match.bookings.create!(
        start_at: Time.zone.local(2026, 2, 26, 9, 0),
        end_at: Time.zone.local(2026, 2, 26, 10, 0),
        creator: user
      )

      expect(booking.buddy_session?).to be(false)
    end
  end

  describe "#status_for" do
    it "returns accepted for host and pending for buddy on creation" do
      host = User.create!(email: "host@example.com", password: "password")
      buddy = User.create!(email: "buddy3@example.com", password: "password")
      match = Match.create!(user_a: host, user_b: buddy, status: :accepted)

      booking = match.bookings.create!(
        start_at: Time.zone.local(2026, 2, 26, 9, 0),
        end_at: Time.zone.local(2026, 2, 26, 10, 0),
        buddy: buddy,
        creator: host
      )

      expect(booking.status_for(host)).to eq(:accepted)
      expect(booking.status_for(buddy)).to eq(:pending)
    end

    it "returns accepted for buddy after acceptance" do
      host = User.create!(email: "host2@example.com", password: "password")
      buddy = User.create!(email: "buddy4@example.com", password: "password")
      match = Match.create!(user_a: host, user_b: buddy, status: :accepted)

      booking = match.bookings.create!(
        start_at: Time.zone.local(2026, 2, 26, 9, 0),
        end_at: Time.zone.local(2026, 2, 26, 10, 0),
        buddy: buddy,
        creator: host
      )
      booking.update!(buddy_status: :accepted)

      expect(booking.status_for(buddy)).to eq(:accepted)
    end
  end
end
