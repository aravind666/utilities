# content class which defines various attributes and behaviours which are used in
# migration
#
# Author::    Aravind Udayashankara  (mailto:aravind.udayashankara@gmail.com)
# Copyright:: Copyright (c) 2012 Crossroads
# License::   MIT
#
#
class Content

  #
  # Create Content object by initilizing the migration flow
  #
  def initialize
    self.clean_old_files();
    self.migrate_content();
  end

  #
  # This method clears old files by deleting the destination directory to recreate it
  #
  def clean_old_files
    begin
      self.validate_content_destination_path(Immutables.config.content_destination_path);
      FileUtils.rm_rf(Dir.glob(Immutables.config.content_destination_path))
    rescue Errno::ENOENT => e
      Immutables.log.error "Folder does not exists, Its first run #{e}"
    end

  end

  #
  # Migration bootstrap
  #
  def migrate_content
    content_data = self.get_content_from_database();
    self.process_content(content_data);
  end


  #
  # This method fetches content details from database
  #
  def get_content_from_database
    begin
      content_data = Immutables.dbh.execute("SELECT page_title, file_path, file_name, pc.category_name, pc.milacron_layout, mmp.migrate, mmp.web_page_id FROM web_page AS wp INNER JOIN page_category AS pc ON (wp.page_category_id = pc.page_category_id) INNER JOIN milacron_migrate_pages as mmp ON (wp.web_page_id = mmp.web_page_id and mmp.migrate = 'YES')");
      return content_data;
    rescue DBI::DatabaseError => e
      Immutables.log.error "Error code: #{e.err}"
      Immutables.log.error "Error message: #{e.errstr}"
      Immutables.log.error "Error SQLSTATE: #{e.state}"
      abort('An error occurred while getting data from DB, Check migration log for more details');
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
      Immutables.log.info "Completed Migration "
      abort("\n Migration process successfully completed, Please check migration.log \n");
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

    destination_dir = Immutables.config.content_destination_path
    unless File.directory?(destination_dir)
      FileUtils.mkdir_p(destination_dir)
    end

    dirname = Immutables.config.content_destination_path + '/' + category_name.gsub(/\s/,'-');
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
    destination_file_name = content[2];
    complete_source_path = Immutables.config.content_source_path + db_file_path + destination_file_name;
    category_name = content[3].gsub(/\s/,'-');
    status = File.file?(complete_source_path);
    case status
      when true
        self.setup_file_path(category_name);
        front_matter = get_jekyll_front_matter_for_content(content);
        self.migrate_by_adding_jekyll_front_matter(complete_source_path, destination_file_name, category_name, front_matter);
      when false
        Immutables.log.warn " - Source WebPage ID #{content['web_page_id']} does not exists at #{complete_source_path} "
    end
  end

  #
  # This method actually migrates the content by creating the front matter
  #
  def migrate_by_adding_jekyll_front_matter(complete_source_path, file_name, category_name,front_matter)
    source_file_handler = File.open(complete_source_path)
    data_to_migrate = source_file_handler.read();
    migrated_file_path = "#{Immutables.config.content_destination_path}/#{category_name}/#{file_name}";
    migrated_content_file_handler = File.open(migrated_file_path, 'w');
    migrated_content_file_handler.write(front_matter);
    # TODO : - Research not sure why this wont work in Mac system
    # data_to_migrate.delete!("\C-M");
    migrated_content_file_handler.write(data_to_migrate);
  end

  #
  # This method is used to get jekyll front matter for a particular content
  #
  def get_jekyll_front_matter_for_content(content)

    file_path = content[1];
    title = content[0].gsub(':','-');
    category = content[3].to_s;
    if file_path['shortlink']
      return "---\nlayout: #{content[4]}\ntitle: #{title}\ncategory: #{category}\npermalink: /#{content[2].gsub('.htm','');}/\n---\n"
    else
      return "---\nlayout: #{content[4]}\ntitle: #{title}\ncategory: #{category}\n---\n";
    end
  end

  #
  # This method removes file extension for files which are in shortlinks folder
  #
  def get_file_name_based_on_content_type(content)

    file_path = content[1];
    if file_path['shortlink']
      file_name = content[2];
      file_name.gsub('.htm','');
      return file_name;
    else
      return content[2];
    end
  end

  #
  # This method is used to check whether directory exists
  #
  def directory_exists?(directory)
    File.directory?(directory)
  end

  #
  # This methods validates destination ,
  # It checks if user has accidently set the destination path as source .
  # meaning if production documents path is set as destination,
  # script will clear all production files . To prevent this accident .
  # This method validates destination by checking if it has any directory which normally apears in
  # production documents folder .
  #
  # Including these tough checks because one day we will be running this script in
  # production environment .
  #
  def validate_content_destination_path(directory)
    pages_directory_path = directory+'pages'
    ajax_directory_path = directory+'ajax'
    admin_directory_path = directory+'admin'

    # Checking like this is wierd but still can prevent blunders :)
    if(directory_exists?(pages_directory_path))
      abort("Hey looks like you have set source directory as destination please review the configuration, \n Warning you to make sure that you dont clear your production files ");
    elsif(directory_exists?(ajax_directory_path))
      abort("Hey looks like you have set source directory as destination please review the configuration, \n Warning you to make sure that you dont clear your production files ");
    elsif(directory_exists?(admin_directory_path))
      abort("Hey looks like you have set source directory as destination please review the configuration, \n Warning you to make sure that you dont clear your production files ");
    else
      Immutables.log.info " - > Source and destination paths seems to be fine to proceed  ";
    end
  end

end