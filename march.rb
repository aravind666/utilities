# rconfig is used to read configuration from files
require 'rconfig'

# dbi gem is used as an interface to talk to DB
require 'dbi'

# require File Utils
require 'fileutils'

# required for logging
require 'logger'

# Requiring all classes in the classes directory
Dir[File.dirname(__FILE__) + '/classes/*.rb'].each { |file| require file }

# Initialize Configuration

CONFIG_DIRECTORY = File.dirname(__FILE__) + '/config/';
RConfig.load_paths = [CONFIG_DIRECTORY];
RConfig.add_config_path(CONFIG_DIRECTORY);


# Bootstrap the application
app = Application.new(ARGV[0]);
