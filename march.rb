# rconfig is used to read configuration from files
require 'rconfig'

# dbi gem is used as an interface to talk to DB
require 'dbi'

# require File Utils
require 'fileutils'


# Requiring all classes in the classes directory
Dir[File.dirname(__FILE__) + '/classes/*.rb'].each { |file| require file }

# Initialize Configuration

CONFIG_DIRECTORY = File.dirname(__FILE__) + '/config/';
RConfig.load_paths = [CONFIG_DIRECTORY];
RConfig.add_config_path(CONFIG_DIRECTORY);


# Bootstrap the application
app = Application.new(ARGV[0]);

#
#begin
#  # connect to the MySQL server
#  dbh = DBI.connect("DBI:Mysql:crossroadsdotnet:localhost", "root", "root")
#  # get server version string and display it
#  sth = dbh.execute("SELECT * FROM web_page");
#  sth.fetch do |row|
#    printf "Title: %s\t, FilePath: %s\n", row[3], row[5]
#  end
#  sth.finish
#
#rescue DBI::DatabaseError => e
#  puts "An error occurred"
#  puts "Error code: #{e.err}"
#  puts "Error message: #{e.errstr}"
#ensure
#  # disconnect from server
#  dbh.disconnect if dbh
#end

#
#
#a = Content.new();
#
#CONFIG_DIRECTORY = File.dirname(__FILE__) + '/config/';
#
#
#RConfig.load_paths = [CONFIG_DIRECTORY]
#
#puts CONFIG_DIRECTORY;
#
#RConfig.add_config_path(CONFIG_DIRECTORY);
#puts "RConfig.global[:admin_email] => #{RConfig.global[:admin_email]}";
#puts "RConfig.global.listen_ip => #{RConfig.global.listen_ip}";
#puts a.inspect