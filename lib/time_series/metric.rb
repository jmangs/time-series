# -*- encoding: utf-8 -*-

module Opower
  module TimeSeries
    # Represents a metric that can be inserted into OpenTSDB instance through a [TSDBClient] object.
    class Metric
      attr_reader :name, :value, :timestamp, :tags

      # Initializer for the Metric class.
      #
      # @param [Hash] config configuration hash consisting of the following values:
      # @option config [String] :name The metric name (required)
      # @option config [String] :value The metric value (required)
      # @option config [String, Integer, Timestamp] :timestamp The timestamp in either epoch or a TimeStamp object.
      # @option config [Array] :tags Array of tags to set for this metric. (tag_key => value)
      #
      # @return [Metric] a new Metric object
      def initialize(config = {})
        validate(config, [:name, :value])

        @name = config[:name]
        @value = config[:value]
        @timestamp = config[:timestamp] ||  Time.now.to_i
        @tags = config[:tags] || {}
      end

      # Converts the metric into the format required for use by `put` to insert into OpenTSDB.
      #
      # @return [String] put string
      def to_s
        result = ''
        # Format the string for OpenTSDB
        @tags.each { |key, value| result += "#{key}=#{value} " }
        [@name, @timestamp, @value, result.rstrip].join(' ')
      end

      private

      # Validates the metric inputs
      #
      # @param [Hash] config The configuration to validate.
      # @param [Array] required_fields The required fields to be set inside the configuration.
      def validate(config = {}, required_fields)
        # Required fields check
        required_fields.each do |field|
          next if config.include?(field)
          fail(ArgumentError, "#{field} is required to write into OpenTSDB.")
        end

        # Reject if user provided timestamp as not numeric
        timestamp = config[:timestamp]
        fail(ArgumentError, 'Timestamp must be numeric') if timestamp && !(timestamp.is_a? Fixnum)
      end
    end
  end
end
