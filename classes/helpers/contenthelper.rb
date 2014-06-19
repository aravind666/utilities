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
      replacements << ['', ''] #escape special chars
      replacements << ["’", "'"] #escape special chars
      replacements << ["”", "\''"] #escape special chars
      replacements << ["“", "\''"] #escape special chars
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
      replacements << ['---', '-']
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
      source = source.strip;
      source = source.gsub("https://www.crossroads.net/", '/')
      source = source.gsub("http://www.crossroads.net/", '/')
      source = source.gsub('../../', '/')
      source = source.gsub('../', '/')
      if !source['https://'] && !source['http://']
        replacements = [] 
        #
        # image/uploadedImages folder
        #
        replacements << ["images/uploadedImages/Corporate Blogger", "content"]
        replacements << ["images/uploadedImages/Corporate%20Blogger", "content"]
        replacements << ["images/uploadedImages/Free%20Journey", "content"]
        replacements << ["images/uploadedImages/Journey Materials/Consumed", "content"]
        replacements << ["images/uploadedImages/GO%20New%20Orleans", "content"]
        replacements << ["images/uploadedImages/kidsmusic", "content"]
        replacements << ["images/uploadedImages/GOMamelodi", "content"]
        replacements << ["images/uploadedImages/boxes/New Folder", "content"]
        replacements << ["images/uploadedImages/boxes/New%20Folder", "content"]
        replacements << ["images/uploadedImages/boxes", "content"]
        replacements << ["images/uploadedImages/buttons", "content"]
        replacements << ["images/uploadedImages/banners", "content"]
        replacements << ["images/uploadedImages/3500 Madison", "content"]
        replacements << ["images/uploadedImages/3500%20Madison", "content"]
        replacements << ["images/uploadedImages/Reset", "content"]
        replacements << ["images/uploadedImages", "content"]

        #
        # img  folder
        #
        replacements << ["img/icn", "content"]
        replacements << ["img/tabs", "content"]

        #
        # uploadedfiles  folder
        #
        replacements << ["uploadedfiles/1/", "content/"]
        replacements << ["uploadedfiles", "content"]

        #
        # players folder
        #
        replacements << ["players/media/smallThumbs", "content"]
        replacements << ["players/media/series", "content"]

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
        old_file_name = File.basename(old_src);
        s3_file_name = old_file_name.gsub(' ','+');
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
        old_file_name = File.basename(href);
        s3_file_name = old_file_name.gsub(' ','+');
        href = href.gsub(old_file_name,s3_file_name);
        new_href = Contenthelper.update_href(href)
        a['href'] = new_href
      end
      return doc_to_migrate.to_s
    end

    #
    # Public static: updates anchor paths
    # with the migrated path by Parsing the content
    #
    # *data_to_migrate* - String data which needs to updated href references
    #
    # Returns new href src for blog links
    #
    def update_html_with_new_blog_hrefs(data_to_migrate)
      doc_to_migrate = Nokogiri::HTML(data_to_migrate)
      new_href = '';
      doc_to_migrate.css('a').each do |a|
        href = a.attribute('href').to_s
        if href['/blog/view']
          post_id = href.split('/').last
          blog_post_info = self.get_post_info_by_id(post_id);
          new_href = self.get_new_blog_reference_url(blog_post_info);
          a['href'] = new_href;
        end
      end
      return doc_to_migrate.to_s
    end

    #
    # Public static: updates anchor paths
    # with the migrated path by Parsing the content
    #
    # *data_to_migrate* - String data gets the new href to be replaced
    #
    # Returns new href src for blog reference links
    #
    def get_new_blog_reference_url(blog_post_info)
      new_href = '';
      blog_post_info.each do |data|
        tag = data['name'].downcase.strip;
        first_date = data['createdDate'].to_s.split('T').first;
        date = first_date.split('-');
        year = date[0];
        month = date[1];
        day = date[2];
        title = Contenthelper.purify_title_by_removing_special_characters(data['title'].downcase.strip);
        title = "#{data['createdDate'].strftime('%H-%M-%S')}-#{title}.html"
        new_href = "/#{tag}/#{year}/#{month}/#{day}/#{title}";
        #File.open("blogref.log", 'a+') { |f| f.write(new_href + "\n") }
      end
      return new_href;
    end

    #
    # Public static: updates anchor paths
    # with the migrated path by Parsing the content
    #
    # *data_to_migrate* - String data which needs to updated href media references
    #
    # Returns new href src for media
    #
    def update_html_with_milacron_href_in_content_posts(data_to_migrate)
      doc_to_migrate = Nokogiri::HTML(data_to_migrate)
      new_href = '';
      doc_to_migrate.css('a').each do |a|
        href = a.attribute('href').to_s
        if href['/my/media/playMedia'] || href['/my/media/playVideo']
          clean_hrefs = self.clean_hrefs_or_images_url(href);
          media_content_id = clean_hrefs.split('=').last
          if !media_content_id.nil?
            message_id_array = self.get_message_media_content_by_id(media_content_id);
            if !message_id_array.nil?
              message_id = message_id_array['MessageId'];
              message_info = self.get_message_info(message_id);
              new_href = self.get_href_media_replace_url(message_info);
            end
          end
        elsif href['/blog/view']
            post_id = href.split('/').last
            blog_post_info = self.get_post_info_by_id(post_id);
            new_href = self.get_new_blog_reference_url(blog_post_info);
        elsif href['/my/media/viewSeries']
          #File.open('series.log', 'a+') { |f| f.write(href + "\n") }
          clean_hrefs = self.clean_hrefs_or_images_url(href);
          series_id = clean_hrefs.split('=').last
          if !series_id.nil?
            series_result = self.get_series_by_id(series_id);
            if !series_result.nil?
              new_href = self.get_href_series_replace_url(series_result);
            end
          end
        end
        if !new_href.empty?
          a['href'] = new_href;
        end
      end
      return doc_to_migrate.to_s
    end

    #
    # Function to rewrite new url
    #
    # * gets the message related data from DB
    # * identifies the columns which is required
    # * generates the url has desired
    #
    # contenthelper.get_href_media_replace_url(array)
    #
    def get_href_media_replace_url(message_info)
      new_href = '';
      message_info.each do |data|
        title = Contenthelper.purify_title_by_removing_special_characters(data['Title'].downcase.strip);
        date = data['Date'].strftime('%Y-%m-%d');
        new_href = "/messages/#{date}-#{title}.html"
        #File.open("fin.log", 'a+') { |f| f.write(new_href + "\n") }
      end
      return new_href;
    end

    #
    # Function to rewrite new url
    #
    # * gets the series related data from DB
    # * identifies the columns which is required
    # * generates the url has desired
    #
    # contenthelper.get_href_series_replace_url(array)
    #
    def get_href_series_replace_url(series_data)
      series_title = series_data['Title']
      series_title.gsub!( ':', '-')
      series_title = Contenthelper.purify_title_by_removing_special_characters(series_title.downcase.strip);
      new_href = "/#{series_title}/"
      #File.open("fin.log", 'a+') { |f| f.write(new_href + "\n") }
      return new_href
    end

    #
    # Function to clean up url
    #
    # * gets the url
    # * checks for parent directory clean up
    # * checks for crossroads.net clean up
    #
    # contenthelper.clean_hrefs_or_images_url(url)
    #
    def clean_hrefs_or_images_url(href)
      href = href.strip;
      href = href.gsub('http://www.crossroads.net/', '/')
      href = href.gsub('../../', '/')
      href = href.gsub('../', '/')

      return href;
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
        elsif old_src['ignup.php']
          File.open("signuppages.log", 'a+') { |f| f.write(old_src + "\n") }
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
      href = href.strip;
      href = href.gsub('http://www.crossroads.net/', '/')
      href = href.gsub('../../', '/')
      href = href.gsub('../', '/')

      replacements = []
      if href['http://'] || href['https://']
        Immutable.log.info " - > #{ href } -- we do not to do any thing with this since its external"
      elsif href['.pdf']
        replacements << ["images/uploadedImages/Corporate Blogger", "documents"]
        replacements << ["images/uploadedImages/Journey%20Materials/Consumed", "documents"]
        replacements << ["images/uploadedimages/gomamelodi/podcasts", "documents"]
        replacements << ["images/uploadedImages/audio", "documents"]
        replacements << ["images/uploadedImages/banners", "documents"]
        replacements << ["images/uploadedImages/Reset", "documents"]
        replacements << ["images/uploadedImages", "documents"]
        replacements << ["uploadedfiles", "documents"]

      elsif href['.mp3']
        replacements << ["images/uploadedImages/Corporate Blogger", "mp3"]
        replacements << ["images/uploadedImages/Journey%20Materials/Consumed", "mp3"]
        replacements << ["images/uploadedimages/gomamelodi/podcasts", "mp3"]
        replacements << ["images/uploadedImages/audio", "mp3"]
        replacements << ["images/uploadedImages/banners", "mp3"]
        replacements << ["images/uploadedImages/Reset", "mp3"]
        replacements << ["images/uploadedImages", "mp3"]
        replacements << ["players/media/hq/320", "mp3"]
        replacements << ["players/media/hq", "mp3"]
        replacements << ["teams/audio/Media", "mp3"]
        replacements << ["audio/Media", "mp3"]
        replacements << ["audio", "mp3"]
        replacements << ["webmedia/JourneyMedia/Reset", "mp3"]
        replacements << ["uploadedfiles", "mp3"]
      elsif href['.doc']

        replacements << ["images/uploadedImages/Corporate Blogger", "documents"]
        replacements << ["images/uploadedImages/Journey%20Materials/Consumed", "documents"]
        replacements << ["images/uploadedimages/gomamelodi/podcasts", "documents"]
        replacements << ["images/uploadedImages/audio", "documents"]
        replacements << ["images/uploadedImages/banners", "documents"]
        replacements << ["images/uploadedImages/Reset", "documents"]
        replacements << ["images/uploadedImages", "documents"]
        replacements << ["uploadedfiles", "documents"]

      elsif href['.jpg']
        replacements << ["images/uploadedImages/Corporate Blogger", "content"]
        replacements << ["images/uploadedImages/Journey%20Materials/Consumed", "content"]
        replacements << ["images/uploadedimages/gomamelodi/podcasts", "content"]
        replacements << ["images/uploadedImages/audio", "content"]
        replacements << ["images/uploadedImages/banners", "content"]
        replacements << ["images/uploadedImages/Reset", "content"]
        replacements << ["images/uploadedImages", "content"]
        replacements << ["uploadedfiles", "content"]
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

    #
    # Function to get the data related to blog post
    #
    # * this function will get all the blog posts
    # * for channels id's in 1,2,3,4,5,6,7,8,9 and the migrate flag need to be yes
    #
    # Contenthelper.get_all_blog_posts
    #
    def get_all_blog_posts
      begin
        # there are too many columns which leads to ambiguity. So, fetch the required columns
        blog_sql = "SELECT cp.title as title, cp.subtitle, cp.paragraph1, cp.paragraph2, cpx.createdDate,";
        blog_sql += "c.name, p.FirstName, cpx.postId FROM channelpost as cp";
        blog_sql += " JOIN channelpostxref as cpx ON cpx.postid = cp.id";
        blog_sql += " JOIN milacron_migrate_post as mmp ON cp.id = mmp.channelpost_id";
        blog_sql += " JOIN channel as c ON c.id = cpx.channelid";
        blog_sql += " JOIN person as p ON p.personId = cpx.createdBy";
        blog_sql += " WHERE cpx.`channelId` IN (1,2,3,4,5,6,7,8,9)";
        blog_sql += " AND migrate = 'yes'";
        blog_sql += " GROUP BY cp.id";
        blog_sql += " HAVING MAX(cpx.createdDate)";
        blog_post_data = Immutable.dbh.execute(blog_sql);
        return blog_post_data;
        rescue DBI::DatabaseError => e
        Immutable.log.error "Error code: #{e.err}"
        Immutable.log.error "Error message: #{e.errstr}"
        Immutable.log.error "Error SQLSTATE: #{e.state}"
        abort('An error occurred while getting blog post data from DB, Check migration log for more details');
      end
    end

    #
    # Function to get the data related to blog post
    # used to get the actual blog content
    #
    # *blog_post* - String blog content data
    #
    # Returns blog content (concatenation of para1 and para2)
    #
    def get_blog_content_matter(blog_post)
      para1 = blog_post['paragraph1'];
      para2 = blog_post['paragraph2'];

      if (para1.nil?)
        content = para2;
      elsif (para2.nil?)
        content = para1;
      else
        content = '';
      end
      if (!para2.nil? && !para1.nil?)
        content = para1 + para2;
      end
      return content;
    end

    #
    # Function to get the data related to a particular post id
    #
    # * this function will get the required post information
    #
    # Contenthelper.get_post_info_by_id(33)
    #
    def get_post_info_by_id(id)
      begin
        # there are too many columns which leads to ambiguity. So, fetch the required columns
        blog_sql = "SELECT cp.title as title, cpx.createdDate,";
        blog_sql += "c.name, cpx.postId FROM channelpost as cp";
        blog_sql += " JOIN channelpostxref as cpx ON cpx.postid = cp.id";
        blog_sql += " JOIN milacron_migrate_post as mmp ON cp.id = mmp.channelpost_id";
        blog_sql += " JOIN channel as c ON c.id = cpx.channelid";
        blog_sql += " WHERE postId = #{id}";
        blog_sql += " AND migrate = 'yes'";
        blog_sql += " GROUP BY cp.id";

        blog_post_data = Immutable.dbh.execute(blog_sql);
        return blog_post_data;
        rescue DBI::DatabaseError => e
        Immutable.log.error "Error code: #{e.err}"
        Immutable.log.error "Error message: #{e.errstr}"
        Immutable.log.error "Error SQLSTATE: #{e.state}"
        abort('An error occurred while getting blog post data from DB, Check migration log for more details');
      end
    end
    #
    # Function to get the data related to blog post
    # used to get the actual blog content
    #
    # *string* - String blog content data
    #
    # Returns blog content (concatenation of para1 and para2)
    #
    def filter_unwanted_chars(char_string)
      char_string.gsub(/\s\w\*%\^\$\&\."',#\@\!`~\(\)\}\{\`\\+=-_/,"")
    end

    #
    # Function to get the message id from the media content id
    #
    # * gets the media content id
    # * generates message id
    #
    # contenthelper.get_message_media_content_by_id(522)
    #
    def get_message_media_content_by_id(message_id)
      begin
        media_content_sql = "SELECT MessageId FROM messagemediacontent";
        media_content_sql += " WHERE MessageMediaContentID = #{message_id}";

        media_content_data = Immutable.dbh.select_one(media_content_sql);
        return media_content_data;
        rescue DBI::DatabaseError => e
        Immutable.log.error "Error code: #{e.err}"
        Immutable.log.error "Error message: #{e.errstr}"
        Immutable.log.error "Error SQLSTATE: #{e.state}"
        abort('An error occurred while getting message data from DB, Check migration log for more details');
      end
    end

    #
    # Function to get the message info based on message id
    #
    # * gets the message id
    # * generates message information required
    #
    # contenthelper.get_message_info(811)
    #
    def get_message_info(message_id)
      begin
        message_sql = "SELECT * FROM message";
        message_sql += " WHERE MessageId = #{message_id}";
        message_sql_data = Immutable.dbh.execute(message_sql);
        return message_sql_data;
        rescue DBI::DatabaseError => e
        Immutable.log.error "Error code: #{e.err}"
        Immutable.log.error "Error message: #{e.errstr}"
        Immutable.log.error "Error SQLSTATE: #{e.state}"
        abort('An error occurred while getting blog post data from DB, Check migration log for more details');
      end
    end

    #
    # Function to get the series info based on series id
    #
    # * gets the series data
    # * generates series information required
    #
    # contenthelper.get_series_by_id(series_id)
    #
    def get_series_by_id(series_id)
      begin
        series_sql = "SELECT Title, StartDate FROM series";
        series_sql += " WHERE SeriesID = #{series_id}";
        series_data = Immutable.dbh.select_one(series_sql);
        return series_data;
      rescue DBI::DatabaseError => e
        Immutable.log.error "Error code: #{e.err}"
        Immutable.log.error "Error message: #{e.errstr}"
        Immutable.log.error "Error SQLSTATE: #{e.state}"
        abort('An error occurred while getting series data from DB, Check migration log for more details');
      end
    end

  end
end
