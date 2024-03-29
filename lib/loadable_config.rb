# frozen_string_literal: true

require 'loadable_config/version'
require 'loadable_config/options'
require 'json_schema'
require 'yaml'
require 'singleton'

class LoadableConfig
  Attribute = Struct.new(:name, :type, :schema, :optional, :serializer, :default)

  class << self
    attr_reader :_attributes, :_config_file

    def inherited(subclass)
      super
      subclass.send(:include, Singleton)
    end

    def config_file(path)
      @_config_file = path
    end

    def attribute(attr, type: :string, schema: {}, serializer: nil, default: nil, optional: !default.nil?)
      @_attributes ||= []
      attr = attr.to_sym
      if ATTRIBUTE_BLACKLIST.include?(attr)
        raise ArgumentError.new("Illegal attribute name '#{attr}': "\
                                'attributes must not collide with class methods of LoadableConfig')
      end

      type = [type] unless type.is_a?(Array)
      type.map! { |t| t.to_s }

      _attributes << Attribute.new(attr.to_s, type, schema, optional, serializer, default)
      attr_accessor attr

      define_singleton_method(attr) { instance.send(attr) }
    end

    def attributes(*attrs, type: :string, optional: false, serializer: nil)
      attrs.each do |attr|
        attribute(attr, type: type, optional: optional, serializer: serializer)
      end
    end

    def _configuration
      @@_configuration
    end

    def configure!
      if @@_configuration.frozen?
        raise ArgumentError.new('Cannot configure LoadableConfig: already configured')
      end

      yield(@@_configuration)
      @@_configuration.freeze
    end

    private

    def _reinitialize_configuration!
      @@_configuration = LoadableConfig::Options.new
    end
  end

  _reinitialize_configuration!

  ATTRIBUTE_BLACKLIST = Set.new(self.methods - Object.instance_methods)

  def initialize
    if self.class._config_file.nil? || self.class._config_file.empty?
      raise RuntimeError.new("Incomplete LoadableConfig '#{self.class.name}': config_file not set")
    end

    config_file_path = self.class._config_file

    if (prefix = LoadableConfig._configuration.config_path_prefix)
      config_file_path = File.join(prefix, config_file_path)
    end

    unless File.exist?(config_file_path)
      raise RuntimeError.new("Cannot configure #{self.class.name}: "\
                             "configuration file '#{config_file_path}' missing")
    end

    config_data = File.read(config_file_path)

    if (preprocessor = LoadableConfig._configuration.preprocessor)
      config_data = preprocessor.call(config_data)
    end

    config = YAML.safe_load(config_data, aliases: true)
    unless config
      raise RuntimeError.new("Cannot configure #{self.class.name}: "\
                             "Configuration file empty for #{self.class.name}.")
    end

    if (env = LoadableConfig._configuration.environment_key)
      config = config.fetch(env) do
        raise RuntimeError.new("Cannot configure #{self.class.name}: "\
                               "Configuration missing for environment '#{env}'")
      end
    end

    if (overlay_function = LoadableConfig._configuration.overlay_function)
      overlay_data = overlay_function.call(self.class)
      config = _deep_merge(config, overlay_data) if overlay_data
    end

    unless config
      raise RuntimeError.new("Configuration file missing config for #{self.class.name}.")
    end

    valid, errors = _schema.validate(config)
    unless valid
      raise ArgumentError.new("Errors parsing #{self.class.name}:\n" +
                              errors.map { |e| "#{e.pointer}: #{e.message}" }.join("\n"))
    end

    self.class._attributes.each do |attr|
      if config.has_key?(attr.name)
        value = config[attr.name]
        if attr.serializer
          value = attr.serializer.load(value)
        end
      else
        value = attr.default
      end

      self.public_send(:"#{attr.name}=", value)
    end

    self.freeze
  end

  private

  def _schema
    JsonSchema.parse!(
      'type'                 => 'object',
      'description'          => "#{self.class.name} Configuration",
      'properties'           => self.class._attributes.each_with_object({}) do |attr, h|
                                  h[attr.name] = { 'type' => attr.type }.merge!(attr.schema)
                                end,
      'required'             => self.class._attributes.reject(&:optional).map(&:name),
      'additionalProperties' => false,
    )
  end

  def _deep_merge(a_hash, b_hash)
    a_hash.merge(b_hash) do |_key, a_val, b_val|
      if a_val.is_a?(Hash) && b_val.is_a?(Hash)
        _deep_merge(a_val, b_val)
      else
        b_val
      end
    end
  end
end
