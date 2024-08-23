class Event < ApplicationRecord
  has_many :tickets, dependent: :delete_all
end
