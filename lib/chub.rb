require 'rubygems'
require 'mongoid'
require 'uuid'

require 'yaml'


class Chub

  # This gem's version
  VERSION = '1.0.0'

  # Default file to load for config.
  DEFAULT_CONFIG_FILE = File.expand_path "~/.chub"

  # Default config to use.
  DEFAULT_CONFIG = {
    'user'  => `whoami`.strip,
    'mongo' => {
      'database'              => 'chub',
      'host'                  => 'localhost',
      'port'                  => 27017,
      'autocreate_indexes'    => false,
      'allow_dynamic_fields'  => true,
      'include_root_in_josn'  => true,
      'parameterize_keys'     => true,
      'persist_in_safe_mode'  => false,
      'raise_not_found_error' => true,
      'reconnect_time'        => 3
    }
  }


  def self.config
    @config ||= DEFAULT_CONFIG
  end


  def self.load_config file=DEFAULT_CONFIG_FILE
    @config = YAML.load_file DEFAULT_CONFIG_FILE
  end


  def self.configure_mongo mconf=nil
    mconf ||= Chub.config['mongo']

    Mongoid.configure do |config|
      config.from_hash mconf
    end
  end


  require 'chub/data_blamer'
  require 'chub/app_config'
end

module MongoSetup
  def self.setup
    Chub.configure_mongo

    Chub::AppConfig.destroy_all
    de = Chub::AppConfig.create_rev "app/default", "def1" => "defval1"
    ac = Chub::AppConfig.create_rev "app/dev", "key1" => "val1"
    ac = ac.create_rev "key2" => "val2"
    ac.include de
    ac = ac.create_rev "key3" => "val3"
  end
end

#MongoSetup.setup
