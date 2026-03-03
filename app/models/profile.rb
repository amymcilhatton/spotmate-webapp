class Profile < ApplicationRecord
  belongs_to :user

  enum experience_band: { beginner: 0, intermediate: 1, experienced: 2 }, _prefix: true
  enum travel_preference: { same_gym_only: "same_gym_only", same_city: "same_city", flexible: "flexible" },
       _prefix: true

  validates :age, numericality: { only_integer: true, greater_than_or_equal_to: 16, less_than_or_equal_to: 100 },
                  presence: true
  validates :gender, presence: true
  validates :experience_band, presence: true
  validates :match_radius_miles,
            numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validate :preferred_age_range_valid

  before_validation :enforce_women_only_rules

  GOAL_OPTIONS = %w[
    general_fitness
    strength
    hypertrophy
    weight_loss
    crossfit
    hyrox
    olympic_lifting
    cardio
    mobility
    skill_work
  ].freeze

  TIME_OF_DAY_OPTIONS = %w[morning lunchtime afternoon evening late_night].freeze
  BUDDY_DAY_OPTIONS = %w[mon tue wed thu fri sat sun].freeze

  def distance_to(other_profile)
    return nil unless other_profile
    return nil if gym_latitude.blank? || gym_longitude.blank?
    return nil if other_profile.gym_latitude.blank? || other_profile.gym_longitude.blank?

    lat1 = gym_latitude.to_f
    lon1 = gym_longitude.to_f
    lat2 = other_profile.gym_latitude.to_f
    lon2 = other_profile.gym_longitude.to_f

    earth_radius_miles = 3958.8
    dlat = degrees_to_radians(lat2 - lat1)
    dlon = degrees_to_radians(lon2 - lon1)

    a = Math.sin(dlat / 2)**2 +
        Math.cos(degrees_to_radians(lat1)) * Math.cos(degrees_to_radians(lat2)) *
        Math.sin(dlon / 2)**2
    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))

    earth_radius_miles * c
  end

  def nearby_profiles(max_miles:)
    return [] if gym_latitude.blank? || gym_longitude.blank?

    Profile.where.not(id: id).select do |profile|
      distance = distance_to(profile)
      distance && distance <= max_miles
    end
  end

  private

  def degrees_to_radians(degrees)
    degrees * Math::PI / 180.0
  end

  def preferred_age_range_valid
    return if preferred_partner_age_min.blank? || preferred_partner_age_max.blank?
    return if preferred_partner_age_min <= preferred_partner_age_max

    errors.add(:preferred_partner_age_max, "must be greater than or equal to min age")
  end

  def enforce_women_only_rules
    if gender == "male"
      self.women_only = false
    end
  end
end
