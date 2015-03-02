# -*- encoding: utf-8 -*-

require 'spec_helper'
require 'time_series'
require 'docker'

describe Opower::TimeSeries::TSClient do
  # Integration tests run inside a Docker container
  before :all do
    # allow HTTP during integration tests
    WebMock.allow_net_connect!

    @container = Docker::Container.create('Image' => 'opower/opentsdb')
    @container.start('PortBindings' => { '4242/tcp' => [{ 'HostPort' => '48000' }] })

    # check if we're runing boot2docker
    if ENV['DOCKER_HOST'].nil?
      network_settings = @container.json.fetch('NetworkSettings')
      @ip = network_settings.fetch('IPAddress') # TODO: verify this works for boot2docker
      @port = 4242
    else
      @ip = `boot2docker ip 2> /dev/null`
      @port = 48000
    end

    sleep 30
    attempts = 0
    client = Opower::TimeSeries::TSClient.new(@ip, @port)

    while client.valid? == false && attempts < 10
      sleep 5
      attempts += 1
    end

    fail RemoteError('Failed to start Docker container!') if attempts > 10 && !client.valid?

    # prewrite expected metrics
    metrics = [{ name: 'cpu.load', timestamp: 1420676750, value: 1, tags: { host: 'localhost' } },
               { name: 'test1.test2', timestamp: 12132343, value: 1, tags: { host: 'localhost' } },
               { name: 'metric1', timestamp: 1421676714, value: 1, tags: { host: 'localhost' } },
               { name: 'metric2', timestamp: 1421676714, value: 2, tags: { host: 'localhost' } }]

    metrics.each { |metric| client.write(Opower::TimeSeries::Metric.new(metric)) }

    # wait for OpenTSDB to synch
    sleep 3
  end

  after :all do
    @container.stop
    @container.delete(force: true)

    # resume blocking afterwards (in case acceptance tests afterwards)
    WebMock.disable_net_connect!
  end

  describe '#suggest' do
    subject { Opower::TimeSeries::TSClient.new(@ip, @port) }

    context 'with no expected results' do
      it 'returns an empty array' do
        suggestions = subject.suggest('mtest')
        expect(suggestions).to eq([])
      end
    end

    context 'with expected results' do
      it 'returns data' do
        suggestions = subject.suggest('test1.test2')
        expect(suggestions).to eq(['test1.test2'])
      end
    end
  end

  describe '#run_query' do
    subject { Opower::TimeSeries::TSClient.new(@ip, @port) }

    context 'with bad input' do
      it 'raises an error for a bad metric name' do
        m = [{ metric: 'mtest' }]
        config = { format: :json, start: 1421676714, finish: 1421676774, m: m }
        query = Opower::TimeSeries::Query.new(config)

        results = subject.run_query(query)
        expect(results.errors?).to be_truthy
        expect(results.error_message).to eq("No such name for 'metrics': 'mtest'")
      end

      it 'raises an error for a bad tagk name ' do
        m = [{ metric: 'test1.test2', tags: { bad_tagk: 'opentsdb.foo.com' } }]
        config = { format: :json, start: 1421676714, finish: 1421676774, m: m }
        query = Opower::TimeSeries::Query.new(config)

        results = subject.run_query(query)
        expect(results.errors?).to be_truthy
        expect(results.error_message).to eq("No such name for 'tagk': 'bad_tagk'")
      end
    end

    context 'with valid input' do
      it 'returns data' do
        m = [{ metric: 'cpu.load' }]
        config = { format: :json, start: 1420676714, finish: 1420676774, m: m }
        query = Opower::TimeSeries::Query.new(config)

        results = subject.run_query(query).results
        expect(results.length).not_to eq(0)
        expect(results[0].fetch('dps')).to include('1420676750' => 1)
      end
    end
  end

  describe '#run_synthetic_query' do
    subject { Opower::TimeSeries::TSClient.new(@ip, @port) }

    it 'computes a simple formula correctly' do
      m = [{ metric: 'metric1' }]
      config = { format: :json, start: 1421676000, finish: 1421676774, m: m }
      query_one = Opower::TimeSeries::Query.new(config)

      m = [{ metric: 'metric2' }]
      config = { format: :json, start: 1421676000, finish: 1421676774, m: m }
      query_two = Opower::TimeSeries::Query.new(config)

      synthetic_results = subject.run_synthetic_query('test', 'x / y', x: query_one, y: query_two)
      expect(synthetic_results.length).not_to eq(0)
    end
  end
end
