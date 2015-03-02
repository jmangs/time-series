# Fixtures wrapper - contains raw data used by webmocks
module Fixtures
  def self.fixture(filename)
    File.expand_path("../fixtures/#{filename}", __FILE__)
  end

  def self.read_file(filename)
    IO.read(fixture(filename))
  end

  BAD_METRIC = read_file('errors/no_metric.json')
  BAD_TAGK = read_file('errors/no_tag_key.json')
  SUGGEST_SYS = read_file('suggest/sys.json')
  SYS_ALLOCATION = read_file('query/sys.numa.allocation.json')
  SYS_ALLOC_RATE = read_file('query/sys.numa.allocation.rate.json')
  SYS_ZONE_ALLOCS = read_file('query/sys.numa.zoneallocs.json')
end
