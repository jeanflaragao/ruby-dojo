# frozen_string_literal: true

require 'mail'
require 'erb'

class BookingMailer
  def self.confirmation_email(booking)
    new(booking).confirmation_email
  end

  def initialize(booking)
    @booking = booking
  end

  def confirmation_email
    booking = @booking
    
    # Render templates OUTSIDE the blocks
    html_body = render_html_template(booking)
    text_body = render_text_template(booking)
    
    # Create email
    mail = Mail.new do
      from     'noreply@ticketing.com'
      to       booking.email
      subject  "Booking Confirmation - #{booking.confirmation_code}"
    end

    # Set HTML part
    mail.html_part = Mail::Part.new do
      content_type 'text/html; charset=UTF-8'
      body html_body  # Use pre-rendered variable
    end

    # Set text part
    mail.text_part = Mail::Part.new do
      body text_body  # Use pre-rendered variable
    end

    # Send it!
    mail.deliver!
    
    puts "✅ Email sent to #{booking.email}"
    mail
  end

  private

  def render_html_template(booking)
    template_path = File.join(__dir__, '..', 'views', 'mailers', 'booking_confirmation.html.erb')
    template = File.read(template_path)
    ERB.new(template).result(binding)
  end

  def render_text_template(booking)
    template_path = File.join(__dir__, '..', 'views', 'mailers', 'booking_confirmation.txt.erb')
    template = File.read(template_path)
    ERB.new(template).result(binding)
  end
end