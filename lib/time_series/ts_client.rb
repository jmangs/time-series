# -*- encoding: utf-8 -*-

require 'rubygems'
require 'excon'
require 'json'
require 'logger'

module Opower
  module TimeSeries
    # Ruby client object to interface with an OpenTSDB instance.
    class TSClient
      attr_accessor :host, :port, :client, :config, :connection, :connection_settings

      # Creates a connection to a specified OpenTSDB instance
      #
      # @param [String] host The hostname/IP to connect to. Defaults to 'localhost'.
      # @param [Integer] port The port to connect to. Defaults to 4242.
      # @param [String] protocol The protocol to use. Defaults to 'http'.
      #
      # @return [TSClient] Client connection to OpenTSDB.
      def initialize(host = '127.0.0.1', port = 4242, protocol = 'http')
        @host = host
        @port = port

        @client = "#{protocol}://#{host}:#{port}/"
        @connection = Excon.new(@client, persistent: true, idempotent: true, tcp_nodelay: true)
        @connection_settings = @connection.data
        configure
      end

      # Configures client-specific options
      #
      # @param [Hash] cfg The configuration options to set.
      # @option cfg [Boolean] :dry_run When set to true, the client does not actually read/write to OpenTSDB.
      # @option cfg [String] :version The version of OpenTSDB to run against. Defaults to 2.0.
      def configure(cfg = {})
        @config = { dry_run: false, version: '2.0' }
        @valid_config_keys = @config.keys

        cfg.each do |key, value|
          key = key.to_sym
          @config[key] = value if @valid_config_keys.include?(key)
        end
      end

      # Basic check to see if the OpenTSDB is reachable
      #
      # @return [Boolean] true if call against api/version resolves
      def valid?
        @connection.get(path: 'api/version')
        true
      rescue Excon::Errors::SocketError, Excon::Errors::Timeout
        false
      end

      # Returns suggestions for metric or tag names
      #
      # @param [String] query The string to search for
      # @param [String] type The type to search for: 'metrics', 'tagk', 'tagv'
      #
      # @return [Array] an array of possible values based on the query/type
      def suggest(query, type = 'metrics', max = 25)
        return suggest_uri(query, type, max) if @config[:dry_run]
        JSON.parse(@connection.get(path: 'api/suggest', query: { type: type, q: query, max: max }).body)
      end

      # Returns the full URI for the suggest query in the context of this client.
      #
      # @param [String] query The string to search for
      # @param [String] type The type to search for: 'metrics', 'tagk', 'tagv'
      # @return [String] the URI
      def suggest_uri(query, type = 'metrics', max = 25)
        @client + "api/suggest?type=#{type}&q=#{query}&max=#{max}"
      end

      # Writes the specified Metric object to OpenTSDB.
      #
      # @param [Metric] metric The metric to write to OpenTSDB
      def write(metric)
        cmd = "echo \"put #{metric}\" | nc -w 30 #{@host} #{@port}"

        if @config[:dry_run]
          cmd
        else
          # Write into the db
          ret = system(cmd)

          # Command failed to run
          fail(IOError, "Failed to insert metric #{metric.name} with value of #{metric.value} into OpenTSDB.") unless ret
        end
      end

      # Runs the specified query against OpenTSDB. If config[:dry-run] is set to true or PNG format requested,
      # it will only return the URL for the query. Otherwise it will return a Result object.
      #
      # @param [Query] query The query object to execute with.
      # @return [Result || String] the results of the query
      def run_query(query)
        return query_uri(query) if @config[:dry_run] || query.format == :png
        Result.new(@connection.get(path: 'api/query', query: query.request))
      end

      # Returns the full URI for the query in the context of this client.
      #
      # @param [Query] query The query object
      # @return [String] the URI
      def query_uri(query)
        @client + 'api/query?' + query.as_graph
      end

      # Runs a synthetic query using queries against OpenTSDB. It expects a formula and a matching Hash which maps
      # parameters in the formula to time_series' query objects.
      #
      # @param name [String] the alias for this synthetic series
      # @param formula [String] the Dentaku calculator formula to use
      # @param query_hash [Hash] a Hash containing Query objects that map to corresponding parameters in the formula
      # @return [SyntheticResult] the calculated result of the formula
      def run_synthetic_query(name, formula, query_hash)
        results_hash = query_hash.map { |key, query| { key => run_query(query).results[0].fetch('dps') } }
        results_hash = results_hash.reduce do |results, result|
          results.merge(result)
        end

        SyntheticResult.new(name, formula, results_hash)
      end

      # Runs the specified queries against OpenTSDB in a HTTP pipelined connection.
      #
      # @param [Array] queries An array of queries to run against OpenTSDB.
      # @return [Array] a matching array of results for each query
      def run_queries(queries)
        # requests cannot be idempotent when pipelined, so we temporarily disable it
        @connection_settings[:idempotent] = false

        results = run_pipelined_request(queries)

        @connection_settings[:idempotent] = true
        results
      end

      private

      # Runs a series of queries in a pipelined, persistent HTTP request against OpenTSDB.
      #
      # @param [Array] queries Array of Query objects to run against OpenTSDB
      # @return [Array] corresponding Array of Result objects
      def run_pipelined_request(queries)
        wrapper = PipelineWrapper.new(@config, queries)
        responses = @connection.requests(wrapper.requests)
        responses.map { |response| Result.new(response) }
      end

      # Wraps pipelined requests and creates their individual HTTP requests against OpenTSDB
      class PipelineWrapper
        attr_reader :requests

        # Initializes the pipeline wrapper and sets up the Excon requests based on the queries.
        #
        # @param [Hash] config the client configuration
        # @param [Array] queries the Array of Query objects to execute
        def initialize(config, queries)
          @config = config
          @queries = queries
          @requests = @queries.map { |query| { method: :get, path: 'api/query', query: query.request } }
        end
      end
    end
  end
end
