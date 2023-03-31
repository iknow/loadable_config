# frozen_string_literal: true

class LoadableConfig::Options
  attr_reader :config_path_prefix, :environment_key, :preprocessor, :overlay_function

  def initialize
    # Prefix for configuration file paths. Must be a valid directory, for
    # example `Rails.root`. If unset, configuration files are resolved relative
    # to the current working directory.
    @config_path_prefix = nil

    # If set, assumes that all LoadableConfig configuration files are structured
    # with top-level keys specifying different environments, each of which is a
    # hash of the configuration attributes. Setting this specifies which top
    # level key to select. For example, `Rails.env`.
    @environment_key     = nil

    # If set, uses the provided block to preprocess the configuration file
    # before YAML parsing.
    @preprocessor        = nil

    # If set, calls the provided block with the configuration class after
    # parsing to obtain a configuration overlay. If a value is returned, it is
    # deep_merged into the application.
    @overlay_function    = nil
  end

  def config_path_prefix=(val)
    unless File.directory?(val)
      raise ArgumentError.new("Config path prefix '#{val}' is not a valid directory")
    end

    @config_path_prefix = File.expand_path(val)
  end

  def environment_key=(val)
    @environment_key = val.to_s
  end

  def preprocess(&block)
    @preprocessor = block
  end

  def overlay(&block)
    @overlay_function = block
  end
end
