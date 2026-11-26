class RequestLog < ApplicationRecord
  belongs_to :user, optional: true

  validates :filter_type, presence: true
end
