require "loadable_config"
require "spec_helper"

RSpec.describe LoadableConfig do

  let(:path) { file_fixture('top_level_config.yml') }

  let(:config_class) do
    path = self.path
    Class.new(LoadableConfig) do
      attribute  :number, type: :integer
      attribute  :text

      config_file path
    end
  end

  it "reads an attribute from an unkeyed file" do
    expect(config_class.number).to eq(200)
  end

  it "stores a configuration file path" do
    expect(config_class._config_file).to eq file_fixture("top_level_config.yml")
  end

  context "with environment keying" do
    let(:path) { file_fixture('env_config.yml') }

    let(:config_class) do
      path = self.path
      Class.new(LoadableConfig) do
        attribute :number, type: :integer
        attributes :sizes, :counts, type: :integer
        attribute :text

        config_file path
      end
    end

    before(:each) do
      environment = self.environment
      LoadableConfig.configure! do |config|
        config.environment_key = environment
      end
    end

    after(:each) do
      LoadableConfig.send(:_reinitialize_configuration!)
    end

    context "for development" do
      let(:environment) { :development }

      it "reads from the correct environment" do
        expect(config_class.instance.number).to eq 1
      end
    end

    context "for production" do
      let(:environment) { :production }

      it "reads from the correct environment" do
        expect(config_class.instance.number).to eq 100
      end
    end

    context "but an invalid key" do
      let(:environment) { :does_not_exist }

      it "raises an error when accessing the instance" do
        expect { config_class.instance }
          .to raise_error(RuntimeError, /Configuration missing for environment/)
      end
    end
  end

  context "with a missing config file" do
    let(:path) { "nonexistent_file" }

    it "returns an error when accessing the instance" do
      expect { config_class.instance }.to raise_error(RuntimeError, /configuration file.*missing/)
    end
  end

  context "with a path prefix" do
    # Test by slicing apart the basename and filename
    let(:path_parts) do
      File.split(file_fixture('top_level_config.yml'))
    end

    let(:prefix) { path_parts.first }
    let(:path) { path_parts.last }

    before(:each) do
      LoadableConfig.configure! do |config|
        config.config_path_prefix = prefix
      end
    end

    after(:each) do
      LoadableConfig.send(:_reinitialize_configuration!)
    end

    it "can read an attribute" do
      expect(config_class.number).to eq 200
    end
  end

  context "no config_file set" do
    let(:config_class) do
      Class.new(LoadableConfig) do
        attribute  :number, type: :integer
        attributes :sizes, :counts, type: :integer
        attribute  :text
      end
    end

    it "raises an error when accessing the instance" do
      expect { config_class.instance }.to raise_error(RuntimeError, /config_file not set/)
    end
  end

  context "config file missing attribute" do
    let(:config_class) do
      path = self.path
      Class.new(LoadableConfig) do
        attribute :number, type: :integer
        attribute :text
        attribute :missing_attr, type: :integer

        config_file path
      end
    end

    it "returns an error when accessing the instance" do
      expect { config_class.instance }.to raise_error(ArgumentError, /missing_attr/)
    end
  end

  context "config file has too many attributes" do
    let(:config_class) do
      path = self.path
      Class.new(LoadableConfig) do
        attribute  :number, type: :integer

        config_file path
      end
    end

    it "returns an error when accessing the instance" do
      expect { config_class.instance }.to raise_error(ArgumentError, /text/)
    end
  end

  context "config file has attribute with incorrect type" do
    let(:config_class) do
      path = self.path
      Class.new(LoadableConfig) do
        attribute  :number, type: :string
        attribute  :text

        config_file path
      end
    end

    it "returns an error when accessing the instance" do
      expect { config_class.instance }.to raise_error(ArgumentError, /number/)
    end
  end
end

