# BqQuery

Bigquery client for only executing query

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'bq_query'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install bq_query

## Usage

### Example

```
require 'bq_query'

opts = {}
opts['service_email'] = '1234@developer.gserviceaccount.com'
opts['key']           = '/path/to/somekeyfile-privatekey.p12'
opts['project_id']    = '54321'
opts['dataset']       = 'yourdataset'

bq = BqQuery::Client.new(opts)

bq.sql("SELECT * FROM [project:dataset.example_table] LIMIT 100")
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/YuheiNakasaka/bq_query.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
