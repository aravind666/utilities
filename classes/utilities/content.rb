# content class which defines various attributes and behaviours which are used in
# migration
#
# Author::    Aravind Udayashankara  (mailto:aravind.udayashankara@gmail.com)
# Copyright:: Copyright (c) 2012 Crossroads
# License::   MIT
#
# Instantiating this class leads to migration
#
class Content

  #
  # Create Content object by initializing the migration flow
  #
  def initialize
    self.clean_old_files();
    self.migrate_content();
  end

  #
  # This method clears old files by deleting the destination directory to recreate it
  #
  # * checks if the log files exists in the location and deletes only on exist
  # * validates the destination path
  # * if exists removes the directory
  # * logs the error message
  #
  # content.clean_old_files
  #
  def clean_old_files
    begin
      File.delete('pdfs_missing.log') if File.exist?('pdfs_missing.log');
      File.delete('mp3_missing.log') if File.exist?('mp3_missing.log');
      File.delete('mp4_missing.log') if File.exist?('mp4_missing.log');
      File.delete('docs_missing.log') if File.exist?('docs_missing.log');
      File.delete('everythingelse.log') if File.exist?('everythingelse.log');
      File.delete('php_links_in_milacron.log') if File.exist?('php_links_in_milacron.log');
      File.delete('mysend_links_in_milacron.log') if File.exist?('mysend_links_in_milacron.log');
      File.delete('missing_web_pages_from_source.log') if File.exist?('missing_web_pages_from_source.log');
      File.delete('unmigrated_web_pages.log') if File.exist?('unmigrated_web_pages.log');
      File.delete('unmigrated_shortlink_web_pages.log') if File.exist?('unmigrated_shortlink_web_pages.log');
      File.delete('web_page_not_exists_in_db.log') if File.exist?('web_page_not_exists_in_db.log');
      ContentHelper.validate_content_destination_path;
      FileUtils.rm_rf(Dir.glob(Immutable.config.content_destination_path))
      rescue Errno::ENOENT => e
      Immutable.log.error "Folder does not exists, Its first run #{e}"
    end
  end

  #
  # Migration bootstrap
  #
  # * gets all the content from the database
  # * sends for processing
  #
  def migrate_content
    content_data = ContentHelper.get_content_from_database();
    self.process_content(content_data);
  end

  #
  # This method is used to process fetched content
  #
  # * for each content process it for migration
  #
  # content.process_content(array)
  #
  def process_content(content)
    begin
      while row = content.fetch do
        self.build_content_based_on_status(row);
      end
      Immutable.log.info "Completed Migration "
      abort("\n Migration process successfully completed, Please check migration.log \n");
    end
  end

  #
  # This method is used to setup folders for category
  # and also the content directory,
  # It deletes the content directory if it exists and re creates it
  #
  # * create the destination path directory
  # * add the category name to the path
  #
  # content.setup_file_path('india')
  #
  def setup_file_path(category_name)

    destination_dir = Immutable.config.content_destination_path
    unless File.directory?(destination_dir)
      FileUtils.mkdir_p(destination_dir)
    end

    dirname = Immutable.config.content_destination_path + '/' + category_name.gsub(/\s/, '-');
    unless File.directory?(dirname)
      FileUtils.mkdir_p(dirname)
    end

  end

  #
  # This method initiates migration based on the
  # status of the content which is about to get migrated
  #
  # * check the status of the content
  # * if it is available in the directory then process
  # * if not log the web page id in the log file
  #
  # content.build_content_based_on_status(array)
  #
  def build_content_based_on_status(content)
    db_file_path = ContentHelper.purify_file_path(content[1]);
    destination_file_name = content[2];
    complete_source_path = Immutable.config.content_source_path + db_file_path + destination_file_name;
    category_name = content[3].gsub(/\s/, '-');
    status = File.file?(complete_source_path);
    case status
      when true
        self.setup_file_path(category_name);
        front_matter = get_jekyll_front_matter_for_content(content);
        self.migrate_by_adding_jekyll_front_matter(complete_source_path, destination_file_name, category_name, front_matter);
      when false
        Immutable.log.warn " - Source WebPage ID #{content['web_page_id']} does not exists at #{complete_source_path} "
    end
  end

  #
  # This method actually migrates the content by creating the front matter
  #
  # * open the source file and read them and process it to change the references
  # * open the migrate file write the front matter
  #
  # content.migrate_by_adding_jekyll_front_matter('_prodContent', 'medalli', 'india', 'string')
  #
  def migrate_by_adding_jekyll_front_matter(complete_source_path, file_name, category_name, front_matter)
    source_file_handler = File.open(complete_source_path)
    data_to_migrate = source_file_handler.read();
    migrated_file_path = "#{Immutable.config.content_destination_path}/#{category_name}/#{file_name}";
    migrated_content_file_handler = File.open(migrated_file_path, 'w');
    migrated_content_file_handler.write(front_matter);
    data_to_migrate = ContentHelper.update_html_with_new_image_paths(data_to_migrate);
    ContentHelper.log_various_href_sources(data_to_migrate);
    data_to_migrate = ContentHelper.update_html_with_new_media_hrefs(data_to_migrate);
    data_to_migrate = BlogHelper.update_html_with_milacron_href_in_content_posts(data_to_migrate.to_s);
    migrated_content_file_handler.write(data_to_migrate);
  end


  #
  # This method is used to get jekyll front matter for a particular content
  #
  # * add the required front matter if short link exists
  #
  # content.get_jekyll_front_matter_for_content(array)
  #
  def get_jekyll_front_matter_for_content(content)

    file_path = content[1];
    title = content[0].gsub(':', '-');
    category = content[3].to_s;
    if file_path['shortlink']
      return "---\nlayout: #{content[4]}\ntitle: #{title}\ncategory: #{category}\npermalink: /#{content[2].gsub('.htm', '');}/\n---\n"
    else
      return "---\nlayout: #{content[4]}\ntitle: #{title}\ncategory: #{category}\n---\n";
    end
  end

end
