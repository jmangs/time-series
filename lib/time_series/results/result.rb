# -*- encoding: utf-8 -*-

module Opower
  module TimeSeries
    # Wraps the OpenTSDB result with response codes and result counts
    class Result
      attr_reader :status, :length, :results, :error_message

      # Takes the Excon response from OpenTSDB and parses it into the desired format.
      #
      # @param [Response] response The Excon response object
      def initialize(response)
        @status = response.status
        @length = 0
        data = response.body

        parse_results(data)
      end

      # Checks if the status code is not a 2XX HTTP response code.
      #
      # @return [Boolean] true if an error occurred
      def errors?
        @status.to_s !~ /^2/
      end

      private

      # Parses the results from OpenTSDB
      #
      # @param [String] data HTTP Response Body
      def parse_results(data)
        @results = JSON.parse(data)
        @length = @results.length

        @error_message = @results['error']['message'] if errors? && @length > 0
      end
    end
  end
end
