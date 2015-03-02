# -*- encoding: utf-8 -*-

require 'time_series'
require 'spec_helper'

describe Opower::TimeSeries::SyntheticResult do
  context 'with valid input' do
    it 'calculates results for aligned time-series' do
      formula = 'x + y'
      data = { x: { '123' => 1, '124' => 2 }, y: { '123' => 1, '124' => 2, '125' => 3 } }

      synthetic_results = Opower::TimeSeries::SyntheticResult.new('test', formula, data)
      calculated_dps = synthetic_results.results
      expect(calculated_dps['123']).to eq(2)
      expect(calculated_dps['124']).to eq(4)
      expect(calculated_dps['125']).to be_nil
    end

    it 'supports using Ruby math functions' do
      formula = 'cos((x + y))'
      data = { x: { '123' => 1, '124' => 2 }, y: { '123' => 1, '124' => 2, '125' => 3 } }

      synthetic_results = Opower::TimeSeries::SyntheticResult.new('test', formula, data)
      calculated_dps = synthetic_results.results
      expect(calculated_dps['123']).to eq(-0.4161468365471424)
      expect(calculated_dps['124']).to eq(-0.6536436208636119)
      expect(calculated_dps['125']).to be_nil
    end
  end

  context 'with invalid input' do
    it 'errors when dividing by zero' do
      formula = 'x / y'
      data = { x: { '123' => 10, '124' => 20, '125' => 30 }, y: { '123' => 1, '124' => 0, '125' => 3 } }

      expect { Opower::TimeSeries::SyntheticResult.new('test', formula, data) }.to raise_error(ZeroDivisionError)
    end
  end
end
