class Profile < ApplicationRecord
  belongs_to :user

  enum experience_band: { beginner: 0, intermediate: 1, experienced: 2 }, _prefix: true
  enum travel_preference: { same_gym_only: "same_gym_only", same_city: "same_city", flexible: "flexible" },
       _prefix: true

  validates :age, numericality: { only_integer: true, greater_than_or_equal_to: 16, less_than_or_equal_to: 100 },
                  presence: true
  validates :gender, presence: true
  validates :experience_band, presence: true
  validate :preferred_age_range_valid

  before_validation :enforce_women_only_rules

  GOAL_OPTIONS = %w[
    general_fitness
    strength
    hypertrophy
    weight_loss
    crossfit
    olympic_lifting
    cardio
    mobility
    skill_work
  ].freeze

  TIME_OF_DAY_OPTIONS = %w[morning lunchtime afternoon evening late_night].freeze
  BUDDY_DAY_OPTIONS = %w[mon tue wed thu fri sat sun].freeze

  private

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
