# encoding: ASCII-8BIT
#
# UploadVideos. class which defines various attributes and behaviours
# which are used to upload videos to youtube
#
# Author::    Hanumantharaju  (mailto:hanumantharaju.tswamy@costrategix.com)
# Copyright:: Copyright (c) 2012 Crossroads
# License::   MIT
#
# Initiating this class leads to uploading videos to youtube
#
class YouTubeHelper

  def initialize
    # initialize required variables
  end

  class << self

    def get_authenticated_service
      begin
        credentials = Hash.new
        client = ''
        credentials_file = Immutable.config.youtube_client_oauth_json
        if File.exist? credentials_file
          File.open(credentials_file, 'r') do |file|
            credentials = JSON.load(file)
            file.close
          end
          client = YouTubeIt::OAuth2Client.new(
              client_access_token: credentials['access_token'],
              client_refresh_token: credentials['refresh_token'],
              client_id: credentials['client_id'],
              client_secret: credentials['client_secret'],
              dev_key: credentials['dev_key'],
              expires_at: credentials['expires_in']
          )
          client.refresh_access_token!
        else
          puts 'client auth info file rquired'
          abort
        end
        client
      end
    end

    def upload_video_to_youtube(video_data)
      begin
        client = self.get_authenticated_service
        video_data[:file] = '/var/www/test1234.mp4'
        video_file = video_data[:file].gsub('https','http')
        response = client.video_upload(
            "#{video_file}",
            :title => video_data[:title],
            :description => video_data[:description],
            :category_id => video_data[:category_id],
            #:keywords => %w["#{video_data['tags']}"],
            :privacy_status => video_data[:privacy_status],
            :publish_at => video_data[:title],
            :license => video_data[:license],
            :embeddable => video_data[:embeddable],
            :public_stats_viewable => video_data[:public_stats_viewable],
            :location_description => video_data[:location_description],
            :latitude => video_data[:latitude],
            :longitude => video_data[:longitude],
            :recorded_at => video_data[:recording_date]
        )
        return response
      end
    end

    def add_video_to_playlist(playlist_id, video_id, position=1)
      begin
        client = self.get_authenticated_service
        playlist = client.add_video_to_playlist(playlist_id, video_id, position)
        return playlist
      end
    end

    #
    # Function used to all message videos
    #
    def get_message_video_data
      begin
        video_data_array = []
        series_data = Mediahelper.get_all_series
        if series_data.fetchable?
          series_data.each do |series|
            series_massage_data = Mediahelper.get_all_messages_for_series(series[0])
            if series_massage_data.fetchable?
              series_massage_data.each do |message|
                if message['MessageID'] > 0
                  message_media_data = Mediahelper.get_video_media_content_for_message(message[0])
                  if message_media_data.fetchable?
                    message_media_data.each do |media|
                      video_data_array << self.create_video_data(media, series[0], message[0])
                    end
                    Immutable.log.info "There are no video content available for media:#{message[0]}"
                  end
                end
              end
            end
          end
        end
        video_data_array
      end
    end

    #
    # Function used to all videos
    #
    def get_only_video_data
      begin
        video_data_array = []
        ipod_video_data = Mediahelper.get_media_content;
        if ipod_video_data.fetchable?
          ipod_video_data.each do |video_data|
            if video_data['iPodVideo'].length > 0
              video_data_array << create_video_data(video_data, 0, 0)
            end
          end
        else
          Immutable.log.info 'There are no video content available'
        end
        video_data_array
      end
    end

    #
    # Function used to process message media content
    #
    def process_message_data(message_data, series_id)
      begin
        video_data_hash = Hash.new
        if message_data.fetchable?
          message_data.each do |message|
            #puts message['MessageID']
            if message['MessageID'] > 0
              message_media_data = Mediahelper.get_video_media_content_for_message(message[0])
              if message_media_data.fetchable?
                message_media_data.each do |media|
                  self.create_video_data(media, series_id, message[0])
                end
                Immutable.log.info "There are no video content available for media:#{message[0]}"
              end
            end
          end
        end
        video_data_hash
      end
    end

    #
    # Function used to create Trollop video data options
    #
    def create_video_data(video_data, series_id=0, message_id=0)
      begin
        video_description = video_data['Description']
        video_description = video_description.strip_control_characters
        video_description = video_description.encode(
            'utf-8', 'binary',
            :invalid => :replace,
            :undef => :replace,
            :replace => ''
        )
        opts = Trollop::options do
          opt :file, 'Video file to upload',
              :default => video_data['iPodVideo'],
              :type => String
          opt :title, 'Video title',
              :default => video_data['Title'],
              :type => String
          opt :description, 'Video description',
              :default => video_description,
              :type => String
          opt :tags, 'Video keywords, comma-separated',
              :default => 'none',
              :type => String
          opt :category_id, 'category',
              :default => 22,
              :type => :int
          opt :privacy_status, 'Video privacy status: public, private, or unlisted',
              :default => 'public',
              :type => String
          opt :publish_at, 'date time',
              :default => video_data['ActiveDate'],
              :type => Date
          opt :license, 'youtube standard license',
              :default => 'youtube',
              :type => String
          opt :embeddable, 'true/false',
              :default => true,
              :type => :boolean
          opt :public_stats_viewable, 'true/false',
              :default => true,
              :type => :boolean
          opt :location_description, 'Crossroads Church',
              :default => 'Crossroads Church',
              :type => String
          opt :latitude, 'Crossroads Church',
              :default => 39.1591796875,
              :type => :double
          opt :longitude, 'Crossroads Church',
              :default => 84.4229736328,
              :type => :double
          opt :recording_date, 'video record date',
              :default => video_data['RecordDate'],
              :type => Date
          opt :series_id, 'message series_id',
              :default => series_id,
              :type => :int
          opt :message_id, 'video message_id',
              :default => message_id,
              :type => :int
          opt :media_content_id, 'video media_content_id',
              :default => video_data['MediaContentID'],
              :type => :int
        end
        return opts
      end
    end

    #
    # Function used to create youtube video reference entry in database
    #
    def create_entry_in_db(youtube_video_id, video_data)
      begin
        sql_query = self.prepare_db_query(youtube_video_id, video_data)
        dbh = Immutable.dbh.execute(sql_query)
        puts "DB insert query : #{sql_query}"
        puts 'Record has been created'
        dbh.commit
      rescue DBI::DatabaseError => e
        puts 'An error occurred'
        puts "Error code:    #{e.err}"
        puts "Error message: #{e.errstr}"
        dbh.rollback
      ensure
        disconnect from server
        dbh.disconnect if dbh
      end
    end

    #
    # Function used to prepare db insert query
    #
    def prepare_db_query(youtube_video_id, video_data)
      begin
        insert_data = Hash.new
        insert_data['media_content_id'] = 0
        insert_data['content_type_id'] = 0
        sql_query= ''
        date_time = Time.now.strftime('%Y-%m-%d %H:%M:%S')
        insert_data['youtube_video_id'] = youtube_video_id
        insert_data['series_id'] = video_data['message_id']
        insert_data['message_id'] = video_data['message_id']
        insert_data['media_content_id'] = video_data['MediaContentID']
        insert_data['content_type_id'] = video_data['ContentTypeID']
        sql_query =  " INSERT INTO milacron_youtube_references "
        sql_query += " (id, youtube_video_id, message_id, media_content_id, "
        sql_query += " content_type_id, create_dt, update_dt) "
        sql_query += " VALUES ('null', '#{insert_data['youtube_video_id']}', "
        sql_query += " #{insert_data['message_id']}, #{insert_data['media_content_id']}, "
        sql_query += " #{insert_data['content_type_id']}, #{date_time}, #{date_time}) "
        return sql_query
      end
    end

    #
    # Function used to get response as array
    #
    def normalize_response_data(response)
      begin
        video_id = response.unique_id
        puts 'Video was successfully uploaded'
        video_id
      end
    end

  end
end