# dynamic class which defines various attributes and behaviours which are used in
# migrate dynamic content from crossroads legacy system
#
# Author::    Aravind Udayashankara  (mailto:aravind.udayashankara@gmail.com)
# Copyright:: Copyright (c) 2012 Crossroads
# License::   MIT
#
# Instantiating this class leads to migration
#
class Dynamic

  #
  # Initializing the dynamic content migration process
  #
  def initialize
    self.migrate_dynamic_content
  end

  # Public: gets the dynamic links from config file
  #
  # Returns dynamic links array
  #
  def migrate_dynamic_content
    links_to_migrate = ContentHelper.get_dynamic_links_to_migrate
    self.process_links(links_to_migrate)
  end

  # Public: gets the content for each link
  #
  # get content for each of the URLS and migrate
  #
  # *links_to_migrate* - Array of links to process
  #
  # Return success message
  #
  def process_links(links_to_migrate)
    links_to_migrate.each do |link|
      link = link.gsub("\n", '')
      response_from_content_url = ContentHelper.get_content_from_url(link)
      if response_from_content_url
        front_matter = self.get_jekyll_front_matter_for_content(link, response_from_content_url)
        content_to_migrate = self.get_content_body_to_migrate(response_from_content_url)
        ContentHelper.log_various_href_sources(content_to_migrate.to_s)
        content_to_migrate = ContentHelper.update_html_with_new_media_hrefs(content_to_migrate.to_s)
        content_to_migrate = BlogHelper.update_html_with_milacron_href_in_content_posts(content_to_migrate.to_s);
        target_file_location = self.setup_target_file_location(link)
        self.migrate_by_adding_jekyll_front_matter(target_file_location, front_matter, content_to_migrate)
      end
    end
    abort('Completed migrating dynamics links, please check migration log for links which returns 404 or 500')
  end

  # Public: gets contents from html document
  #
  # *response* - String response from the dynamic link
  #
  # Returns html part which needs to be migrated
  #
  def get_content_body_to_migrate(response)
    response.parser.css('img').each do |img|
      old_src = img.attribute('src').to_s
      new_src = ContentHelper.replace_image_sources_with_new_paths(old_src)
      img['src'] = new_src;
    end

    response = ContentHelper.remove_unwanted_paragraph(response.to_s)
    response = Nokogiri::HTML(response);
    if response.search('div#mainContent').nil?
      post_body = response.search('body')
    else
      post_body = response.search('div#mainContent')
    end
    post_body
  end

  # Public: sets target file location
  #
  # *link* - String used to get the target file location
  #
  # Returns target file location to migrate
  #
  def setup_target_file_location(link)
    directory_path = self.get_complete_directory_path_to_migrate(link)
    file_name_to_migrate = get_complete_file_name_to_migrate(link)
    directory_to_migrate = self.setup_file_path_to_migrate(directory_path)
    target_file = directory_to_migrate.downcase + '/' + file_name_to_migrate.downcase
    if File.file?(target_file)
      Immutable.log.info "File already exists : #{link}"
      target_file['.htm'] = '-2.htm'
    end
    target_file
  end

  # Public: validates file path
  #
  # *file_path* - String file path
  #
  # This method returns exact path
  # which needs to be recreated in migrated destination
  # Returns absolute file path
  #
  def get_exact_filepath_from_url(file_path)
    file_path.sub(/[a-zA-Z]/) { |s| s.downcase }
  end

  # Public: used to get file name
  #
  # *content_url* - String file name
  #
  # Returns the complete filesystem path post migration
  #
  def get_complete_file_name_to_migrate(content_url)
    file_name_to_migrate = File.basename(content_url)
    file_name_to_migrate['.php'] = '.htm'
    file_name_to_migrate.downcase;
  end

  # Public: used to get directory path
  #
  # *content_url* - String file name
  #
  # Returns directory name which needs to be
  # created at destination
  #
  def get_complete_directory_path_to_migrate(content_url)
    file_path = self.get_exact_filepath_from_url(content_url)
    directory = File.dirname(file_path)
    return directory.downcase
  end

  #
  # Public: Creates directory where we need to migrate
  #
  # *directory_path* - String file name
  #
  # Returns directory name
  #
  def setup_file_path_to_migrate(directory_path)
    dirname = Immutable.config.content_destination_path + '/' + directory_path
    unless File.directory?(dirname)
      FileUtils.mkdir_p(dirname)
    end
    dirname
  end

  #
  # Public: actually migrates the file by adding
  # Jekyll front matter
  #
  # *target_file_location* - String target file location
  # *front_matter* - String front matter to write to file
  # *content_to_migrate* - String content to migrate
  #
  # Return file by writing the message content front matter to the given destination path
  #
  def migrate_by_adding_jekyll_front_matter(target_file_location, front_matter, content_to_migrate)
    migrated_handler = File.open(target_file_location, 'w')
    migrated_handler.write(front_matter)
    migrated_handler.write(content_to_migrate)
    migrated_handler.close
  end

  #
  # Public: creates jekyll front matter for content
  #
  # *content_url* - String content url
  # *content* - String content to migrate
  #
  # Returns jekyll front matter for content
  #
  def get_jekyll_front_matter_for_content(content_url, content)
    # Check if the page has title
    if content.title.nil?
      # if its null make filename as title
      file_name_in_location = File.basename(content_url)
      title = file_name_in_location.chomp(File.extname(file_name_in_location))
      title = title.upcase
    else
      title = content.title
    end
    title = title.downcase
    title[0] = title[0].capitalize
    # category is nothing but the parent folder
    # it is the standard followed in migrating managed content
    category = self.get_complete_directory_path_to_migrate(content_url)
    category_parts = category.split('/')
    category_name = category_parts[0];

    "---\nlayout: right_column \ntitle: \"#{title}\" \ncategory: \"#{category_name.downcase}\"\n---\n"
  end

end
