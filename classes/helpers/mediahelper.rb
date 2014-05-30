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
        message_sql = "SELECT * FROM mediacontent WHERE mediacontentid IN ";
        message_sql += "(SELECT messagemediacontent.mediaid FROM messagemediacontent WHERE messageid = #{message_id})";
        message_sql += " AND ( iPodVideo IS NOT NULL OR HighQFilePath IS NOT NULL) AND (mediacontentid IS NOT NULL) ";
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

        audio_sql = "SELECT * FROM mediacontent WHERE mediacontentid"
        audio_sql += " IN (SELECT messagemediacontent.mediaid FROM messagemediacontent WHERE"
        audio_sql += " messageid = #{message_id}) AND ( HighQFilePath IS NOT NULL)";

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
        message_video_media_content_data = Immutable.dbh.execute("SELECT * FROM mediacontent
        WHERE mediacontentid IN
        (SELECT messagemediacontent.mediaid FROM messagemediacontent
            WHERE messageid = #{message_id}) AND
            ( iPodVideo IS NOT NULL)");
        return message_video_media_content_data;
        rescue DBI::DatabaseError => e
        Immutable.log.error "Error code: #{e.err}"
        Immutable.log.error "Error message: #{e.errstr}"
        Immutable.log.error "Error SQLSTATE: #{e.state}"
        abort('An error occurred while getting message video content data from DB, Check migration log for more details');
      end
    end

  end
end
