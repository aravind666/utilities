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
      Contenthelper.validate_content_destination_path;
      FileUtils.rm_rf(Dir.glob(Immutable.config.content_destination_path))
    rescue Errno::ENOENT => e
      Immutable.log.error "Folder does not exists, Its first run #{e}"
    end
  end

  #
  # Migration bootstrap
  #
  def migrate_content
    content_data = Contenthelper.get_content_from_database();
    self.process_content(content_data);
  end

  #
  # This method is used to process fetched content
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
  def build_content_based_on_status(content)
    db_file_path = Contenthelper.purify_file_path(content[1]);
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
       # Immutable.log.warn " - Source WebPage ID #{content['web_page_id']} does not exists at #{complete_source_path} "
    end
  end

  #
  # This method actually migrates the content by creating the front matter
  #
  def migrate_by_adding_jekyll_front_matter(complete_source_path, file_name, category_name, front_matter)

    source_file_handler = File.open(complete_source_path)
    data_to_migrate = source_file_handler.read();
    migrated_file_path = "#{Immutable.config.content_destination_path}/#{category_name}/#{file_name}";
    migrated_content_file_handler = File.open(migrated_file_path, 'w');
    migrated_content_file_handler.write(front_matter);
    data_to_migrate = Contenthelper.update_html_with_new_image_paths(data_to_migrate);
    Contenthelper.update_html_with_new_media_paths(data_to_migrate);
    migrated_content_file_handler.write(data_to_migrate);
  end


  #
  # This method is used to get jekyll front matter for a particular content
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