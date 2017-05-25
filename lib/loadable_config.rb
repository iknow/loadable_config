require 'loadable_config/version'
require 'json_schema'
require 'yaml'
require 'singleton'

class LoadableConfig
  Attribute = Struct.new(:name, :type, :optional) do
    def initialize(name, type, optional)
      super(name.to_s, type.to_s, optional)
    end
  end

  class << self
    attr_reader :_attributes, :_config_file
  end

  def self.inherited(subclass)
    subclass.send(:include, Singleton)
  end

  def self.config_file(path)
    @_config_file = path
  end

  def self.attribute(attr, type: :string, optional: false)
    @_attributes ||= []
    _attributes << Attribute.new(attr, type, optional)
    attr_accessor attr

    singleton_class.instance_eval do
      define_method(attr) { self.class.send(attr) }
    end
  end

  def self.attributes(*attrs, type: :string, optional: false)
    attrs.each do |attr|
      attribute(attr, type: type, optional: optional)
    end
  end

  def initialize
    prefix = LoadableConfig::Options.config_path_prefix || ''
    subkey = LoadableConfig::Options.subkey || nil

    prefix.chomp('/').concat('/') unless prefix.empty?
    subkey = subkey.to_s          unless subkey.nil?

    if self.class._config_file.nil? || self.class._config_file.empty?
      raise RuntimeError.new("config_file not set")
    end

    config_file_path = "#{prefix}#{self.class._config_file}"

    unless File.exist?(config_file_path)
      raise RuntimeError.new("Cannot configure #{self.class.name}: configuration file '#{config_file_path}' missing")
    end

    full_config = YAML.load(File.open(config_file_path, "r"))

    if subkey
      config = full_config[subkey]
    else
      config = full_config
    end

    unless config
      raise RuntimeError.new("Cannot configure #{self.class.name}.")
    end

    valid, errors = _schema.validate(config)
    unless valid
      raise ArgumentError.new("Errors parsing #{self.class.name}:\n" +
                              errors.map { |e| "#{e.pointer}: #{e.message}" }.join("\n"))
    end

    self.class._attributes.each do |attr|
      self.public_send(:"#{attr.name}=", config[attr.name])
    end

    self.freeze
  end

  private

  def _schema
    JsonSchema.parse!(
      'type'                 => 'object',
      'description'          => "#{self.class.name} Configuration",
      'properties'           => self.class._attributes.each_with_object({}) do |attr, h|
                                  h[attr.name] = { 'type' => attr.type }
                                end,
      'required'             => self.class._attributes.reject(&:optional).map(&:name),
      'additionalProperties' => false
    )
  end

  class Options
    class << self
      attr_accessor :config_path_prefix, :subkey
    end
  end
end
