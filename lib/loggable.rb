# frozen_string_literal: true

# lib/loggable.rb
module Loggable
  def save
    log("Saving #{self.class.name}...")
    result = super # Call original save method
    log("Saved #{self.class.name} successfully")
    result
  end

  def update(*args)
    log("Updating #{self.class.name}...")
    result = super
    log("Updated #{self.class.name} successfully")
    result
  end

  private

  def log(message)
    puts "[#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}] #{message}"
  end
end
