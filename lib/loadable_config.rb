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
    @_config_file = File.join(Rails.root, path)
  end

  def self.attribute(attr, type: :string, optional: false)
    @_attributes ||= []
    _attributes << Attribute.new(attr, type, optional)
    attr_accessor attr

    singleton_class.instance_eval do
      delegate attr, to: :instance
    end
  end

  def self.attributes(*attrs, type: :string, optional: false)
    attrs.each do |attr|
      attribute(attr, type: type, optional: optional)
    end
  end

  def initialize
    unless File.exist?(self.class._config_file)
      raise RuntimeError.new("Cannot configure #{self.class.name}: configuration file '#{self.class._config_file}' missing")
    end

    config = YAML.load(File.open(self.class._config_file, "r"))
    env_config = config[Rails.env.to_s]

    unless env_config
      raise RuntimeError.new("Cannot configure #{self.class.name}: no configuration defined for Rails environment #{Rails.env}")
    end

    valid, errors = _schema.validate(env_config)
    unless valid
      raise ArgumentError.new("Errors parsing #{self.class.name}:\n" +
                              errors.map { |e| "#{e.pointer}: #{e.message}" }.join("\n"))
    end

    self.class._attributes.each do |attr|
      self.public_send(:"#{attr.name}=", env_config[attr.name])
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
end
