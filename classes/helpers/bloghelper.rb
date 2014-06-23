# encoding: ASCII-8BIT

# Blog Helper class definition, which defines several helper
# classes for blog migration
#
# Author::    Sandeep A R  (mailto:sandeep.setty@costrategix.com)
# Copyright:: Copyright (c) 2012 Crossroads
# License::   MIT
#
# All behaviours exhibited here are selfies you do not need an object to call them
#
class BlogHelper

  class << self
    #
    # Function to get the data related to blog post
    #
    # * this function will get all the blog posts
    # * for channels id's in 1,2,3,4,5,6,7,8,9 and the migrate flag need to be yes
    #
    # BlogHelper.get_all_blog_posts
    #
    def get_all_blog_posts
      begin
        # there are too many columns which leads to ambiguity. So, fetch the required columns
        blog_sql = "SELECT cp.id, cp.title as title, cp.subtitle, cp.paragraph1, cp.paragraph2, cpx.createdDate,";
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
    # Public static: updates anchor paths
    # with the migrated path by Parsing the content
    #
    # *data_to_migrate* - String data which needs to updated href media references
    #
    # Returns new href src for media
    #
    def update_html_with_milacron_href_in_content_posts(data_to_migrate)
      doc_to_migrate = Nokogiri::HTML(data_to_migrate)
      new_href = false
      doc_to_migrate.css('a').each do |a|
        href = a.attribute('href').to_s

        if href['/my/media/playMedia'] || href['/my/media/playVideo']
          new_href = self.get_play_media_and_video_url(href)
        elsif href['/blog/view']
          new_href = self.get_blog_view_url(href)
        elsif href['/my/media/viewSeries']
          new_href = self.get_series_view_url(href)
        elsif href['/my/media/index.php']
          new_href = '/media';
        elsif href['/my/media/messages.php']
          new_href = '/media/series';
        elsif href['/my/media/music.php']
          new_href = '/media/music/';
        elsif href['/my/media/podcasts.htm']
          new_href = '/content/Media/podcasts.htm';
        end
        if new_href
          a['href'] = new_href;
        end
      end
      return doc_to_migrate.to_s
    end

    #
    # This method based on the href's received
    # gets the message info by media content id by splitting with
    # the mentioned id
    #
    # * Split from the URL
    # * Get message id from media content id
    # * Get message info from message table
    #
    # bloghelper.get_play_media_and_video_url(url)
    #
    def get_play_media_and_video_url(href)
      new_href = false
      clean_hrefs = ContentHelper.clean_hrefs_or_images_url(href);
      media_content_id = clean_hrefs.split('=').last
      if !media_content_id.nil?
        message_id_array = self.get_message_media_content_by_id(media_content_id);
        if !message_id_array.nil?
          message_id = message_id_array['MessageId'];
          message_info = self.get_message_info(message_id);
          new_href = self.get_href_media_replace_url(message_info);
        end
      end
      return new_href
    end

    #
    # Get the blog information from the post id and channel id
    #
    # * Split from the URL
    # * Get blog post info from channel id and post id
    #
    # bloghelper.get_blog_view_url(url)
    #
    def get_blog_view_url(href)
      new_href = false
      href_parts = href.split('/')
      post_id = href_parts[href_parts.length - 1]
      channel_id = href_parts[href_parts.length - 2]
      blog_post_info = self.get_post_info_by_id(channel_id,post_id);
      if !blog_post_info.nil?
        new_href = self.get_new_blog_reference_url(blog_post_info);
      else
        log_message = "post Id  #{post_id} on channel Id #{channel_id} does not exists in DB "
        File.open("blog_posts_does_not_exists.log", 'a+') { |f| f.write(log_message + "\n") }
      end
      return new_href
    end

    #
    # This method based on the href's received
    # gets the series info with
    # the mentioned id
    #
    # * Split from the URL
    # * Get series info from series id
    #
    # bloghelper.get_series_view_url(url)
    #
    def get_series_view_url(href)
      new_href = false
      clean_hrefs = ContentHelper.clean_hrefs_or_images_url(href);
      series_id = clean_hrefs.split('=').last
      if !series_id.nil?
        series_result = self.get_series_by_id(series_id);
        if !series_result.nil?
          new_href = self.get_href_series_replace_url(series_result);
        end
      end
      return new_href
    end


    #
    # Function to get the message id from the media content id
    #
    # * gets the media content id
    # * generates message id
    #
    # BlogHelper.get_message_media_content_by_id(522)
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
    # BlogHelper.get_message_info(811)
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
    # Function to rewrite new url
    #
    # * gets the message related data from DB
    # * identifies the columns which is required
    # * generates the url has desired
    #
    # BlogHelper.get_href_media_replace_url(array)
    #
    def get_href_media_replace_url(message_info)
      new_href = false
      message_info.each do |data|
        title = ContentHelper.purify_title_by_removing_special_characters(data['Title'].downcase.strip);
        date = data['Date'].strftime('%Y-%m-%d');
        new_href = "/messages/#{date}-#{title}.html"
      end
      return new_href;
    end

    #
    # Function to get the data related to a particular post id
    #
    # * this function will get the required post information
    #
    # BlogHelper.get_post_info_by_id(33)
    #
    def get_post_info_by_id(channel_id, post_id)
      begin
        # there are too many columns which leads to ambiguity. So, fetch the required columns

        blog_sql = "SELECT cp.id, cpx.postId, cpx.createdDate, cpx.channelId, ch.name ,cp.title "
        blog_sql += " from channelpostxref as cpx"
        blog_sql += " JOIN channel as ch ON cpx.channelId = ch.id"
        blog_sql += " JOIN channelpost as cp ON cpx.postId = cp.id"
        blog_sql += " where cpx.channelId = #{channel_id} and cpx.postId = #{post_id}"
        blog_post_data = Immutable.dbh.select_one(blog_sql);
        return blog_post_data;
        rescue DBI::DatabaseError => e
        Immutable.log.error "Error code: #{e.err}"
        Immutable.log.error "Error message: #{e.errstr}"
        Immutable.log.error "Error SQLSTATE: #{e.state}"
        abort('An error occurred while getting blog post data from DB, Check migration log for more details');
      end
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
      title = ContentHelper.purify_title_by_removing_special_characters(blog_post_info['title'].downcase.strip);
      file_name = "#{blog_post_info['createdDate'].strftime('%Y-%m-%d')}-#{blog_post_info['id']}-#{title}.html"
      tag = blog_post_info['name'].downcase.strip;
      file_parts = file_name.split('-');
      new_href = "/#{tag}/#{file_parts[0]}/#{file_parts[1]}/#{file_parts[2]}/#{blog_post_info['id']}-#{title}.html";
      status = BlogHelper.check_for_blog_post_existence(file_name,blog_post_info)
      if status
        return new_href
      else
        return false
      end
    end

    #
    # Function to get the series info based on series id
    #
    # * gets the series data
    # * generates series information required
    #
    # BlogHelper.get_series_by_id(series_id)
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

    #
    # Function to rewrite new url
    #
    # * gets the series related data from DB
    # * identifies the columns which is required
    # * generates the url has desired
    #
    # BlogHelper.get_href_series_replace_url(array)
    #
    def get_href_series_replace_url(series_data)
      series_title = series_data['Title']
      series_title.gsub!(':', '-')
      series_title = ContentHelper.purify_title_by_removing_special_characters(series_title.downcase.strip);
      new_href = "/#{series_title}/"
      #File.open("fin.log", 'a+') { |f| f.write(new_href + "\n") }
      return new_href
    end

    #
    # Public static: checks whether the blog post exists or not
    # with in the migrated folder in the milacron app folder
    #
    # *file_name* - file name to check for
    # *blog_post_info* - Blog information which we are searching for
    #
    # Returns new href src for blog reference links
    #
    def check_for_blog_post_existence(file_name,blog_post_info)
      destination_to_check = Immutable.config.blog_destination_path
      file_path = "#{destination_to_check}/#{file_name}"
      if File.file?(file_path)
        return true;
      else
        log_message = "post Id  #{blog_post_info['postId']} on channel Id #{blog_post_info['channelId']} has not been migrated "
        File.open("blog_posts_missing.log", 'a+') { |f| f.write(log_message + "\n") }
        return false
      end
    end

  end
end