# -*- encoding: utf-8 -*-

require 'spec_helper'
require 'time_series'

describe Opower::TimeSeries::Metric do
  subject(:config) { { name: 'test1.test2', timestamp: 12_132_342, value: 1, tags: { 'x' => 1, 'y' => 2 } } }

  context 'with valid input' do
    describe 'Metric#new' do
      subject { Opower::TimeSeries::Metric.new(config) }

      describe '#name' do
        subject { super().name }
        it { is_expected.to eq('test1.test2') }
      end

      describe '#timestamp' do
        subject { super().timestamp }
        it { is_expected.to eq(12_132_342) }
      end

      describe '#value' do
        subject { super().value }
        it { is_expected.to eq(1) }
      end

      describe '#tags' do
        subject { super().tags }
        it { is_expected.to eq('x' => 1, 'y' => 2) }
      end
    end
  end

  context 'with invalid input' do
    it 'errors if no data is specified' do
      expect { Opower::TimeSeries::Metric.new }.to raise_error(ArgumentError)
    end

    it 'errors if no metric name is specified' do
      expect { Opower::TimeSeries::Metric.new(value: 1) }.to raise_error(ArgumentError)
    end

    it 'errors if no metric value is specified' do
      expect { Opower::TimeSeries::Metric.new(name: '123') }.to raise_error(ArgumentError)
    end
  end
end
