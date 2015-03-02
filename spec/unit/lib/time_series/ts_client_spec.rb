# -*- encoding: utf-8 -*-

require 'spec_helper'
require 'time_series'

describe Opower::TimeSeries::TSClient do
  describe '#new' do
    context 'with defaults' do
      subject { Opower::TimeSeries::TSClient.new }

      describe '#host' do
        subject { super().host }
        it { is_expected.to eq '127.0.0.1' }
      end

      describe '#port' do
        subject { super().port }
        it { is_expected.to eq 4242 }
      end
    end

    context 'with user options' do
      subject { Opower::TimeSeries::TSClient.new('opentsdb.foo.com', 4343) }

      describe '#host' do
        subject { super().host }
        it { is_expected.to eq 'opentsdb.foo.com' }
      end

      describe '#port' do
        subject { super().port }
        it { is_expected.to eq 4343 }
      end
    end
  end

  describe '#configure' do
    context 'with defaults' do
      subject { Opower::TimeSeries::TSClient.new.config }

      describe(:dry_run) do
        subject { super()[:dry_run] }
        it { is_expected.to eq(false) }
      end

      describe(:version) do
        subject { super()[:version] }
        it { is_expected.to eq('2.0') }
      end
    end

    context 'with user input' do
      subject do
        client = Opower::TimeSeries::TSClient.new
        client.configure(dry_run: true, validation: true, version: '2.1')
        client.config
      end

      describe(:dry_run) do
        subject { super()[:dry_run] }
        it { is_expected.to eq(true) }
      end

      describe(:version) do
        subject { super()[:version] }
        it { is_expected.to eq('2.1') }
      end
    end
  end
end
