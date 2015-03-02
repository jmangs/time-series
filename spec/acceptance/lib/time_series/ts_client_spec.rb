# -*- encoding: utf-8 -*-

require 'spec_helper'
require 'time_series'

describe Opower::TimeSeries::TSClient do
  describe '#suggest' do
    subject { Opower::TimeSeries::TSClient.new('opentsdb.foo.com', 4242) }

    before do
      stub_request(:get, subject.suggest_uri('mtest')).to_return(body: '[]')
      stub_request(:get, subject.suggest_uri('sys')).to_return(body: Fixtures::SUGGEST_SYS)
    end

    context 'in dry run mode' do
      subject do
        super().configure(dry_run: true)
        super()
      end

      it 'returns the proper URI' do
        url = subject.suggest_uri('mtest')
        expect(url).to eq('http://opentsdb.foo.com:4242/api/suggest?type=metrics&q=mtest&max=25')
      end
    end

    context 'in normal mode' do
      subject do
        super().configure(dry_run: false)
        super()
      end

      it 'returns an empty array for a query with no expected results' do
        suggestions = subject.suggest('mtest')
        expect(suggestions).to eq([])
      end

      it 'returns data for a query with expected results' do
        suggestions = subject.suggest('sys')
        expect(suggestions).to eq(JSON.parse(Fixtures::SUGGEST_SYS))
      end
    end
  end

  describe '#run_query' do
    subject { Opower::TimeSeries::TSClient.new('opentsdb.foo.com', 4242) }

    context 'with invalid input' do
      it 'raises an error for a bad metric name' do
        m = [{ metric: 'mtest' }]
        config = { format: :json, start: 1421676714, finish: 1421676774, m: m }
        query = Opower::TimeSeries::Query.new(config)
        stub_request(:get, subject.query_uri(query)).to_return(status: 500, body: Fixtures::BAD_METRIC)

        results = subject.run_query(query).results
        expect(results).to include(JSON.parse(Fixtures::BAD_METRIC))
      end

      it 'raises an error for a bad tagk name ' do
        m = [{ metric: 'sys.numa.allocation', tags: { bad_tagk: 'opentsdb.foo.com' } }]
        config = { format: :json, start: 1421676714, finish: 1421676774, m: m }
        query = Opower::TimeSeries::Query.new(config)
        stub_request(:get, subject.query_uri(query)).to_return(status: 500, body: Fixtures::BAD_TAGK)

        results = subject.run_query(query).results
        expect(results).to include(JSON.parse(Fixtures::BAD_TAGK))
      end
    end

    context 'with valid input' do
      it 'returns an empty JSON array for a query with no expected results' do
        m = [{ metric: 'sys.numa.allocation' }]
        config = { format: :json, start: 1420676714, finish: 1420676774, m: m }
        query = Opower::TimeSeries::Query.new(config)
        stub_request(:get, subject.query_uri(query)).to_return(status: 200, body: '[]')

        results = subject.run_query(query).results
        expect(results).to eq([])
      end

      it 'returns data for a query in JSON format' do
        m = [{ metric: 'sys.numa.allocation', tags: { host: 'opentsdb.foo.com' } }]
        config = { format: :json, start: 1420676714, finish: 1420676774, m: m }
        query = Opower::TimeSeries::Query.new(config)
        stub_request(:get, subject.query_uri(query)).to_return(body: Fixtures::SYS_ALLOCATION)

        results = subject.run_query(query).results
        expect(results).to eq(JSON.parse(Fixtures::SYS_ALLOCATION))
      end

      it 'returns data for a rate query in JSON format' do
        m = [{ metric: 'sys.numa.allocation', rate: true, tags: { host: 'opentsdb.foo.com' } }]
        config = { format: :json, start: 1420676714, finish: 1420676774, m: m }
        query = Opower::TimeSeries::Query.new(config)
        stub_request(:get, subject.query_uri(query)).to_return(body: Fixtures::SYS_ALLOC_RATE)

        results = subject.run_query(query).results
        expect(results).to eq(JSON.parse(Fixtures::SYS_ALLOC_RATE))
      end

      it 'returns a URL for a query in PNG format' do
        m = [{ metric: 'sys.numa.allocation', tags: { host: 'opentsdb.foo.com' } }]
        config = { format: :png, start: 1420676714, finish: 1420676774, m: m }
        query = Opower::TimeSeries::Query.new(config)
        results = subject.run_query(query)
        expect(results).not_to eq('')
        expect(results).not_to include('Internal Server Error')
      end

      it 'returns data for multiple queries' do
        queries = []
        3.times do
          m = [{ metric: 'sys.numa.allocation', tags: { host: 'opentsdb.foo.com' } }]
          config = { format: :json, start: '1h-ago', m: m }
          query = Opower::TimeSeries::Query.new(config)
          stub_request(:get, subject.query_uri(query)).to_return(body: Fixtures::SYS_ALLOCATION)
          queries << query
        end

        results = subject.run_queries(queries)
        expect(results.length).to eq(3)
        results.each do |r|
          expect(r.results).not_to eq('')
        end
      end
    end
  end

  describe '#valid?' do
    subject { Opower::TimeSeries::TSClient.new('opentsdb.foo.com', 4242) }

    context 'with a valid connection' do
      it 'returns true' do
        stub_request(:get, "#{subject.client}api/version").to_return(status: 200)
        expect(subject.valid?).to be_truthy
      end
    end

    context 'with an invalid connection' do
      it 'returns false' do
        stub_request(:get, "#{subject.client}api/version").to_timeout
        expect(subject.valid?).to be_falsey
      end
    end
  end
end
