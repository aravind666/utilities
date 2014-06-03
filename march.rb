# Application bootstrap
# Migration march starts from the execution of this script
#
# Author::    Aravind Udayashankara  (mailto:aravind.udayashankara@gmail.com)
# Copyright:: Copyright (c) 2012 Crossroads
# License::   MIT
#
# It requires all necessary gems and does little ground work before migration
#
#


# rconfig is used to read configuration from files
require 'rconfig';

# dbi gem is used as an interface to talk to DB
require 'dbi';

# required for pathname
require 'pathname'

# require File Utils
require 'fileutils';

# required for logging
require 'logger';

# requireed for opening URL in content_migration
require 'mechanize';

# Delete the log file during a fresh run
# FileUtils.rm('migration.log');
File.delete('migration.log') if File.exist?('migration.log');

# Load Configuration path to Rconfig to look for configuration
CONFIG_DIRECTORY = File.dirname(__FILE__) + '/config/';
RConfig.load_paths = [CONFIG_DIRECTORY];
RConfig.add_config_path(CONFIG_DIRECTORY);

# Requiring all helper classes
Dir[File.dirname(__FILE__) + '/classes/helpers/*.rb'].each { |file| require file }

# Requiring all utility classes
Dir[File.dirname(__FILE__) + '/classes/utilities/*.rb'].each { |file| require file }

# Requiring all classes in the classes directory
Dir[File.dirname(__FILE__) + '/classes/*.rb'].each { |file| require file }

# Bootstrap the application
app = Application.new(ARGV[0]);
