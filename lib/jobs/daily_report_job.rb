# frozen_string_literal: true

require 'sidekiq'

class DailyReportJob
  include Sidekiq::Job

  sidekiq_options queue: 'low', retry: 2

  def perform
    date = Date.today - 1.day  # Yesterday's report
    
    logger.info "Generating daily report for #{date}"
    
    # Calculate stats
    bookings_count = Booking.where(created_at: date.beginning_of_day..date.end_of_day).count
    revenue = Booking.where(created_at: date.beginning_of_day..date.end_of_day)
                    .sum(:total_price_amount)
    
    # Send report email to admin
    send_report_email(date, bookings_count, revenue)
    
    logger.info "Daily report sent: #{bookings_count} bookings, $#{revenue} revenue"
  end

  private

  def send_report_email(date, bookings_count, revenue)
    puts "📊 Daily Report - #{date}"
    puts "   Bookings: #{bookings_count}"
    puts "   Revenue: $#{sprintf('%.2f', revenue)}"
  end
end