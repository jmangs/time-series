## TimeSeries

TimeSeries is a Ruby Gem for OpenTSDB that provides core tools when working with an OpenTSDB data store. With TimeSeries, you can search for registered metrics, tag keys and tag values, read from and write to the OpenTSDB, and submit multiple simultaneous queries to an OpenTSDB cluster.

### Installation

Download the Gem from a standard Gem server like rubygems.org and install it:

    gem install time_series

Alternatively, build it from source and install it:

    git clone https://github.com/opower/time-series.git
    cd time-series
    gem build time_series.gemspec
    gem install time_series-4.0.0.gem

### Usage
Once you have the OpenTSDB cluster set up, we can configure the TimeSeries Gem to talk to the API. The first step would be configuring a TimeSeries client. If no host is specified, the client connects to localhost by default. The client connects to port 4242 by default.

#### Configuring a TimeSeries Client

```ruby
client = Opower::TimeSeries::TSClient.new('opentsdb.foo.com', 4242)
client.configure({ :version => '2.0', :dry_run => false, :validation => true })
```

Here is a table that lists options supported by the TimeSeries client:

| Option | Type | Description| Default value |
| ------------- | ------------- | ------------- | ------------- |
| :version | Float | version of the OpentSDB cluster the client will be talking to.  If you wish to use the new 2.0 endpoints, set version to 2.0 or higher. | 2.0 |
| :dry_run | Boolean | If set to true, this gem will not run any commands, only output the generated URLs or calls to OpenTSDB. | false |
| :validation | Boolean | With this flag set to true, client performs a check to validate the metric name.  | false | 

#### Search for a registered metric/tagk/tagv

Using a properly configured client, you can search an OpenTSDB cluster to find suggestions for a metric, tag key, or tag value. This employs the `/api/suggest` end point of the OpenTSDB API and works as a simple namespace search. It is useful when you do not know what metric labels are being written to the OpenTSDB.

```ruby
client.suggest('proc.stat.cpu') # suggest a metric
client.suggest('proc.stat.cpu', 'tagk') # suggest a tagk
client.suggest('proc.stat.cpu', 'tagv') # suggest a tagv
```

#### Writing to OpenTSDB

You can use a TimeSeries client to push telnet/netcat style writes to OpenTSDB. If no hostname and port are specified, this gem defaults to 127.0.0.1:4242. To insert a metric into OpenTSDB using a configured client, create a new `Metric` object first and then use the `client.write` call as shown below :

```ruby
metric_config = {
        :name => 'proc.stat.cpu',
        :timestamp => Time.now.to_i,
        :value => 10,
        :tags => {:host => 'somehost.foo.com', :type => 'iowait'}
}

metric = Opower::TimeSeries::Metric.new(metric_config)
client.write(metric)
```


#### Reading from OpenTSDB

We can use a TimeSeries client to read metric data from an OpenTSDB cluster. To read data from OpenTSDB, you would first create a query object to run against the specified client. This query object supports all the standard options in the 2.0 API. Here is an example :

```ruby
query_config = {
        :format => :png,
        :start => '2013/01/01-01:00:00',
        :end => '2013/02/01-01:00:00',
        :m => [{ :aggregator => 'sum', :metric => 'proc.stat.cpu', :tags => {:type => 'iowait'} }],
        :nocache => true
}

query = Opower::TimeSeries::Query.new(query_config)
client.run_query(query)
```

The `Query` object accepts the following parameters:


| Option | Type | Description| Default value |
| ------------- | ------------- | ------------- | ------------- |
| :format | String | Specifies the output format. supported values include : `ascii`, `json`, `png`. | 'json' |
| :start | `String` / `Integer` / `DateTime` | The query's start date/time expressed as '2013/01/01-01:00:00' (string), '5m-ago' (String, indicating data for last 5 minutes), 1232323232 (time since epoch, Integer) or as a Ruby DateTime object. This is a required field. | none | 
| :end | `String` / `Integer` / `DateTime` | The query's end date. This field supports the same types as `:start` field. This field is optional | Time.now (current time) |
| :m | `Array` | Array of JSON objects with the `aggregator`, `metrics`, and `tags` as fields: | none |

Here is a sample metrics object , that goes into the :m object .
```ruby
:m => [{ :aggregator => 'sum', :metric => 'proc.stat.cpu', :tags => {:type => 'iowait', :version => 2.1} }]
```

