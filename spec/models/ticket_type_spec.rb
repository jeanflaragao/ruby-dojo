# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/models/ticket_type'
require_relative '../../lib/value_objects/money'

RSpec.describe TicketType do
  describe 'base class' do
    it 'cannot be instantiated directly' do
      expect { described_class.new }.to raise_error(NotImplementedError)
    end
  end

  describe VIPTicket do
    let(:base_price) { Money.new(100, 'USD') }
    let(:vip_ticket) { described_class.new(base_price) }

    it 'applies 2x multiplier to base price' do
      expect(vip_ticket.price).to eq(Money.new(200, 'USD'))
    end

    it 'has VIP tier' do
      expect(vip_ticket.tier).to eq(:vip)
    end

    it 'includes perks' do
      expect(vip_ticket.perks).to include('Priority seating', 'Meet & greet access')
    end

    it 'converts to hash' do
      result = vip_ticket.to_h
      expect(result[:tier]).to eq(:vip)
      expect(result[:price]).to eq({ amount: 200, currency: 'USD' })
      expect(result[:perks]).to be_an(Array)
    end
  end

  describe GeneralTicket do
    let(:base_price) { Money.new(100, 'USD') }
    let(:general_ticket) { described_class.new(base_price) }

    it 'uses base price (1x multiplier)' do
      expect(general_ticket.price).to eq(Money.new(100, 'USD'))
    end

    it 'has general tier' do
      expect(general_ticket.tier).to eq(:general)
    end

    it 'has standard seating perk' do
      expect(general_ticket.perks).to eq(['Standard seating'])
    end
  end

  describe StudentTicket do
    let(:base_price) { Money.new(100, 'USD') }
    let(:student_ticket) { described_class.new(base_price) }

    it 'applies 0.7x discount to base price' do
      expect(student_ticket.price).to eq(Money.new(70, 'USD'))
    end

    it 'has student tier' do
      expect(student_ticket.tier).to eq(:student)
    end

    it 'requires student ID' do
      expect(student_ticket.perks).to include('Student discount (30% off)')
    end

    it 'requires verification' do
      expect(student_ticket.requires_verification?).to be true
    end
  end

  describe 'polymorphism' do
    let(:base_price) { Money.new(100, 'USD') }

    it 'can work with different ticket types through base interface' do
      tickets = [
        VIPTicket.new(base_price),
        GeneralTicket.new(base_price),
        StudentTicket.new(base_price)
      ]

      prices = tickets.map(&:price)
      expect(prices).to eq([
                             Money.new(200, 'USD'),
                             Money.new(100, 'USD'),
                             Money.new(70, 'USD')
                           ])
    end

    it 'can sort tickets by price' do
      tickets = [
        VIPTicket.new(base_price),
        StudentTicket.new(base_price),
        GeneralTicket.new(base_price)
      ]

      sorted = tickets.sort_by { |t| t.price.amount }
      expect(sorted.map(&:tier)).to eq(%i[student general vip])
    end
  end
end
