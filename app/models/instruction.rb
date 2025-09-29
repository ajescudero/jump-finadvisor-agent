class Instruction < ApplicationRecord
  belongs_to :user
  scope :active, -> { where(is_active: true) }
  validates :content, presence: true
end
