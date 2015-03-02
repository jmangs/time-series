# -*- encoding: utf-8 -*-

require 'spec_helper'
require 'time_series'

describe Opower::TimeSeries::TSClient do
  describe '#write' do
    subject { Opower::TimeSeries::TSClient.new('127.0.0.1', 60000) }
    let(:config) { { name: 'test1.test2', timestamp: 12132342, value: 1, tags: { host: 'localhost' } } }
    let(:metric) { Opower::TimeSeries::Metric.new(config) }

    context 'in dry run mode' do
      it 'returns the put string' do
        subject.configure(dry_run: true)
        call = subject.write(metric)
        expect(call).to eq("echo \"put test1.test2 12132342 1 host=localhost\" | nc -w 30 127.0.0.1 60000")
      end
    end

    context 'in normal mode' do
      it 'errors on failing to insert data' do
        message = "Failed to insert metric #{metric.name} with value of #{metric.value} into OpenTSDB."
        expect { subject.write(metric) }.to raise_error(IOError, message)
      end
    end
  end
end
