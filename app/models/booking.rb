class Booking < ApplicationRecord
  belongs_to :match, optional: true
  belongs_to :buddy, class_name: "User", optional: true
  belongs_to :creator, class_name: "User"

  attribute :buddy_status, :integer

  attr_accessor :availability_warning, :availability_warning_ok

  enum buddy_status: { pending: 0, accepted: 1, declined: 2 }, _prefix: true

  validates :start_at, :end_at, presence: true
  validates :match, presence: true, if: -> { buddy.present? }
  validate :end_after_start

  before_validation :set_default_buddy_status, on: :create

  def buddy_session?
    buddy.present?
  end

  def host
    creator
  end

  def partner_for(user)
    return nil if user.nil?
    return buddy if user.id == creator_id
    return creator if buddy_id.present? && user.id == buddy_id

    nil
  end

  def partner_first_name_for(user)
    partner = partner_for(user)
    return nil if partner.nil?

    (partner.name.presence || partner.email).to_s.split.first
  end

  def status_for(user)
    # status is determined by the buddy status and whether the viewer is the organiser or the invited buddy
    return :accepted unless buddy_session?
    return :declined if buddy_status_declined?

    if user&.id == creator_id
      :accepted
    elsif user&.id == buddy_id
      return :pending if buddy_status_pending?
      return :accepted if buddy_status_accepted?
    end

    :unknown
  end

  def pending_for?(user)
    status_for(user) == :pending
  end

  def accepted_for?(user)
    status_for(user) == :accepted
  end

  def declined_for?(user)
    status_for(user) == :declined
  end

  def availability_warning_ok?
    availability_warning_ok
  end

  def status_label_for(user)
    if buddy_session? && user&.id == creator_id && buddy_status_pending?
      return "Awaiting response"
    end

    case status_for(user)
    when :accepted then "Accepted"
    when :pending then "Pending"
    when :declined then "Declined"
    else nil
    end
  end

  def status_badge_class_for(user)
    if buddy_session? && user&.id == creator_id && buddy_status_pending?
      return "badge badge-muted"
    end

    case status_for(user)
    when :accepted then "badge"
    when :pending then "badge badge-muted"
    when :declined then "badge badge-muted"
    else "badge badge-muted"
    end
  end

  private

  def set_default_buddy_status
    # Buddy sessions start pending; solo sessions are accepted.
    if buddy.present?
      self.buddy_status = "pending" if buddy_status.blank? || !buddy_status_changed?
    else
      self.buddy_status = "accepted"
    end
  end

  def end_after_start
    return if start_at.nil? || end_at.nil?
    return if end_at > start_at

    errors.add(:end_at, "must be after start_at")
  end
end
