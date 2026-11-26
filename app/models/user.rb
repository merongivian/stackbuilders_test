class User < ApplicationRecord
  has_many :request_logs, dependent: :nullify

  # Store emails lowercased so the unique DB index matches the
  # case-insensitive validation below.
  normalizes :email, with: -> { it.strip.downcase }

  validates :name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }
end
