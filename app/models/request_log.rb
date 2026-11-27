class RequestLog < ApplicationRecord
  validates :filter_type, presence: true
  validates :user_name, presence: true
end
