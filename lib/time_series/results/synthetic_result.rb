# -*- encoding: utf-8 -*-

require 'dentaku'

module Opower
  module TimeSeries
    # Provides support for synthetic metrics
    class SyntheticResult
      attr_reader :results, :data

      # Initializes a synthetic results wrapper and runs the calculations on the results data.
      #
      # @param name [String] - alias for this synthetic series
      # @param formula [String] - the formula used to calculate data together
      # @param data [Hash] - a hash containing key mappings to results to be used in the formula
      def initialize(name, formula, data)
        @name = name
        @formula = formula
        @data = data
        @results = {}
        @calculator = TimeSeriesCalculator.new

        calculate
      end

      # Calculates the result of the formula set for this synthetic result. Currently, the timestamps
      # of each of the queries must match in order for a calculation to be performed.
      def calculate
        formula_map = FormulaMap.new(@data)

        formula_map.parameters.each do |ts, parameter|
          @results[ts] = @calculator.evaluate(@formula, parameter)
        end
      end

      # Gives the total results size after calculating synthetic metrics.
      #
      # @return [Integer] the number of data-points
      def length
        @results.keys.length
      end

      # Subclass of Dentaku's calculator - adds math functions by default
      class TimeSeriesCalculator < Dentaku::Calculator
        def initialize
          super
          initialize_math_functions
        end

        # Initializes math functions provided by Ruby and places them into the calculator as functions.
        # NOTE: You must wrap nested mathematical expressions in formulas or Dentaku will attempt to pass them
        # as separate arguments into the lambda below!
        # This method smells of :reek:NestedIterators
        #
        # For example:
        # Assume x = 1, y = 2
        # cos(x + y) is translated into cos(1, 'add', 2) - this calls Math.cos(1, 'add', 2)
        # cos((x + y)) is translated into cos(3) - this correctly calls Math.cos(3)
        def initialize_math_functions
          Math.methods(false).each do |method|
            math_method = Math.method(method)
            add_function(
                name: method,
                type: :numeric,
                signature: [:numeric],
                body: ->(*args) { math_method.call(*args) }
            )
          end
        end
      end

      # Merges all matching data point timestamps together and assigns their values to formula keys
      class FormulaMap
        attr_reader :parameters

        # Initializes the formula map using the set of results received from OpenTSDB.
        #
        # @param [Hash] data A hash mapping formula parameters to OpenTSDB results
        def initialize(data)
          @data = data
          @parameters = {}

          @data[@data.keys.sample].each_key do |ts|
            build_hash(ts)
          end
        end

        # Checks each of the keys in the data provided to see if they contain a data-point at the
        # specified timestamp. Does nothing if any of the keys is missing a data-point.
        #
        # @param [String] ts the OpenTSDB timestamp to check (yes, it's a String from OpenTSDB)
        def build_hash(ts)
          result = @data.map { |key, dps| { key => dps[ts] } if dps.key?(ts) }
          return if result.include?(nil)

          @parameters[ts] = result.reduce do |formula_map, parameter|
            formula_map.merge(parameter)
          end
        end
      end
    end
  end
end
