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
        series_data = Immutable.dbh.execute('select * from series order by `StartDate` DESC');
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
        message_data = Immutable.dbh.execute("select * from message where SeriesID = #{series_id} order by date desc");
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
        message_media_content_data = Immutable.dbh.execute("SELECT * from mediacontent
where mediacontentid in (select messagemediacontent.mediaid from messagemediacontent where messageid = #{message_id}) AND ( HighQFilePath IS NOT NULL OR iPodVideo IS NOT NULL)");
        return message_media_content_data;
      rescue DBI::DatabaseError => e
        Immutable.log.error "Error code: #{e.err}"
        Immutable.log.error "Error message: #{e.errstr}"
        Immutable.log.error "Error SQLSTATE: #{e.state}"
        abort('An error occurred while getting message media content data from DB, Check migration log for more details');
      end
    end

  end
end