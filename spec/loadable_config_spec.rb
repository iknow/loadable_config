# frozen_string_literal: true

require "loadable_config"
require "spec_helper"
require "tempfile"

RSpec.describe LoadableConfig do
  def self.letblk(name, &proc)
    let(name) { proc }
  end

  let(:text) { "Baz" }

  let(:config_data) do
    {
      "text" => text
    }
  end

  letblk(:attributes) do
    attribute :text
  end

  let(:data_file) do
    file = Tempfile.new
    file.write(YAML.dump(config_data))
    file.rewind
    file
  end

  let(:data_file_path) { data_file.path }

  let(:config_class) do
    attributes = self.attributes
    path = data_file_path
    Class.new(LoadableConfig) do
      instance_exec(&attributes)
      config_file path
    end
  end

  it "stores a configuration file path" do
    expect(config_class._config_file).to eq data_file.path
  end

  it "reads an attribute" do
    expect(config_class.text).to eq(text)
  end

  context "with nil config data" do
    let(:text) { nil }

    it "returns an error when accessing the instance" do
      expect { config_class.instance }.to raise_error(ArgumentError, /nil is not a/)
    end
  end

  context "with config data missing an attribute" do
    let(:config_data) { {} }

    it "returns an error when accessing the instance" do
      expect { config_class.instance }.to raise_error(ArgumentError, /wasn't supplied/)
    end
  end

  context "with config data including unknown attributes" do
    let(:config_data) { super().merge("unknown" => 1) }

    it "returns an error when accessing the instance" do
      expect { config_class.instance }.to raise_error(ArgumentError, /is not a permitted/)
    end
  end

  context "using 'attributes' multi-setter" do
    let(:config_data) do
      {
        "text1" => "Foo",
        "text2" => "Bar"
      }
    end

    letblk(:attributes) do
      attributes :text1, :text2
    end

    it "reads an attribute" do
      expect(config_class.text2).to eq("Bar")
    end
  end

  context "with typed attributes" do
    let(:number) { 1000 }

    let(:config_data) do
      {
        "number" => number
      }
    end

    letblk(:attributes) do
      attribute :number, type: :integer
    end

    it "reads an attribute" do
      expect(config_class.number).to eq(number)
    end

    context "provided as the incorrect type" do
      let(:number) { "100" }

      it "returns an error when accessing the instance" do
        expect { config_class.instance }.to raise_error(ArgumentError, /number/)
      end
    end
  end

  context "with complex typed attributes" do
    let(:object) do
      {
        "number" => 1,
        "string" => "cat"
      }
    end

    letblk(:attributes) do
      attribute :object, type: :object, schema: {
                  'additionalProperties' => false,
                  'properties' => {
                    'number' => { 'type' => 'integer' },
                    'string' => { 'type' => 'string' }
                  },
                  'required' => ['number', 'string']
                }
    end

    let(:config_data) do
      {
        "object" => object
      }
    end

    it "reads an attribute" do
      expect(config_class.object).to eq(object)
    end

    context "provided as the incorrect type" do
      let(:object) do
        {
          "unknown" => 1,
          "string" => 3
        }
      end

      it "returns an error when accessing the instance" do
        expect { config_class.instance }.to raise_error(ArgumentError, /is not a/)
      end
    end
  end

  context "with optional attributes" do
    letblk(:attributes) do
      attribute :text, optional: true
    end

    it "reads an attribute" do
      expect(config_class.text).to eq(text)
    end

    context "not provided" do
      let(:config_data) { {} }

      it "reads a missing optional attribute as nil" do
        expect(config_class.text).to eq(nil)
      end
    end
  end

  context "with environment keying" do
    before(:each) do
      environment = self.environment
      LoadableConfig.configure! do |config|
        config.environment_key = environment
      end
    end

    after(:each) do
      LoadableConfig.send(:_reinitialize_configuration!)
    end

    let(:config_data) do
      {
        "development" => {
          "text" => "dev"
        },
        "production" => {
          "text" => "prod"
        }
      }
    end

    context "for development" do
      let(:environment) { :development }

      it "reads from the correct environment" do
        expect(config_class.text).to eq("dev")
      end
    end

    context "for production" do
      let(:environment) { :production }

      it "reads from the correct environment" do
        expect(config_class.text).to eq("prod")
      end
    end

    context "for a missing enviroment" do
      let(:environment) { :does_not_exist }

      it "raises an error when accessing the instance" do
        expect { config_class.instance }
          .to raise_error(RuntimeError, /Configuration missing for environment/)
      end
    end
  end

  context "with a missing config file" do
    let(:data_file_path) { "nonexistent_file" }

    it "returns an error when accessing the instance" do
      expect { config_class.instance }.to raise_error(RuntimeError, /configuration file.*missing/)
    end
  end

  context "with a path prefix" do
    # Test by slicing apart the basename and filename
    let(:path_parts) do
      File.split(data_file.path)
    end

    let(:prefix) { path_parts.first }
    let(:data_file_path) { path_parts.last }

    before(:each) do
      LoadableConfig.configure! do |config|
        config.config_path_prefix = prefix
      end
    end

    after(:each) do
      LoadableConfig.send(:_reinitialize_configuration!)
    end

    it "can read an attribute" do
      expect(config_class.text).to eq(text)
    end
  end

  context "with no config_file set" do
    let(:config_class) do
      Class.new(LoadableConfig) do
        attribute :text
      end
    end

    it "raises an error when accessing the instance" do
      expect { config_class.instance }.to raise_error(RuntimeError, /config_file not set/)
    end
  end
end
