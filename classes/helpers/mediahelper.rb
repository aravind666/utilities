# encoding: ASCII-8BIT

# Media Helper class definition, which defines several helper
# classes for Media content migration it may be message or video or audio
#
# Author::    Aravind Udayashankara  (mailto:aravind.udayashankara@gmail.com)
# Copyright:: Copyright (c) 2012 Crossroads
# License::   MIT
#
# All behaviours exhibitted here are selfies you donot need an object to call them
#
#
class Mediahelper

  class << self

    #
    # This method is used to get all series from database
    #
    # * this function will get all the series by start date in descending order
    #
    # mediahelper.get_all_series
    #
    def get_all_series
      begin
        series_sql  = 'SELECT * FROM series ORDER BY StartDate DESC'
        series_data = Immutable.dbh.execute(series_sql)
        return series_data
      rescue DBI::DatabaseError => e
        Immutable.log.error "Error code: #{e.err}"
        Immutable.log.error "Error message: #{e.errstr}"
        Immutable.log.error "Error SQLSTATE: #{e.state}"
        abort('An error occurred while getting series data from DB, Check migration log for more details');
      end
    end

    #
    # This method is used to get all messages with in a particular series
    #
    # * this function will get message details for a particular series id
    # * and orders by date in descending
    #
    # mediahelper.get_all_messages_for_series(121)
    #
    def get_all_messages_for_series(series_id)
      begin
        message_data = Immutable.dbh.execute("SELECT * FROM message WHERE SeriesID = #{series_id} ORDER BY date DESC");
        return message_data;
      rescue DBI::DatabaseError => e
        Immutable.log.error "Error code: #{e.err}"
        Immutable.log.error "Error message: #{e.errstr}"
        Immutable.log.error "Error SQLSTATE: #{e.state}"
        abort('An error occurred while getting message data for series from DB, Check migration log for more details');
      end
    end

    #
    # This method gets mediacontent for a particular message
    #
    # * this function will get media content searching the various mediacontent id's
    # * for a particular message id
    # * checks if ipodvideo, highqfilepath exists and is not empty
    #
    # mediahelper.get_media_content_for_message(1245)
    #
    def get_media_content_for_message(message_id)
      begin
        message_sql = "SELECT * FROM mediacontent WHERE mediacontentid IN";
        message_sql += " (SELECT messagemediacontent.mediaid FROM messagemediacontent WHERE messageid = #{message_id})";
        message_sql += " AND (( iPodVideo IS NOT NULL AND iPodVideo != '') OR (HighQFilePath IS NOT NULL AND HighQFilePath != '' ))";
        message_media_content_data = Immutable.dbh.execute(message_sql);

        return message_media_content_data;
      rescue DBI::DatabaseError => e
        Immutable.log.error "Error code: #{e.err}"
        Immutable.log.error "Error message: #{e.errstr}"
        Immutable.log.error "Error SQLSTATE: #{e.state}"
        abort('An error occurred while getting message media content data from DB, Check migration log for more details');
      end
    end

    #
    # This method gets audio content for a particular message
    #
    # * this function will get only the audio related media content
    # * for a particular message id
    # * checks if  highqfilepath exists and is not empty and checks for particular content type id 5 and 2
    #
    # mediahelper.get_audio_content_for_message(1245)
    #
    def get_audio_content_for_message(message_id)
      begin

        audio_sql = "SELECT * FROM mediacontent WHERE mediacontentid";
        audio_sql += " IN (SELECT messagemediacontent.mediaid FROM messagemediacontent WHERE";
        audio_sql += " messageid = #{message_id}) AND ( HighQFilePath IS NOT NULL)";
        audio_sql += " AND (ContentTypeID = 5 OR ContentTypeID = 2) AND (HighQFilePath LIKE '%mp3')";
        audio_sql += " AND HighQFilePath != ''"

        message_audio_content_data = Immutable.dbh.execute(audio_sql);
        return message_audio_content_data;
      rescue DBI::DatabaseError => e
        Immutable.log.error "Error code: #{e.err}"
        Immutable.log.error "Error message: #{e.errstr}"
        Immutable.log.error "Error SQLSTATE: #{e.state}"
        abort('An error occurred while getting audio content data from DB, Check migration log for more details');
      end
    end

    #
    # This method gets all media from all the messages
    #
    # * this function will get all the media content
    # * checks if  highqfilepath exists and is not empty
    #
    # mediahelper.get_all_media_from_all_messages
    #
    def get_all_media_from_all_messages
      begin
        media_sql = "SELECT * FROM mediacontent WHERE mediacontentid IN";
        media_sql += " (SELECT messagemediacontent.mediaid FROM messagemediacontent)";
        media_sql += " AND  (HighQFilePath IS NOT NULL AND HighQFilePath != '' ) ";
        message_media_data = Immutable.dbh.execute(media_sql);
        return message_media_data;
      rescue DBI::DatabaseError => e
        Immutable.log.error "Error code: #{e.err}"
        Immutable.log.error "Error message: #{e.errstr}"
        Immutable.log.error "Error SQLSTATE: #{e.state}"
      end
    end


    #
    # This method gets only the video mediacontent for a particular message
    #
    # * this function will get only the video related media content
    # * for a particular message id
    # * checks if  ipodvideo exists and is not empty and checks for particular content type id 4 and 1
    # * and is of type mp4
    #
    # mediahelper.get_video_media_content_for_message(1245)
    #
    def get_video_media_content_for_message(message_id)
      begin
        video_sql = "SELECT * FROM mediacontent WHERE mediacontentid";
        video_sql += " IN (SELECT messagemediacontent.mediaid FROM messagemediacontent WHERE";
        video_sql += " messageid = #{message_id}) AND ( iPodVideo IS NOT NULL)";
        video_sql += " AND (ContentTypeID = 4 OR ContentTypeID = 1) AND (iPodVideo LIKE '%mp4')";
        video_sql += "AND iPodVideo!='' ORDER BY RecordDate ASC ";
        message_video_content_data = Immutable.dbh.execute(video_sql);

        return message_video_content_data;
      rescue DBI::DatabaseError => e
        Immutable.log.error "Error code: #{e.err}"
        Immutable.log.error "Error message: #{e.errstr}"
        Immutable.log.error "Error SQLSTATE: #{e.state}"
        abort('An error occurred while getting message video content data from DB, Check migration log for more details');
      end
    end

    #
    # Get all media content
    #
    # * this function will get all media content
    # * checks if ipodvideo is not empty and exists and is of type mp4
    #
    # mediahelper.get_media_content
    #
    def get_media_content
      begin
        video_sql = "SELECT * FROM mediacontent";
        video_sql += " WHERE  ContentTypeID = 1";
        video_sql += " AND ( iPodVideo IS NOT NULL AND iPodVideo != '') AND (iPodVideo LIKE '%mp4') ORDER BY RecordDate ASC";
        message_video_content_data = Immutable.dbh.execute(video_sql);

        return message_video_content_data;
      rescue DBI::DatabaseError => e
        Immutable.log.error "Error code: #{e.err}"
        Immutable.log.error "Error message: #{e.errstr}"
        Immutable.log.error "Error SQLSTATE: #{e.state}"
        abort('An error occurred while getting message video content data from DB, Check migration log for more details');
      end
    end

    #
    # function to get the media content information based on the blog post
    #
    # * this function will get mediacontent
    # * for a particular post id
    #
    # mediahelper.get_media_content_by_media_content_id(1245)
    #
    def get_media_content_by_media_content_id(id)
      begin
        content_sql = "SELECT mediacontent.* FROM channelmedia";
        content_sql += " JOIN mediacontent ON mediacontent.mediaContentId = channelmedia.mediaId";
        content_sql += " WHERE postId = #{id}";
        media_content = Immutable.dbh.execute(content_sql);
        return media_content;
      rescue DBI::DatabaseError => e
        Immutable.log.error "Error code: #{e.err}"
        Immutable.log.error "Error message: #{e.errstr}"
        Immutable.log.error "Error SQLSTATE: #{e.state}"
        abort('An error occurred while getting media content from DB, Check migration log for more details');
      end
    end

    #
    # method that returns the media element based on the blog post
    # table are of 3 types - video, audio, image
    #
    # * this function will get list of media elements that may be either in image, audio OR video
    # * for a particular message id
    #
    # mediahelper.get_all_media_for_blog(1245, 'video')
    #
    def get_all_media_for_blog(id, table)
      begin
        media_sql = "SELECT #{table}.* FROM channelmedia ";
        media_sql += " JOIN #{table} ON channelmedia.mediaId = #{table}.mediaContentId";
        media_sql += " WHERE postId = #{id}";
        media_blog_post_data = Immutable.dbh.execute(media_sql);

        return media_blog_post_data;
      rescue DBI::DatabaseError => e
        Immutable.log.error "Error code: #{e.err}"
        Immutable.log.error "Error message: #{e.errstr}"
        Immutable.log.error "Error SQLSTATE: #{e.state}"
        abort('An error occurred while getting blog post data from DB, Check migration log for more details');
      end
    end

    #
    # This method gets all audio contents
    #
    # * this function will get only the audio related media content
    # * checks if  highqfilepath exists and is not empty and checks for particular content type id 2
    # * and is of type mp3
    #
    # mediahelper.get_audio_content
    #
    def get_audio_content
      begin
        audio_sql = "SELECT * FROM mediacontent WHERE HighQFilePath IS NOT NULL";
        audio_sql += " AND (ContentTypeID = 2) AND (HighQFilePath LIKE '%mp3')";
        audio_sql += " AND HighQFilePath != ''"
        audio_content_data = Immutable.dbh.execute(audio_sql);
        return audio_content_data;
        rescue DBI::DatabaseError => e
        Immutable.log.error "Error code: #{e.err}"
        Immutable.log.error "Error message: #{e.errstr}"
        Immutable.log.error "Error SQLSTATE: #{e.state}"
        abort('An error occurred while getting audio content data from DB, Check migration log for more details');
      end
    end

    #
    # get all the media elements of a blog post
    #
    def media_for_blog_post(id)
      media_data = Mediahelper.get_media_content_by_media_content_id(id);
      return media_data;
    end

    # Public: get audio duration for a message content
    #
    # *message_id* - Int used to get the audio duration from media content table
    # Return audio duration
    #
    def get_audio_duration(message_id)
      begin
        audio_sql ="SELECT duration FROM mediacontent WHERE mediacontentid IN";
        audio_sql +=" (SELECT messagemediacontent.mediaid FROM messagemediacontent";
        audio_sql +=" WHERE messageid =#{message_id}) AND (HighQFilePath IS NOT NULL";
        audio_sql +=" AND HighQFilePath != ' ' ) AND ContentTypeID=5";
        audio_result = Immutable.dbh.select_one(audio_sql);
        return audio_result;
        rescue DBI::DatabaseError => e
        Immutable.log.error "Error code: #{e.err}";
        Immutable.log.error "Error message: #{e.errstr}";
        Immutable.log.error "Error SQLSTATE: #{e.state}";
        abort('An error occurred while getting message data for series from DB, Check migration log for more details')
      end
    end

    #
    # This method receives the media content id
    # and gets single OR multiple content tags associated to it
    #
    # * Gets the id
    # * Gets content information for that id
    #
    # mediahelper.get_content_tag_from_media_content_id(12)
    #
    def get_content_tag_from_media_content_id(media_content_id)
      begin
        content_tag_sql = "SELECT * FROM contenttag WHERE MediaContentID = #{media_content_id}";
        content_tag_data = Immutable.dbh.execute(content_tag_sql);
        return content_tag_data;
        rescue DBI::DatabaseError => e
        Immutable.log.error "Error code: #{e.err}"
        Immutable.log.error "Error message: #{e.errstr}"
        Immutable.log.error "Error SQLSTATE: #{e.state}"
        abort('An error occurred while getting content tag data from DB, Check migration log for more details');
      end
    end

    #
    # This method the associated media tag id in content tag table
    #
    # * Gets the media tag id
    # * Gets the tag name associated to it
    #
    # mediahelper.get_tags_using_media_tag_id(355)
    #
    def get_tags_using_media_tag_id(media_tag_id)
      begin
        media_tag_sql = "SELECT * FROM mediatag WHERE MediaTagID = #{media_tag_id}";
        media_tag_data = Immutable.dbh.select_one(media_tag_sql);
        return media_tag_data;
        rescue DBI::DatabaseError => e
        Immutable.log.error "Error code: #{e.err}"
        Immutable.log.error "Error message: #{e.errstr}"
        Immutable.log.error "Error SQLSTATE: #{e.state}"
        abort('An error occurred while getting media tag data from DB, Check migration log for more details');
      end
    end

    #
    # This method used for single media content id related tag list
    #
    # * Gets the media content id
    # * Gets the front matter related to that tag list
    #
    # mediahelper.get_tag_data(12)
    #
    def get_tag_data(media_content_id)
      front_matter = ''
      content_tag_data = self.get_content_tag_from_media_content_id(media_content_id)
      if content_tag_data.fetchable? then
        front_matter = "\ntag: "
        content_tag_data.each do |content_tag|
          tag = self.get_tags_using_media_tag_id(content_tag[1])
          if !tag.nil?
            tag_name = ContentHelper.purify_title_by_removing_special_characters(tag['WordPhrase'].strip)
            front_matter += "\n - #{tag_name.downcase}"
          end
        end
      end
      if front_matter == "\ntag: "
        return false
      end
      return front_matter
    end

    #
    # This method gets multiple media content id and is based on a message
    # message contains multiple media and multiple content tags which is organized
    # and stored as a comma separated array
    #
    # * Gets the media content id
    # * Gets the comma separated info of media content id
    #
    # mediahelper.get_message_tag_data(12)
    #
    def get_message_tag_data(media_content_id)
      message_tags = ''
      content_tag_data = self.get_content_tag_from_media_content_id(media_content_id)
      if content_tag_data.fetchable? then
        content_tag_data.each do |content_tag|
          tag = self.get_tags_using_media_tag_id(content_tag[1])
          if !tag.nil?
            tag_name = ContentHelper.purify_title_by_removing_special_characters(tag['WordPhrase'].strip)
            message_tags += "#{tag_name.downcase},"
          end
        end
      end
      message_tags.chomp!(',')
    end

    #
    # This method combines multiple media content of a message
    # in comma separated form
    # and then associates to a front matter
    #
    # * Gets the tag array of message media content
    # * find uniq among all the media content in a message
    # * get the jeklly front matter
    #
    # mediahelper.get_message_tag_front_matter(array)
    #
    def get_message_tag_front_matter(message_tag_array)
      front_matter = "\ntag: "
      message_tags = ''
      message_tag_array.each do |tag|
        if !tag.nil?
          message_tags += "#{tag},"
        end
      end
      combine_array = message_tags.split(',')
      if combine_array.any?
        combine_array.uniq!
        combine_array.each do |value|
          if !value.nil?
            front_matter += "\n - #{value}"
          end
        end
      end
      if front_matter == "\ntag: "
        return false
      end
      front_matter
    end

    #
    # Function used to download file from url
    #
    def http_download_uri(uri, filename)
      puts "Starting HTTP download for: #{uri.to_s}"
      http_object = Net::HTTP.new(uri.host, uri.port)
      http_object.use_ssl = true if uri.scheme == 'https'
      begin
        http_object.start do |http|
          request = Net::HTTP::Get.new uri.request_uri
          http.read_timeout = 500
          http.request request do |response|
            open filename, 'w' do |io|
              response.read_body do |chunk|
                io.write chunk
              end
            end
          end
        end
      rescue Exception => e
        puts "=> Exception: '#{e}'. Skipping download."
        return
      end
      puts "Stored download as #{filename}."
    end

    #
    # Function used to url encode file and replace https with http
    #
    def get_url_encoded_file(file)
      begin
        file.gsub!('https','http')
        uri = URI.parse(URI.escape(URI.unescape(file)))
        return uri
      end
    end

    #
    # Function to get the media content information from DB
    #
    # * Gets the id
    # * send the info from DB related to the given id
    #
    # Mediahelper.get_content_type_by_content_id(20566)
    #
    def get_content_type_by_content_id(content_id)
      begin
        media_content_sql = "SELECT * FROM mediacontent";
        media_content_sql += " where MediaContentID = '#{content_id}'"
        media_content_data = Immutable.dbh.select_one(media_content_sql)
        return media_content_data
        rescue DBI::DatabaseError => e
        Immutable.log.error "Error code: #{e.err}"
        Immutable.log.error "Error message: #{e.errstr}"
        Immutable.log.error "Error SQLSTATE: #{e.state}"
        abort('An error occurred while getting milacron migrate new pages by legacy path, Check migration log for more details')
      end
    end

  end
end
