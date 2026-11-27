# One request to the API. created_at doubles as the request timestamp.
class RequestLog < ApplicationRecord
  validates :filter_type, presence: true
  validates :user_name, presence: true
end
