# encoding: ASCII-8BIT

# Content Helper class definition, which defines several helper
# classes for content migration
#
# Author::    Aravind Udayashankara  (mailto:aravind.udayashankara@gmail.com)
# Copyright:: Copyright (c) 2012 Crossroads
# License::   MIT
#
# All behaviours exhibited here are selfies you do not need an object to call them
#
class Contenthelper

  class << self

    # Public static: used to check whether directory exists
    #
    # *directory* - String directory name
    #  Returns bool
    def directory_exists?(directory)
      File.directory?(directory)
    end

    #
    # Public static: used to purify the file path
    #
    # *file_path* - String file path
    #
    # Returns file path
    #
    def purify_file_path(file_path)
      if file_path['//']
        file_path['//'] = '/'
      end
      file_path
    end

    #
    # Public static: fetches content details from DB
    #
    # Return DB result set
    #
    def get_content_from_database
      begin
        content_data = Immutable.dbh.execute("SELECT page_title, file_path, file_name, pc.category_name, pc.milacron_layout, mmp.migrate, mmp.web_page_id FROM web_page AS wp INNER JOIN page_category AS pc ON (wp.page_category_id = pc.page_category_id) INNER JOIN milacron_migrate_pages as mmp ON (wp.web_page_id = mmp.web_page_id and mmp.migrate = 'YES')");
        return content_data
      rescue DBI::DatabaseError => e
        Immutable.log.error "Error code: #{e.err}"
        Immutable.log.error "Error message: #{e.errstr}"
        Immutable.log.error "Error SQLSTATE: #{e.state}"
        abort('An error occurred while getting data from DB, Check migration log for more details')
      end
    end

    #
    # Public static: removes file extension from file name
    #
    # *file_name* - String file name
    #
    # Returns file name without file extension
    #
    def remove_file_extension_from_filename(file_name)
      file_name.chomp(File.extname(file_name))
    end

    #
    # Public static: removes all special characters from the string
    #
    # *string_to_remove* - string to remove special characters
    #
    # Returns String
    #
    def remove_all_special_characters_from_string(string_to_remove)
      string_to_remove.gsub!(/[^0-9A-Za-z]/, '')
    end

    #
    # Public static: validates destination file path
    #
    # It checks if user has accidently set the destination path as source
    # meaning if production documents path is set as destination,
    # script will clear all production files . To prevent this accident
    # This method validates destination by checking if it has any directory which normally appears in
    # production documents folder
    # Including these tough checks because one day we will be running this script in
    # production environment
    #
    # Returns nothing
    #
    def validate_content_destination_path
      directory = Immutable.config.content_destination_path
      pages_directory_path = directory+'pages'
      ajax_directory_path = directory+'ajax'
      admin_directory_path = directory+'admin'
      # Checking like this is wierd but still can prevent blunders :)
      if directory_exists?(pages_directory_path)
        abort("Hey looks like you have set source directory as destination please review the configuration, \n Warning you to make sure that you dont clear your production files ")
      elsif directory_exists?(ajax_directory_path)
        abort("Hey looks like you have set source directory as destination please review the configuration, \n Warning you to make sure that you dont clear your production files ")
      elsif directory_exists?(admin_directory_path)
        abort("Hey looks like you have set source directory as destination please review the configuration, \n Warning you to make sure that you dont clear your production files ")
      else
        Immutable.log.info '-> Source and destination paths seems to be fine to proceed'
      end
    end

    #
    # Public static: validates destination file path
    #
    # Thanks to Dan Rye for giving this beautiful thing
    # This method replaces junk characters with alternative symbols
    # The list has been given from Dan in case if you need to update this
    # Please contact Dan Rye <drye@crossroads.net> before doing so
    #
    # *string_to_purify* - String to purify
    #
    # Returns purified string
    #
    def purify_by_removing_special_characters(string_to_purify)
      replacements = []
      replacements << ['â€¦', '…'] # elipsis
      replacements << ['â€“', '–'] # long hyphen
      replacements << ['â€”', '–'] # long hyphen
      replacements << ['â€™', '’'] # curly apostrophe
      replacements << ['â€œ', '“'] # curly open quote
      replacements << [/â€[[:cntrl:]]/, '”'] # curly close quote
      replacements << [':', '&#58;'] # escape colon
      replacements << ['\C-M', ''] # remove unwanted control m chars
      replacements << ['Â', ''] # remove nbsp character
      replacements << ['"', '\\"'] # escape quotes
      replacements.each { |set| string_to_purify = string_to_purify.gsub(set[0], set[1]) }
      string_to_purify
    end

    #
    # Public static: removes special characters
    # from the title, its used for naming files using titles
    #
    # *title* - String to remove special characters
    #
    # Returns string
    #
    def purify_title_by_removing_special_characters(title)
      replacements = []
      replacements << [' ', '-']
      replacements << ['/', '-']
      replacements << ['?', '']
      replacements << ['*', '']
      replacements << ['#', '']
      replacements << ['@', '']
      replacements << ['&', '-and-']
      replacements << ['...', '']
      replacements << [/'/, '']
      replacements << [/"/, '']
      replacements << ['|', '']
      replacements << [':', '']
      replacements << ['.', '']
      replacements.each { |set| title = title.gsub(set[0], set[1]) }
      title
    end

    #
    # Public static: escapes special characters from the given URL string
    #
    # *url* - String url
    #
    # Return encoded url string
    #
    def encode_url_string(url)
      URI.escape(url)
    end

    #
    # Public static: gets the links to migrate from file
    #
    # Returns array of links
    #
    def get_dynamic_links_to_migrate
      file_with_migrate_link_list = Immutable.config.dynamic_links_list
      list_of_links_to_migrate = []
      File.open(file_with_migrate_link_list) do |links|
        links.each do |link|
          list_of_links_to_migrate << link.to_s
        end
      end
      list_of_links_to_migrate
    end

    #
    # Public static: does an http request to the URL
    #
    # *content_base_url* - String url to send request
    #
    # Return http response or bool
    #
    def get_content_from_url(content_base_url)
      begin
        content_url = Immutable.config.dynamic_link_base_url + '/' + content_base_url
        crawler = Mechanize.new
        response = crawler.get(content_url)
        return response
      rescue Mechanize::ResponseCodeError => exp
        Immutable.log.error "URL - #{content_url} Error details #{exp.inspect}"
        return false
      end
    end

    #
    # Public static: replaces image sources with new S3 bucket url
    #
    # *source* - String image src (legacy system image path)
    #
    # Return new S3 bucket url
    #
    def replace_image_sources_with_new_paths(source)
      source = source.gsub("https://www.crossroads.net/", '/')
      source = source.gsub("http://www.crossroads.net/", '/')
      if !source['http://']
        replacements = []
        replacements << ["uploadedfiles", "content"]
        replacements << ["images/uploadedImages/GOMamelodi", "content"]
        replacements << ["images/uploadedImages/boxes/New Folder", "content"]
        replacements << ["images/uploadedImages/boxes/New%20Folder", "content"]
        replacements << ["images/uploadedImages/boxes", "content"]
        replacements << ["images/uploadedImages/buttons", "content"]
        replacements << ["images/uploadedImages/banners", "content"]
        replacements << ["images/uploadedImages/3500 Madison", "content"]
        replacements << ["images/uploadedImages/3500%20Madison", "content"]
        replacements << ["images/uploadedImages", "content"]
        replacements << ["img/icn", "content"]
        replacements << ["img/tabs", "content"]
        replacements.each { |set| source = source.gsub(set[0], set[1]) }
        source = Immutable.config.s3url+ source
      end
      source
    end

    #
    # Public static: adds slash in the beginning of file name
    #
    # *file_path* - String file name
    #
    # Return file name with trailing slash
    #
    def add_trailing_slash_if_it_doesnot_exists(file_path)
      file_path << '/' if file_path[0] != '/'
      file_path
    end

    #
    # Public static: updates image paths
    # with the migrated path by Parsing the content
    #
    # *data_to_migrate* - String data which needs to updated image references
    #
    # Returns new image src
    #
    def update_html_with_new_image_paths(data_to_migrate)
      doc_to_migrate = Nokogiri::HTML(data_to_migrate)
      doc_to_migrate.css('img').each do |img|
        old_src = img.attribute('src').to_s
        new_src = Contenthelper.replace_image_sources_with_new_paths(old_src)
        img['src'] = new_src
      end
      doc_to_migrate.to_s
    end

    #
    # Public static: updates anchor paths
    # with the migrated path by Parsing the content
    #
    # *data_to_migrate* - String data which needs to updated href references
    #
    # Returns new href src
    #
    def update_html_with_new_media_hrefs(data_to_migrate)
      doc_to_migrate = Nokogiri::HTML(data_to_migrate)
      doc_to_migrate.css('a').each do |a|
        href = a.attribute('href').to_s
        new_href = Contenthelper.update_href(href)
        a['href'] = new_href
      end
      return doc_to_migrate.to_s
    end

    #
    # Public static: logs various src references to a file
    # by reading media content migrated content
    #
    # *data_to_migrate* - String data which needs to process and
    # log various references
    #
    # Returns various log file
    #
    def log_various_href_sources(data_to_migrate)
      doc_to_migrate = Nokogiri::HTML(data_to_migrate)
      doc_to_migrate.css('a').each do |a|
        old_src = a.attribute('href').to_s
        old_src.gsub('http://www.crossroads.net/', '/')
        if old_src['http://'] || old_src['https://'] || old_src['itpc://'] || old_src['mailto:'] || old_src['.jpg']
          Immutable.log.info " - > #{ old_src } -- we do not to do any thing with this since its external"
        elsif old_src['.pdf']
          File.open("pdfs_missing.log", 'a+') { |f| f.write(old_src + "\n") }
        elsif old_src['.mp3']
          File.open("mp3_missing.log", 'a+') { |f| f.write(old_src + "\n") }
        elsif old_src['.mp4']
          File.open("mp4_missing.log", 'a+') { |f| f.write(old_src + "\n") }
        elsif old_src['.doc']
          File.open("docs_missing.log", 'a+') { |f| f.write(old_src + "\n") }
        elsif old_src[/^#.+/]
          Immutable.log.info " - > #{ old_src } -- we do not need this since it is just hash tag"
        elsif old_src['.php']
          File.open("php_links_in_milacron.log", 'a+') { |f| f.write(old_src + "\n") }
        elsif old_src['mysend/']
          File.open("mysend_links_in_milacron.log", 'a+') { |f| f.write(old_src + "\n") }
        elsif !old_src.empty?
          File.open("everythingelse.log", 'a+') { |f| f.write(old_src + "\n") }
        end
      end
    end

    #
    # Public static: changes all href with new S3 bucket url
    #
    # *href* - String href src (legacy system href path)
    #
    # Return new S3 bucket url
    #
    def update_href(href)
      href.gsub('http://www.crossroads.net/', '/')
      replacements = []
      if href['http://'] || href['https://']
        Immutable.log.info " - > #{ href } -- we do not to do any thing with this since its external"
      elsif href['.pdf']
        replacements << ["uploadedfiles", "pdf"]
        replacements << ["images/uploadedImages", "pdf"]
      elsif href['.mp3']
        replacements << ["players/media/hq/320", "mp3"]
        replacements << ["uploadedfiles", "mp3"]
      elsif href['.doc']
        replacements << ["uploadedfiles", "docs"]
        replacements << ["images/uploadedImages", "docs"]
      elsif href['.jpg']
        replacements << ["uploadedfiles", "content"]
        replacements << ["images/uploadedImages", "content"]
      end
      replacements.each { |set| href = href.gsub(set[0], set[1]) }
      if !replacements.empty?
        href = Immutable.config.s3media + href
      end
       href
    end

    #
    # Public static: copies required images for blog to respective folder
    #
    # *old_src* - String file path to copy
    #
    # Returns nothing
    #
    def copy_required_blog_images_to_folder(old_src)
      old_src.gsub('http://www.crossroads.net/', '/')
      if old_src['http://']
        Immutable.log.info " - > #{ old_src } we do not need this file"
      else
        file_to_copy = Immutable.config.legacy_htdocs_path + old_src
        status = File.file?(file_to_copy);
        case status
          when true
            FileUtils.cp(file_to_copy, 'blogimages/')
          when false
            Immutable.log.info " - > #{ file_to_copy } does not exists"
        end
      end
    end
  end
end
