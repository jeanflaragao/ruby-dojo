# frozen_string_literal: true

require 'mail'

# Load environment variables
require 'dotenv/load' if File.exist?('.env')

# Validate required environment variables
required_vars = ['SMTP_USERNAME', 'SMTP_PASSWORD']
missing_vars = required_vars.reject { |var| ENV[var] }

if missing_vars.any? && ENV['RACK_ENV'] != 'test'
  warn "⚠️  Missing environment variables: #{missing_vars.join(', ')}"
  warn "⚠️  Please create a .env file with your email credentials"
  warn "⚠️  See .env.example for template"
end

# Configure Mail
Mail.defaults do
  if ENV['RACK_ENV'] == 'test'
    # Test mode - don't actually send emails
    delivery_method :test
  elsif ENV['RACK_ENV'] == 'development' && ENV['SMTP_USERNAME'].nil?
    # Development without config - log instead
    delivery_method :logger
  else
    # Production or configured development - use SMTP
    delivery_method :smtp, {
      address: ENV.fetch('SMTP_ADDRESS', 'smtp.gmail.com'),
      port: ENV.fetch('SMTP_PORT', 587).to_i,
      domain: ENV.fetch('SMTP_DOMAIN', 'gmail.com'),
      user_name: ENV['SMTP_USERNAME'],
      password: ENV['SMTP_PASSWORD'],
      authentication: ENV.fetch('SMTP_AUTHENTICATION', 'plain').to_sym,
      enable_starttls_auto: ENV.fetch('SMTP_ENABLE_STARTTLS', 'true') == 'true',
      openssl_verify_mode: ENV.fetch('SMTP_OPENSSL_VERIFY_MODE', 'peer')
    }
  end
end

# Log configuration in development
if ENV['RACK_ENV'] == 'development' && ENV['SMTP_USERNAME']
  puts "📧 Mail configured with: #{ENV['SMTP_USERNAME']} via #{ENV.fetch('SMTP_ADDRESS', 'smtp.gmail.com')}"
end