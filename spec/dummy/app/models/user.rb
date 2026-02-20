class User < ActiveRecord::Base
  has_many :orders
  scope :recent, -> { where(created_at: 7.days.ago..) }
end
