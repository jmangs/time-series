# -*- encoding: utf-8 -*-

require 'spec_helper'
require 'time_series'

describe Opower::TimeSeries::TSClient do
  describe '#run_synthetic_query' do
    subject { Opower::TimeSeries::TSClient.new('opentsdb.foo.com', 4242) }

    it 'computes a simple formula correctly' do
      m = [{ metric: 'sys.numa.allocation', tags: { host: 'opentsdb.foo.com' } }]
      config = { format: :json, start: 1421676714, finish: 1421676774, m: m }
      @query_one = Opower::TimeSeries::Query.new(config)

      m = [{ metric: 'sys.numa.zoneallocs', tags: { host: 'opentsdb.foo.com' } }]
      config = { format: :json, start: 1421676714, finish: 1421676774, m: m }
      @query_two = Opower::TimeSeries::Query.new(config)

      # stub requests
      stub_request(:get, subject.query_uri(@query_one)).to_return(status: 200, body: Fixtures::SYS_ALLOCATION)
      stub_request(:get, subject.query_uri(@query_two)).to_return(status: 200, body: Fixtures::SYS_ZONE_ALLOCS)

      synthetic_results = subject.run_synthetic_query('test', 'x / y', x: @query_one, y: @query_two)
      expect(synthetic_results.length).not_to eq(0)
    end
  end
end
