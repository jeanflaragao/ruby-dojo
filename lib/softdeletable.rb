# frozen_string_literal: true

module SoftDeletable
  attr_reader :deleted_at

  def delete
    @deleted_at = Time.now
    self
  end

  def deleted?
    !@deleted_at.nil?
  end

  def restore
    @deleted_at = nil
    self
  end

  def self.included(base)
    # Add a scope-like method to the class
    # This is metaprogramming - we'll cover it more later
    base.extend(ClassMethods)
  end

  module ClassMethods
    # This will be a class method on the including class
    def active
      # Override in the class to filter non-deleted records
    end
  end
end
