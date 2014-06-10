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
    def get_all_series
      begin
        series_data = Immutable.dbh.execute('SELECT * FROM series ORDER BY `StartDate` DESC');
        return series_data;
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
    # This method gets only the video mediacontent for a particular message
    #
    def get_video_media_content_for_message(message_id)
      begin
        video_sql = "SELECT * FROM mediacontent WHERE mediacontentid";
        video_sql += " IN (SELECT messagemediacontent.mediaid FROM messagemediacontent WHERE";
        video_sql += " messageid = #{message_id}) AND ( iPodVideo IS NOT NULL)";
        video_sql += " AND (ContentTypeID = 4 OR ContentTypeID = 1) AND (iPodVideo LIKE '%mp4')";
        video_sql += "AND iPodVideo!=''";
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
    def get_media_content
      begin
        video_sql = "SELECT * FROM mediacontent";
        video_sql += " WHERE  ContentTypeID = 1";
        video_sql += " AND ( iPodVideo IS NOT NULL AND iPodVideo != '') AND (iPodVideo LIKE '%mp4')";
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
    # Function to get the data related to blog post
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
    # function to get the media content information based on the blog post
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
    
  end
end
