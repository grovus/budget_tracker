class PaymentType < ActiveRecord::Base
  has_many :transactions

  validates :name,  presence: true, uniqueness: true, length: { maximum: 50 }
end
