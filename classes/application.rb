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
  # Construct the application object
  #
  def initialize(command)

    # Start the log over whenever the log exceeds 100 megabytes in size.
    @logger = Logger.new('migration.log', 0, 100 * 1024 * 1024);
    @config = RConfig.global;
    self.main(command);
  end

  #
  # Main Function called on Application bootstrap
  #
  # * It validates commandline arguments passed
  # * Process tasks
  #
  def main(command_line_argument)
    self.validate_arguments(command_line_argument);
    self.process_commands(command_line_argument);

  end

  #
  # This method validates passed arguments from standard IO
  #
  # * Checks and aborts if command passed is invalid
  #
  def validate_arguments(command_line_argument)
    case command_line_argument
      when 'migrate-content'

        return;
      when 'migrate-media'
        puts (' - > This feature is not yet developed ');
        exit(false);
      else
        puts "you have passed #{command_line_argument} -- I have no idea what to do with that.";
        puts 'I know only to process the commands :  ,  migrate-content & migrate-media'
        @logger.error "Invalid command usage !"
        exit(false);
    end
  end

  #
  # This method clears old files by deleting the destination directory to recreate it
  #
  def clean_old_files
    begin
      FileUtils.remove_dir(@config.content_destination_path, force=false);
    rescue Errno::ENOENT => e
      @logger.error "Folder does not exists, Its first run #{e}"
    end

  end

  #
  # This will process the command passed by the enduser
  #
  #
  def process_commands(command_line_argument)
    case command_line_argument
      when 'migrate-content'
        self.clean_old_files();
        self.migrate_content();
      when 'migrate-media'
        puts (' - > This feature is not yet developed ');
        exit(false);
    end
  end

  #
  # Migration bootstrap
  #
  def migrate_content
    self.initialize_database_handler();
    content_data = self.get_content_from_database();
    self.process_content(content_data);
  end

  #
  # Initialize database handler
  #
  def initialize_database_handler
    begin
      connection_string = 'DBI:Mysql:' + @config.db_name + ':' + @config.db_host;
      @dbh = DBI.connect("#{connection_string}", @config.db_user_name, @config.db_password);

    rescue DBI::DatabaseError => e
      puts 'An error occurred while initializing DB handler check migration log for more details '
      @logger.error "Error code: #{e.err}"
      @logger.error "Error message: #{e.errstr}"
    end
  end

  #
  # This method fetches content details from database
  #
  def get_content_from_database
    begin
      content_data = @dbh.execute('SELECT page_title,file_path,file_name,pc.category_name,pc.milacron_layout
FROM web_page AS wp LEFT JOIN page_category AS pc ON wp.page_category_id = pc.page_category_id');
      return content_data;
    rescue DBI::DatabaseError => e
      puts 'An error occurred while getting data from DB, Check migration log for more details'
      @logger.error "Error code: #{e.err}"
      @logger.error "Error message: #{e.errstr}"
      @logger.error "Error SQLSTATE: #{e.state}"
    end
  end

  #
  # This method is used to process fetched content
  #
  def process_content(content)
    begin
      while row = content.fetch do
        self.build_content_based_on_status(row);
      end
      @logger.info "Completed Migration "
      abort('done');
    end
  end

  #
  # Some file paths are not in standard format hence this method is
  # USed to purify that
  #
  def purify_file_path(file_path)
    if file_path['//']
      file_path['//'] = '/'
    end
    return file_path
  end

  #
  # This method is used to setup folders for category
  # and also the content directory,
  # It deletes the content directory if it exists and re creates it
  #
  def setup_file_path(category_name)

    destination_dir = @config.content_destination_path
    unless File.directory?(destination_dir)
      FileUtils.mkdir_p(destination_dir)
    end

    dirname = @config.content_destination_path + '/' + category_name;
    unless File.directory?(dirname)
      FileUtils.mkdir_p(dirname)
    end

  end

  #
  # This method initiates migration based on the
  # status of the content which is about to get migrated
  #
  def build_content_based_on_status(content)

    db_file_path = self.purify_file_path(content[1]);
    complete_source_path = @config.content_source_path + db_file_path + content[2];
    category_name = content[3];
    status = File.file?(complete_source_path);
    case status
      when true
        self.setup_file_path(category_name);
        front_matter = get_jekyll_front_matter_for_content(content);
        self.migrate_by_adding_jekyll_front_matter(complete_source_path, content[2], category_name, front_matter);
      when false
        @logger.warn " - > Source File Does Not Exists #{complete_source_path} "
    end
  end

  #
  # This method actually migrates the content by creating the front matter
  #
  def migrate_by_adding_jekyll_front_matter(complete_source_path, file_name, category_name, front_matter)
    source_file_handler = File.open(complete_source_path)
    data_to_migrate = source_file_handler.read();
    migrated_file_path = "#{@config.content_destination_path}/#{category_name}/#{file_name}";
    migrated_content_file_handler = File.open(migrated_file_path, 'w');
    migrated_content_file_handler.write(front_matter);
    data_to_migrate.delete!("\C-M");
    migrated_content_file_handler.write(data_to_migrate);
  end

  #
  # This method is used to get jekyll front matter for a particular content
  #
  def get_jekyll_front_matter_for_content(content)

    file_path = content[1];
    title = content[0].gsub(':','-')
    if file_path['shortlink']
      file_name = content[2];
      file_name['.htm']= '';
      return "---\nlayout: #{content[4]}\ntitle: #{content[0]}\ncategory: #{content[3]}\npermalink: #{file_name}\n---\n"
    else
      return "---\nlayout: #{content[4]}\ntitle: #{content[0]}\ncategory: #{content[3]}\n---\n";
    end
  end


end