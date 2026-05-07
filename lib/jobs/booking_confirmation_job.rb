# frozen_string_literal: true

require 'sidekiq'

class BookingConfirmationJob
  include Sidekiq::Job

  # Default queue is 'default', can specify: sidekiq_options queue: 'mailers'
  sidekiq_options queue: 'mailers', retry: 3

  def perform(booking_id)
    booking = Booking.find(booking_id)
    
    # Log the job
    logger.info "Processing booking confirmation for booking ##{booking_id}"
    
    # Send confirmation email (we'll implement this in Phase 4)
    send_confirmation_email(booking)
    
    logger.info "Booking confirmation sent for booking ##{booking_id}"
  end

  private

  def send_confirmation_email(booking)
    # Placeholder - we'll implement this with Mail gem in Phase 4
    puts "📧 Sending confirmation email to #{booking.email}"
    puts "   Booking: #{booking.confirmation_code}"
    puts "   Seats: #{booking.seats_reserved}"
  end
end