# Application bootstrap class definition
#
# Author::    Aravind Udayashankara  (mailto:aravind.udayashankara@gmail.com)
# Copyright:: Copyright (c) 2012 Crossroads
# License::   MIT
#
# This class works as a bootstrap which sets up the platform
# For any process based on the user input .
#
#

class Application

  #
  # This methods initialize the application by validating
  # command line arguments passed and starts processing
  #
  # *command_line_argument* - Commandline input arguments
  #
  def initialize(command_line_argument)
    self.validate_arguments(command_line_argument);
    self.process_commands(command_line_argument);
  end

  #
  # This method validates passed arguments from standard IO
  #
  # *command_line_argument* - Commandline input arguments
  #
  def validate_arguments(command_line_argument)

    available_utilities = Immutable.routes
    if available_utilities.has_key?(command_line_argument)
      return;
    else
      available_commands = "\n";
      available_utilities.each do |key, value|
        available_commands += "#{key} \n"
      end
      puts "You have passed #{command_line_argument} -- I have no idea what to do with that."
      puts "I know only to process the commands :  #{available_commands}"
      Immutable.log.error "Invalid command usage !"
      exit(false);
    end
  end

  #
  # This will process the command passed by the enduser
  #
  # *command_line_argument* - Commandline input arguments
  #
  def process_commands(command_line_argument)
    available_utilities = Immutable.routes
    utility_class = available_utilities[command_line_argument];
    Object.const_get(utility_class).new
  end
end
