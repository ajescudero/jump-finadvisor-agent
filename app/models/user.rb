class User < ApplicationRecord
  has_many :embeddings, dependent: :destroy
  has_many :instructions, dependent: :destroy
  has_many :tasks, dependent: :destroy
end