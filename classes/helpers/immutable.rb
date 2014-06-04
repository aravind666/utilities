# class of Immutables which defines various immutables
# which are reused accross the application
#
# Author::    Aravind Udayashankara  (mailto:aravind.udayashankara@gmail.com)
# Copyright:: Copyright (c) 2012 Crossroads
# License::   MIT
#
# Immutables defined
# config : - Global configuration object
# log : - Logger object to log the file
# dbh :- database handler
#

class Immutable

  @dbh = false;

  class << self

    #
    # Selfie to get Config
    #
    def config
      RConfig.global;
    end

    #
    # Selfie to get logger
    #
    def log
      Logger.new('migration.log', 0, 100 * 1024 * 1024);
    end

    #
    # Selfie to get database handler
    #
    def dbh
      begin
        if (@dbh)
          return @dbh
        else
          return self.getconnection;
        end
      end
    end

    #
    # This method returns the connection handler
    # TODO : - Research on Persistance
    #
    def getconnection
      connection_string = 'DBI:Mysql:' + self.config.db_name + ':' + self.config.db_host;
      DBI.connect("#{connection_string}", self.config.db_user_name, self.config.db_password);
    rescue DBI::DatabaseError => e
      puts 'An error occurred while initializing DB handler check migration log for more details ';
      self.logger.error "Error code: #{e.err}";
      self.logger.error "Error message: #{e.errstr}";
    end

  end

end