require 'rubygems'
gem 'google-api-client', '>0.7'
require 'google/api_client'
require 'google/api_client/client_secrets'
require 'google/api_client/auth/file_storage'
require 'google/api_client/auth/installed_app'
require 'trollop'
require_relative 'immutable'

#require 'rubygems'
#gem 'google-api-client', '>0.7'
#require 'google/api_client'
#require 'google/api_client/client_secrets'
#require 'google/api_client/auth/file_storage'
#require 'google/api_client/auth/installed_app'

class YouTubeHelper

  # This OAuth 2.0 access scope allows for read-only access to the authenticated
  # user's account, but not other types of account access.
  YOUTUBE_READONLY_SCOPE = 'https://www.googleapis.com/auth/youtube.readonly'
  YOUTUBE_API_SERVICE_NAME = 'youtube'
  YOUTUBE_API_VERSION = 'v3'
  USER_ACCESS_TOKEN_INFO = Immutable.config.user_oauth_json
  YOUTUBE_CLIENT_SECRETE = Immutable.config.youtube_client_secrete_json

  def initialize
    # initialize required variables
  end

  class << self

    #
    # Function used to authenticate the user credentials
    #
    def get_authenticated_service
      begin
        client = Google::APIClient.new(:application_name => 'Milacron', :application_version => '1.0')
        youtube = client.discovered_api(YOUTUBE_API_SERVICE_NAME, YOUTUBE_API_VERSION)
        auth_util = CommandLineOAuthHelper.new(YOUTUBE_READONLY_SCOPE, YOUTUBE_CLIENT_SECRETE)
        client.authorization = auth_util.authorize(USER_ACCESS_TOKEN_INFO)
        return client, youtube
      rescue Google::APIClient::TransmissionError => e
        response_hash = JSON.parse(e.result.body)
        result_hash = Hash.new
        response_hash = response_hash['error']['errors'].to_enum
        response_hash.each { |val| result_hash = val }
        #p result_hash
        #puts "val:#{result_hash['reason']}"
        #abort
        #p result_hash
        if result_hash['reason'] == 'authError'
          puts 'Get new access token using refresh token'
          CommandLineOAuthHelper.refresh_access_token(USER_ACCESS_TOKEN_INFO, YOUTUBE_CLIENT_SECRETE, PlayList)
        else
          puts e.result.body
        end
      end
    end

    #
    # Function used to all message videos
    #
    def get_message_video_data
      video_data_array = []
      series_data = Mediahelper.get_all_series
      if series_data.fetchable?
        series_data.each do |series|
          series_massage_data = Mediahelper.get_all_messages_for_series(series[0])
          #video_data_array = self.process_message_data(series_massage_data,series[0])
          if series_massage_data.fetchable?
            series_massage_data.each do |message|
              #puts message['MessageID']
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
      #migrated_audio_file_handler = File.open('/var/www/test_video_data.txt', 'w')
      #migrated_audio_file_handler.write(video_data_array)
      #migrated_audio_file_handler.close
      #abort
    end

    #
    # Function used to all videos
    #
    def get_only_video_data
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

    #
    # Function used to process message media content
    #
    def process_message_data(message_data, series_id)
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
      migrated_audio_file_handler = File.open('/var/www/test_video_data.txt', 'w')
      migrated_audio_file_handler.write(video_data_hash+'\n')
      migrated_audio_file_handler.close
    end

    #
    # Function used to process message video content
    #
    def process_message_video_data(video_data, series_id)
      video_data_array = []
      if video_data.size > 0
        video_data.each do |video|
          puts video['iPodVideo']
          puts video['MessageID']
          puts video['MediaContentID']
          if video['iPodVideo'].length > 0
            video_data_array << create_video_data(video, series_id, video['MessageID'])
          end
        end
      else
        Immutable.log.info "There are no video content available for message_id:#{video['MessageID']}"
      end
    end

    #
    # Function used to create Trollop video data options
    #
    def create_video_data(video_data, series_id=0, message_id=0)
      video_description = video_data['Description']
      video_description = video_description.strip_control_characters
      video_description = video_description.encode('utf-8', 'binary', :invalid => :replace,:undef => :replace, :replace => '')
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
        #opt :publish_at, 'date time',
        #    :default => video_data['ActiveDate'],
        #    :type => Date
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
        #opt :recording_date, 'video record date',
        #    :default => video_data['RecordDate'],
        #    :type => Date
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

    #
    # Function used to get youtube video request body
    #
    def get_youtube_body_request_data(request_data)

      body = {
          :snippet=> {
              :title=> request_data[:title],
              :description=> request_data[:description],
              :tags=> request_data[:tags].split(','),
              #:categoryId=> ' People & Blogs',
          },
          :status=> {
              :privacyStatus=> request_data[:privacy_status],
              #:publishAt=> request_data[:title] #'2014-06-30T4:44:56.1234Z',
              #:license=> request_data[:title] #'youtube standard license',
              :embeddable=> request_data[:embeddable],
              :publicStatsViewable=> request_data[:public_stats_viewable]
          },
          :recordingDetails=> {
              :locationDescription=> 'Crossroads Church',
              :location=> {
                  :latitude=> request_data[:latitude],
                  :longitude=> request_data[:longitude]
              },
              :recordingDate=> request_data[:recording_date] #'2014-06-30T4:44:56.1234Z'
          }
      }
      return body
    end

    #
    # Function used to create youtube video reference entry in database
    #
    def create_entry_in_db(video_data)
      begin
        date_time = Time.now.strftime('%Y-%m-%d %H:%M:%S')
        sql_query =  " INSERT INTO milacron_youtube_references "
        sql_query += " (id, youtube_video_id, message_id, media_content_id, "
        sql_query += " content_type_id, create_dt, update_dt) "
        sql_query += " VALUES ('null', #{video_data['youtube_video_id']}, "
        sql_query += " #{video_data['message_id']}, #{video_data['media_content_id']}, "
        sql_query += " #{video_data['content_type_id']}, #{date_time}, #{date_time}) "
        dbh = Immutable.dbh.execute(sql_query)
        puts 'Record has been created'
        dbh.commit
      rescue DBI::DatabaseError => e
        puts 'An error occurred'
        puts "Error code:    #{e.err}"
        puts "Error message: #{e.errstr}"
        dbh.rollback
      ensure
        # disconnect from server
        dbh.disconnect if dbh
      end
    end
  end
end