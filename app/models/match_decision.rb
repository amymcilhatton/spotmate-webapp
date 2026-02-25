class MatchDecision < ApplicationRecord
  belongs_to :match
  belongs_to :user

  enum decision: { accepted: 0, declined: 1, rematch: 2 }, _prefix: true
end
