# encoding: ASCII-8BIT

# Content Helper class definition, which defines several helper
# classes for content migration
#
# Author::    Aravind Udayashankara  (mailto:aravind.udayashankara@gmail.com)
# Copyright:: Copyright (c) 2012 Crossroads
# License::   MIT
#
# All behaviours exhibitted here are selfies you donot need an object to call them
#
#

class Contenthelper

  class << self

    #
    # This method is used to check whether directory exists
    #
    def directory_exists?(directory)
      File.directory?(directory)
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
    # This method fetches content details from database
    #
    def get_content_from_database
      begin
        content_data = Immutable.dbh.execute("SELECT page_title, file_path, file_name, pc.category_name, pc.milacron_layout, mmp.migrate, mmp.web_page_id FROM web_page AS wp INNER JOIN page_category AS pc ON (wp.page_category_id = pc.page_category_id) INNER JOIN milacron_migrate_pages as mmp ON (wp.web_page_id = mmp.web_page_id and mmp.migrate = 'YES')");
        return content_data;
      rescue DBI::DatabaseError => e
        Immutable.log.error "Error code: #{e.err}"
        Immutable.log.error "Error message: #{e.errstr}"
        Immutable.log.error "Error SQLSTATE: #{e.state}"
        abort('An error occurred while getting data from DB, Check migration log for more details');
      end
    end

    #
    # This method removes file Extension from file name
    #
    def remove_file_extension_from_filename(file_name)
      name = file_name.chomp(File.extname(file_name));
      return name;
    end

    #
    # This method removes all special characters from the string
    #
    def remove_all_special_characters_from_string(string_to_remove)
      return string_to_remove.gsub!(/[^0-9A-Za-z]/, '');
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
    def validate_content_destination_path

      directory = Immutable.config.content_destination_path;

      pages_directory_path = directory+'pages'
      ajax_directory_path = directory+'ajax'
      admin_directory_path = directory+'admin'

      # Checking like this is wierd but still can prevent blunders :)
      if (directory_exists?(pages_directory_path))
        abort("Hey looks like you have set source directory as destination please review the configuration, \n Warning you to make sure that you dont clear your production files ");
      elsif (directory_exists?(ajax_directory_path))
        abort("Hey looks like you have set source directory as destination please review the configuration, \n Warning you to make sure that you dont clear your production files ");
      elsif (directory_exists?(admin_directory_path))
        abort("Hey looks like you have set source directory as destination please review the configuration, \n Warning you to make sure that you dont clear your production files ");
      else
        Immutable.log.info " - > Source and destination paths seems to be fine to proceed  ";
      end
    end

    #
    # Thanks to Dan Rye for giving this beatiful thing
    # This method replaces junk characters with alternative symbols
    # The list has been given from Dan in case if you need to update this
    # Please contact Dan Rye <drye@crossroads.net> before doing so
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
      return string_to_purify
    end

    #
    # This method removes special characters
    # from the title, its used for naming files using titles
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
      return title
    end

    #
    # This method escapes special characters from the given URL string
    #
    def encode_url_string(url)
      url_string = URI.escape(url)
      return url_string
    end

    #
    # This method returns the links to migrate from file ,
    # As an array
    #
    def get_dynamic_links_to_migrate

      file_with_migrate_link_list = Immutable.config.dynamic_links_list;
      list_of_links_to_migrate = []
      File.open(file_with_migrate_link_list) do |links|
        links.each do |link|
          list_of_links_to_migrate << link.to_s;
        end
      end
      return list_of_links_to_migrate;
    end

    #
    # This method does an http request to the URL
    # Which needs to be migrated and returns the response
    #
    def get_content_from_url(content_base_url)
      begin
        content_url = Immutable.config.dynamic_link_base_url + '/' + content_base_url;
        crawler = Mechanize.new
        response = crawler.get(content_url);
        return response;
      rescue Mechanize::ResponseCodeError => exp
        Immutable.log.error "URL - #{content_url} Error details #{exp.inspect}";
        return false;
      end
    end

    #
    # This method replaces image sources with
    # migrated image sources
    #
    def replace_image_sources_with_new_paths(source)

      replacements = []
      replacements << ["uploadedfiles", "content"]

      replacements << ["images/uploadedImages/GOMamelodi", "content/gomamelodi"]
      replacements << ["images/uploadedImages/boxes/New Folder", "boxes"]
      replacements << ["images/uploadedImages/boxes/New%20Folder", "boxes"]
      replacements << ["images/uploadedImages/boxes", "boxes"]
      replacements << ["images/uploadedImages/buttons", "buttons"]
      replacements << ["images/uploadedImages/banners", "banners"]
      replacements << ["images/uploadedImages/3500 Madison", "content/3500Madison"]
      replacements << ["images/uploadedImages/3500%20Madison", "content/3500Madison"]
      replacements << ["images/uploadedImages", "content"]
      replacements << ["img/icn", "icn"]
      replacements << ["img/tabs", "tabs"]

      replacements.each { |set| source = source.gsub(set[0], set[1]) }
      source = Immutable.config.s3url+ source
      return source;

    end

    #
    # This method adds slash in the beginning of image sources .
    # If its missing
    #
    def add_trailing_slash_if_it_doesnot_exists(file_path)
      file_path << '/' if file_path[0] != '/'
      return file_path;
    end

    #
    # This method updates image paths
    # with the migrated path by
    # Parsing the content
    #
    def update_html_with_new_image_paths(data_to_migrate)
      doc_to_migrate = Nokogiri::HTML(data_to_migrate);
      doc_to_migrate.css('img').each do |img|
        old_src = img.attribute('src').to_s;
        new_src = Contenthelper.replace_image_sources_with_new_paths(old_src);
        img['src'] = new_src;
      end
      return doc_to_migrate.to_s;
    end


    #
    # This method updates image paths
    # with the migrated path by
    # Parsing the content
    #
    def update_html_with_new_media_hrefs(data_to_migrate)
      doc_to_migrate = Nokogiri::HTML(data_to_migrate);
      doc_to_migrate.css('a').each do |a|
        href = a.attribute('href').to_s;
        new_href = Contenthelper.update_href(href);
        a['href'] = new_href;
      end
      return doc_to_migrate.to_s;
    end


    #
    # This method logs hrefs to media in all
    # migrated content
    #
    def log_various_href_sources(data_to_migrate)
      doc_to_migrate = Nokogiri::HTML(data_to_migrate);
      doc_to_migrate.css('a').each do |img|
        old_src = img.attribute('href').to_s;
        if   old_src['.pdf']
            File.open("pdfs_missing.log", 'a+') {|f| f.write(old_src + "\n") }
        elsif old_src['.mp3']
            File.open("mp3_missing.log", 'a+') {|f| f.write(old_src + "\n") }
        elsif old_src['.mp4']
            File.open("mp4_missing.log", 'a+') {|f| f.write(old_src + "\n") }
        elsif old_src['.doc']
            File.open("docs_missing.log", 'a+') {|f| f.write(old_src + "\n") }
        else
            File.open("everythingelse.log", 'a+') {|f| f.write(old_src + "\n") }
        end
      end
    end





    #
    # This method changes all hrefs with new S3 url
    #
    def update_href(href)

      href.gsub('http://www.crossroads.net/', '/');
      replacements = []
      if href['.pdf']
        replacements << ["uploadedfiles", "pdf"]
        replacements << ["images/uploadedImages", "pdf"]
      elsif href['.mp3']
        replacements << ["players/media/hq/320", "mp3"]
        replacements << ["uploadedfiles", "mp3"]
      elsif href['.doc']
        replacements << ["uploadedfiles", "docs"]
        replacements << ["images/uploadedImages", "docs"]
      end
      replacements.each { |set| href = href.gsub(set[0], set[1]) }
      if !replacements.empty?
        href = Immutable.config.s3media + href
      end
      return href;

    end

    #
    # This method copies required media to a folder
    #
    def copy_files_to_required_folder(data_to_migrate)
      doc_to_migrate = Nokogiri::HTML(data_to_migrate);
      doc_to_migrate.css('a').each do |img|
        old_src = img.attribute('href').to_s;
        old_src.gsub('http://www.crossroads.net/', '/');
        if(old_src['http://'])
          Immutable.log.info " - > #{ old_src } we do not need this file   ";
        else
          file_to_copy = Immutable.config.legacy_htdocs_path + old_src
          status = File.file?(file_to_copy);
          case status
            when true
              if   old_src['.pdf']
                FileUtils.cp(file_to_copy, 'pdfs/');
              elsif old_src['.mp3']
                FileUtils.cp(file_to_copy, 'mp3/');
              elsif old_src['.mp4']
                FileUtils.cp(file_to_copy, 'mp4/');
              elsif old_src['.doc']
                FileUtils.cp(file_to_copy, 'doc/') ;
              else
                FileUtils.cp(file_to_copy, 'all/') ;
              end
            when false
                Immutable.log.info " - > #{ file_to_copy } does not exists  ";
            end
        end
      end
    end
  end

end





