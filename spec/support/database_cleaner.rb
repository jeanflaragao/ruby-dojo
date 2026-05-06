# Create support directory first if it doesn't exist
# mkdir -p spec/support

RSpec.configure do |config|
  config.before(:each) do
    # Clean in correct order (child -> parent)
    Booking.delete_all if defined?(Booking)
    Event.delete_all if defined?(Event)
    Venue.delete_all if defined?(Venue)
  end
end