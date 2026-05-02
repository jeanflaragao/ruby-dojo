# frozen_string_literal: true

module Searchable
  # Search by any attribute (case-insensitive partial match)
  #
  # @param attribute [Symbol] the attribute to search (e.g., :name, :description)
  # @param query [String] the search term
  # @return [Array] matching records
  def search_by(attribute, query)
    @events.select do |record|
      if record.respond_to?(attribute)
        value = record.send(attribute)
        value.to_s.downcase.include?(query.downcase)
      else
        false
      end
    end
  end

  # Search across multiple attributes
  #
  # @param query [String] the search term
  # @param attributes [Array<Symbol>] attributes to search
  # @return [Array] matching records
  def search_across(query, *attributes)
    @events.select do |record|
      attributes.any? do |attribute|
        if record.respond_to?(attribute)
          value = record.send(attribute)
          value.to_s.downcase.include?(query.downcase)
        else
          false
        end
      end
    end
  end
end
