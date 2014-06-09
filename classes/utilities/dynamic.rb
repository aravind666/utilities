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
  # Create Content object by initilizing the migration flow
  #
  def initialize
    self.migrate_dynamic_content();
  end

  #
  # Migration bootstrap
  #
  def migrate_dynamic_content
    links_to_migrate = Contenthelper.get_dynamic_links_to_migrate();
    self.process_links(links_to_migrate);
  end

  #
  # get content for each of the URLS and migrate
  #
  def process_links(links_to_migrate)
    links_to_migrate.each do |link|
      link = link.gsub("\n",'');
      response_from_content_url = Contenthelper.get_content_from_url(link);
      if (response_from_content_url)
        front_matter = self.get_jekyll_front_matter_for_content(link, response_from_content_url);
        content_to_migrate = self.get_content_body_to_migrate(response_from_content_url);
        Contenthelper.log_various_href_sources(content_to_migrate.to_s);
        content_to_migrate = Contenthelper.update_html_with_new_media_hrefs(content_to_migrate.to_s);
        target_file_location = self.setup_target_file_location(link);
        self.migrate_by_adding_jekyll_front_matter(target_file_location, front_matter, content_to_migrate);
      end
    end
    abort("Completed migrating dynamics links, please check migration log for links which returns 404 or 500");
  end

  #
  # Returns html part which needs to be migrated
  #
  def get_content_body_to_migrate(response)

    response.parser.css('img').each do |img|
      old_src = img.attribute('src').to_s;
      new_src = Contenthelper.replace_image_sources_with_new_paths(old_src);
      img['src'] = new_src;
    end



    if response.search('div#mainContent').nil?
      post_body = response.search('body');
    else
      post_body = response.search('div#mainContent');
    end
    return post_body;
  end

  #
  # This method returns target location to migrate
  #
  def setup_target_file_location(link)
    directory_path = self.get_complete_directory_path_to_migrate(link);
    file_name_to_migrate = get_complete_file_name_to_migrate(link);
    directory_to_migrate = self.setup_file_path_to_migrate(directory_path);
    target_file = directory_to_migrate + "/" + file_name_to_migrate;
    if(File.file?(target_file))
      Immutable.log.info "File already exists : #{link}"
      target_file['.htm'] = '-2.htm';
    end
    return target_file;
  end

  #
  # This method returns exact path
  # which needs to be recreated in migrated destination
  #
  def get_exact_filepath_from_url(file_path)
    return file_path.sub(/[a-zA-Z]/) { |s| s.upcase }
  end

  #
  # returns the complete filesystem path post migration
  #
  def get_complete_file_name_to_migrate(content_url)
    file_name_to_migrate = File.basename(content_url);
    file_name_to_migrate['.php'] = '.htm'
    return file_name_to_migrate;
  end

  #
  # This method returns directory name which needs to be
  # created at destination
  #
  def get_complete_directory_path_to_migrate(content_url)
    file_path = self.get_exact_filepath_from_url(content_url);
    directory_path = File.dirname(file_path);
    return directory_path;
  end

  #
  # Creates directory where we need to migrate
  #
  def setup_file_path_to_migrate(directory_path)
    dirname = Immutable.config.content_destination_path + '/' + directory_path;
    unless File.directory?(dirname)
      FileUtils.mkdir_p(dirname)
    end
    return dirname;
  end

  #
  # This method actually migrates the file by adding
  # Jekyll front matter .
  #
  def migrate_by_adding_jekyll_front_matter(target_file_location, front_matter, content_to_migrate)
    migrated_handler = File.open(target_file_location, 'w');
    migrated_handler.write(front_matter);
    migrated_handler.write(content_to_migrate);
    migrated_handler.close;
  end

  #
  # Returns jekyll front matter for content
  #
  def get_jekyll_front_matter_for_content(content_url, content)

    # Check if the page has title
    if content.title.nil?
      # if its null make filename as title .
      file_name_in_location = File.basename(content_url);
      title = file_name_in_location.chomp(File.extname(file_name_in_location));
      title = title.upcase;
    else
      title = content.title;
    end
    title = title.downcase;
    title[0] = title[0].capitalize

    # category is nothing but the parent folder
    # it is the standard followed in migrating managed content
    category = self.get_complete_directory_path_to_migrate(content_url);
    category_parts = category.split('/');
    return "---\nlayout: right_column \ntitle: \"#{title}\" \ncategory: \"#{category_parts[0]}\"\n---\n";
  end

end