Other options available to the REST API can be used here as well. Here is a list of options that have been tested to work with this gem. See the [OpenTSDB documentation](http://opentsdb.net/http-api.html#/q_Parameters) for more information :

```

 # * o       Rendering options.
 # * wxh     The dimensions of the graph.
 # * yrange  The range of the left Y axis.
 # * y2range The range of the right Y axis.
 # * ylabel  Label for the left Y axis.
 # * y2label Label for the right Y axis.
 # * yformat Format string for the left Y axis.
 # * y2formatFormat string for the right Y axis.
 # * ylog    Enables log scale for the left Y axis.
 # * y2log   Enables log scale for the right Y axis.
 # * key     Options for the key (legend) of the graph.
 # * nokey   Removes the key (legend) from the graph.
 # * nocache Forces TSD to ignore cache and fetch results from HBase.

```



#### Example Queries

```ruby
query_config = {
        :format => :ascii,
        :start => 14535353,
        :end => 16786786,
        :m => [{ :aggregator => 'sum', :metric => 'proc.stat.cpu', :rate => true, :tags => {:type => 'iowait'} }]
}

query = Opower::TimeSeries::Query.new(query_config)
client.run_query(query)
```

```ruby
query_config = {
        :format => :json,
        :start => '3m-ago',
        :m => [{ :aggregator => 'max', :metric => 'proc.stat.cpu', :tags => {:type => 'iowait'} }],
        :nocache => true
}

query = Opower::TimeSeries::Query.new(query_config)
client.run_query(query)
```

#### Running Multiple Queries Simultaneously

If you need to query multiple metrics at the same time, TimeSeries provides support for that as well:

```ruby
queries = []
3.times do
    query_config = {
            :format => :ascii,
            :start => 14535353,
            :end => 16786786,
            :m => [{ :aggregator => 'sum', :metric => 'proc.stat.cpu', :rate => true, :tags => {:type => 'iowait'} }]
    }

    queries << Opower::TimeSeries::Query.new(query_config)
end

client.run_queries(queries)
```

#### Running Synthetic Metric Queries

Sometimes, you might need to create a new time series using metrics data from existing time series. We call these 'Synthetic Metric Queries'. Some examples could be disk utilization (expressed as disk used/total disk available) or CPU itilization (expressed as cpu cycles used/total cpu cycles).

TimeSeries also provides the capability to create synthetic metric queries through the use of a formula and any number of queries against OpenTSDB. Here is an example that creates a formula which adds two time series ( `x + y` ) and feeds the calculation with data from OpenTSDB :

```ruby
metric_x = [{ metric: 'sys.numa.allocation', tags: { host: 'somehost.foo.com' } }]
query_config_x = { format: :json, start: '1h-ago', m: metric_x }
@query_metric_x = Opower::TimeSeries::Query.new(query_config_x)

metric_y = [{ metric: 'sys.numa.foreign_allocs', tags: { host: 'somehost.foo.com' } }]
query_config_y = { format: :json, start: '1h-ago', m: metric_y }
@query_metric_y = Opower::TimeSeries::Query.new(query_config_y)

name = 'My Synthetic Metric Alias'
formula = 'x + y'
query_hash = { x: @query_metric_x, y: @query_metric_y }
client.run_synthetic_query(name, formula, query_hash)
```

The above example illustrates how you pass in a hash object to the client in order to run a sythentic query. This also indicates how the key maps to the parameters in the formula, with their corresponding values consisting of a Query object. When the calculation is performed, it will only operate on matching timestamps. If there are no matching data-points, it will return nothing.

For more information about what can be done with the formula parameters, read the documentation for the [Dentaku Calculator](https://github.com/rubysolo/dentaku). This gem expects any parameter in the formula to have a matching query in the query hash.

##### Built-in Ruby Math support

```ruby
name = 'My Synthetic Metric Alias'
formula = 'cos(x) + y'
query_hash = { x: @query_metric_x, y: @query_metric_y }
client.run_synthetic_query(name, formula, query_hash)
```

Formulas in time-series can use all of the basic methods provided by the Math module from Ruby.

You must wrap nested mathematical expressions in formulas or Dentaku will attempt to pass them as separate arguments into the lambda below!

For example:
Assume x = 1, y = 2
 - cos(x + y) is translated into cos(1, 'add', 2) - this calls Math.cos(1, 'add', 2) - this obviously throws an error
 - cos((x + y)) is translated into cos(3) - this correctly calls Math.cos(3)

This is due to the way Dentaku handles the order of precedence; unless you wrap nested arguments, it will pass them separately.

#### Testing time_series

Test cases should be added for any new code added to this project.

Run acceptance/unit tests locally:

```
rake spec
```

Running integration tests:
```
docker pull opower/opentsdb
rake integration
```

Integration tests requires you have a `Docker` installed and have ran `docker pull opower/opentsdb` before-hand.

#### Generating Documentation

To generate the documentation for this gem, run the following:

```
yard doc
```
