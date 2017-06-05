[![Build Status](https://travis-ci.org/iknow/loadable_config.svg?branch=master)](https://travis-ci.org/iknow/loadable_config)

# LoadableConfig
LoadableConfig is a tool you can use to load and parse configuration
from YAML. It validates your declaration of the configuration against
the provided file and gives you a singleton to access configuration.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'loadable_config'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install loadable_config

## Usage

Subclass from LoadableConfig:

```ruby
class MyConfig < LoadableConfig
  attribute :size, type: :integer
  attribute :name # implictly a string

  config_file 'config/my_config.yml'
end
```

You can then access the configuration through the instance of the class:

`MyConfig.instance.size # => 3`

If you store configuration keyed by environment, or want to set a
project root for all subclasses, you can set global options:

```ruby
LoadableConfig::Options.subkey             = Rails.env.to_s
LoadableConfig::Options.config_path_prefix = Rails.root.to_s
```

Attributes are validated according to [JSON Schema](http://json-schema.org)

# Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/iknow/loadable_config.

