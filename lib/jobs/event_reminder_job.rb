# frozen_string_literal: true

require 'sidekiq'

class EventReminderJob
  include Sidekiq::Job

  sidekiq_options queue: 'mailers', retry: 3

  def perform(event_id)
    event = Event.find(event_id)
    
    # Get all bookings for this event
    bookings = Booking.where(event_id: event_id)
    
    bookings.each do |booking|
      send_reminder_email(event, booking)
    end
    
    logger.info "Sent #{bookings.count} reminder emails for event ##{event_id}"
  end

  private

  def send_reminder_email(event, booking)
    # Send reminder 24 hours before event
    puts "📧 Reminder: #{event.name} starts tomorrow!"
    puts "   To: #{booking.email}"
    puts "   Confirmation: #{booking.confirmation_code}"
  end
end