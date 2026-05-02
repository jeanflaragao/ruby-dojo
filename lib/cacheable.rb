# frozen_string_literal: true

module Cacheable
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def cache_config
      @cache_config ||= { ttl: 3600, enabled: true }
    end

    def configure_cache(ttl: nil, enabled: nil)
      cache_config[:ttl] = ttl if ttl
      cache_config[:enabled] = enabled unless enabled.nil?
    end
  end

  def cached_fetch(&block)
    return block.call unless self.class.cache_config[:enabled]

    @cache ||= {}
    cache_key = block.source_location.join(':')

    if @cache[cache_key] && !expired?(cache_key)
      @cache[cache_key][:value]
    else
      value = block.call
      @cache[cache_key] = { value: value, cached_at: Time.now }
      value
    end
  end

  private

  def expired?(key)
    ttl = self.class.cache_config[:ttl]
    Time.now - @cache[key][:cached_at] > ttl
  end
end

# Usage:
class EventRepository
  include Cacheable

  configure_cache ttl: 300, enabled: true

  def expensive_query
    cached_fetch do
      # expensive operation
    end
  end
end
