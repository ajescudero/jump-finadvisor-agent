# app/models/contact.rb
class Contact < ApplicationRecord
  belongs_to :user

  validates :user_id, presence: true
end
