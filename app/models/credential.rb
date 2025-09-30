# app/models/credential.rb
class Credential < ApplicationRecord
  belongs_to :user

  validates :provider, presence: true
end
