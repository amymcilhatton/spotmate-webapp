class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum role: { member: 0, admin: 1 }, _prefix: true

  has_one_attached :avatar
  has_one :profile, dependent: :destroy
  has_many :availability_slots, dependent: :destroy
  has_many :workout_logs, dependent: :destroy
  has_many :prs, dependent: :destroy
  has_many :group_members, dependent: :destroy
  has_many :groups, through: :group_members
  has_many :survey_responses, dependent: :destroy
  has_many :matches_as_a, class_name: "Match", foreign_key: :user_a_id, dependent: :destroy
  has_many :matches_as_b, class_name: "Match", foreign_key: :user_b_id, dependent: :destroy
  has_many :match_decisions, dependent: :destroy
  has_many :workout_comments, foreign_key: :author_id, dependent: :destroy
  has_many :workout_kudos, foreign_key: :giver_id, dependent: :destroy

  def matches
    Match.where("user_a_id = ? OR user_b_id = ?", id, id)
  end

  def accepted_buddies
    match_ids = Match.where(status: Match.statuses[:accepted])
                     .where("user_a_id = :id OR user_b_id = :id", id: id)
    user_ids = match_ids.pluck(:user_a_id, :user_b_id).flatten.uniq - [id]
    User.where(id: user_ids)
  end

  validate :avatar_type
  validate :avatar_size

  private

  def avatar_type
    return unless avatar.attached?
    return if avatar.content_type.in?(%w[image/png image/jpeg image/jpg image/webp])

    errors.add(:avatar, "must be a PNG, JPG, or WebP image")
  end

  def avatar_size
    return unless avatar.attached?
    return if avatar.byte_size <= 2.megabytes

    errors.add(:avatar, "must be smaller than 2MB")
  end
end
