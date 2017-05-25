require "loadable_config"
RSpec.describe LoadableConfig do
  let(:config_class) do
    path = file_fixture('my_config.yml')

    Class.new(LoadableConfig) do
      attribute :number, type: :integer
      attributes :sizes, :counts, type: :integer
      attribute :name

      config_file path
    end
  end

  before(:all) { LoadableConfig::Options.subkey = "development" }

  it "stores a configuration file path" do
    expect(config_class._config_file).to eq file_fixture("my_config.yml")
  end

  it "can read an attribute" do
    expect(config_class.instance.number).to eq 1
  end

  context "production environment" do
    let(:config_class) do
      path = file_fixture('my_config.yml')

      Class.new(LoadableConfig) do
        attribute  :number, type: :integer
        attributes :sizes, :counts, type: :integer
        attribute  :name

        config_file path
      end
    end

    it "reads from the correct environment" do
      begin
        LoadableConfig::Options.subkey = "production"
        expect(config_class.instance.number).to eq 100
      ensure
        LoadableConfig::Options.subkey = "development"
      end
    end
  end

  context "missing config file" do
    let(:config_class) do
      Class.new(LoadableConfig) do
        attribute  :number, type: :integer
        attributes :sizes, :counts, type: :integer
        attribute  :name

        config_file "foobar"
      end
    end

    it "returns an error when accessing the instance" do
      expect { config_class.instance }.to raise_error(RuntimeError)
    end
  end

  context "no subkey" do
    let(:config_class) do
      path = file_fixture('top_level.yml')

      Class.new(LoadableConfig) do
        attribute  :number, type: :integer
        attribute  :name

        config_file path
      end
    end

    it "reads an attribute" do
      begin
        LoadableConfig::Options.subkey = nil
        expect { config_class.instance }.to raise_error(RuntimeError)
      ensure
        LoadableConfig::Options.subkey = "development"
      end
    end
  end

  context "with a default prefix" do
    let(:config_class) do
      path = @path

      Class.new(LoadableConfig) do
        attribute  :number, type: :integer
        attributes :sizes, :counts, type: :integer
        attribute  :name

        config_file path
      end
    end

    it "can read an attribute" do
      path = file_fixture("my_config.yml")
      prefix = path.slice(0,2)
      @path = path.slice(2, path.length-1)

      begin
        LoadableConfig::Options.config_path_prefix = prefix
        expect(config_class.instance.number).to eq 1
      ensure
        LoadableConfig::Options.config_path_prefix = ''
      end
    end

  end

  context "no config_file" do
    let(:config_class) do
      Class.new(LoadableConfig) do
        attribute  :number, type: :integer
        attributes :sizes, :counts, type: :integer
        attribute  :name
      end
    end

    it "returns an error when accessing the instance" do
      expect { config_class.instance }.to raise_error(RuntimeError)
    end
  end

  context "too few attributes" do
    let(:config_class) do
      path = file_fixture('my_config.yml')

      Class.new(LoadableConfig) do
        attribute  :number, type: :integer
        attributes :sizes, :counts, type: :integer

        config_file path
      end
    end

    it "returns an error when accessing the instance" do
      expect { config_class.instance }.to raise_error(ArgumentError)
    end
  end

  context "too many attributes" do

    let(:config_class) do
      path = file_fixture('my_config.yml')

      Class.new(LoadableConfig) do
        attribute  :number, type: :integer
        attributes :sizes, :counts, type: :integer
        attribute  :name
        attribute  :foobar

        config_file path
      end
    end

    it "returns an error when accessing the instance" do
      expect { config_class.instance }.to raise_error(ArgumentError)
    end
  end

  context "mistyped attribute" do

    let(:config_class) do
      path = file_fixture('my_config.yml')

      Class.new(LoadableConfig) do
        attribute  :number, type: :string
        attributes :sizes, :counts, type: :integer
        attribute  :name

        config_file path
      end
    end

    it "returns an error when accessing the instance" do
      expect { config_class.instance }.to raise_error(ArgumentError)
    end
  end

  context "bad subkey" do

    let(:config_class) do
      path = file_fixture('my_config.yml')

      Class.new(LoadableConfig) do
        attribute  :number, type: :integer
        attributes :sizes, :counts, type: :integer
        attribute  :name

        config_file path
      end
    end

    it "returns an error when accessing the instance" do
      begin
        LoadableConfig::Options.subkey = "foobar"
        expect { config_class.instance }.to raise_error(RuntimeError)
      ensure
        LoadableConfig::Options.subkey = "development"
      end
    end
  end
end

