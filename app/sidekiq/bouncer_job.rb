class BouncerJob
  include Sidekiq::Job

  def perform(*args)
    Ticket.transaction do
      conn = ActiveRecord::Base.connection
      time_now = Time.now.to_i
      lingering_tickets = conn.execute("SELECT id FROM tickets WHERE expired_at < #{time_now}").to_a.flatten rescue []
      conn.execute("UPDATE tickets SET user_id = NULL, expired_at = NULL WHERE id IN (#{lingering_tickets.join(',')})")
    end
  end
end
