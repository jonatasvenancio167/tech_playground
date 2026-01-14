class Employee < ApplicationRecord
  has_many :responses, dependent: :destroy
end

