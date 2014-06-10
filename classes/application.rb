# Application bootstrap class definition
#
# Author::    Aravind Udayashankara  (mailto:aravind.udayashankara@gmail.com)
# Copyright:: Copyright (c) 2012 Crossroads
# License::   MIT
# This class works as a bootstrap which sets up the platform
# For any process based on the user input .
#
#

class Application

  #
  # Do things when application is instantiated
  #
  def initialize(command_line_argument)
    self.validate_arguments(command_line_argument);
    self.process_commands(command_line_argument);
  end

  #
  # This method validates passed arguments from standard IO
  #
  # Checks and aborts if command passed is invalid
  #
  def validate_arguments(command_line_argument)
    # TODO : - Aravind :  Make this as config and validate commands from YAML
    # This has to be done post integration with Rspec in future .
    #
    case command_line_argument
      when 'migrate-content'
        return;
      when 'migrate-messages'
        return;
      when 'migrate-audios'
        return;
      when 'migrate-videos'
        return;
      when 'migrate-blog'
        return;
      when 'migrate-dynamic-content'
        return;
      when 'crawl-for-links'
        return;
      else
        puts "you have passed #{command_line_argument} -- I have no idea what to do with that.";
        puts "I know only to process the commands :  ,  \nmigrate-content \nmigrate-messages \nmigrate-videos \nmigrate-audios \nmigrate-dynamic-content\nmigrate-blog";
        Immutable.log.error "Invalid command usage !"
        exit(false);
    end
  end

  #
  # This will process the command passed by the enduser
  #
  def process_commands(command_line_argument)
    case command_line_argument
      when 'migrate-content'
        Content.new;
      when 'migrate-messages'
        Message.new;
      when 'migrate-audios'
        Audio.new;
      when 'migrate-videos'
        Video.new;
      when 'migrate-blog'
        Blog.new;
      when 'migrate-dynamic-content'
        Dynamic.new;
      when 'crawl-for-links'
        Crawler.new;
    end
  end
end
