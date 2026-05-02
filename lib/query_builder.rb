# frozen_string_literal: true

class QueryBuilder
  def initialize(events)
    @events = events
  end

  def where(&block)
    QueryBuilder.new(@events.select(&block))
  end

  def order_by(attribute)
    QueryBuilder.new(@events.sort_by { |e| e.send(attribute) })
  end

  def limit(count)
    QueryBuilder.new(@events.first(count))
  end

  def results
    @events.dup
  end
end