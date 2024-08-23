class Ticket < ApplicationRecord
  belongs_to :event

  def self.create_empty_tickets(event)
    number_of_tickets = event.capacity
    tickets = Array.new(number_of_tickets) { { event_id: event.id } }
    Ticket.insert_all(tickets)
  end

  def reserved?
    user_id.present?
  end

  def status_done?
    expired_at.present? && expired_at < Time.now.to_i
  end

  def status
    return "FILLED" if reserved? && status_done?
    return "RESERVED" if reserved?
    return "AVAILABLE" if !reserved?
  end
end
