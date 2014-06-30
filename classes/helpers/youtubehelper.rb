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

  end
  class << self

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

    def get_all_video_from_db
      video_data = ''
      video_data_array = create_video_data(video_data)
      request_body = get_youtube_body_request_data(video_data_array)
      return request_body
    end

    def create_video_data(video_data)
      opts = Trollop::options do
      opt :file, 'Video file to upload',
          :default => video_data['filename'],
          :type => String
      opt :title, 'Video title',
          :default => 'Milacron Test video upload',
          :type => String
      opt :description, 'Video description',
          :default => 'Test Description',
          :type => String
      opt :tags, 'Video keywords, comma-separated',
          :default => 'Test',
          :type => String
      opt :category_id, 'category',
          :default => 'People & Blogs',
          :type => String
      opt :privacy_status, 'Video privacy status: public, private, or unlisted',
          :default => 'public',
          :type => String
      opt :publish_at, 'date time',
          :default => '2014-06-30',
          :type => String
      opt :license, 'youtube standard license',
          :default => 'youtube standard license',
          :type => String
      opt :embeddable, 'true/false',
          :default => true,
          :type => Boolean
      opt :public_stats_viewable, 'true/false',
          :default => true,
          :type => Boolean
      opt :location_description, 'Crossroads Church',
          :default => 'Crossroads Church',
          :type => String
      opt :latitude, 'Crossroads Church',
          :default => '39.1591796875',
          :type => double
      opt :longitude, 'Crossroads Church',
          :default => '84.4229736328',
          :type => double
      opt :recording_date, 'video record date',
          :default => '204-06-30',
          :type => datetime
      end
    end

    def get_youtube_body_request_data(request_data)

      body = {
          :snippet=> {
              :title=> request_data[:title],
              :description=> request_data[:description],
              :tags=> request_data[:tags].split(','),
              #:categoryId=> ' People & Blogs',
          },
          :status=> {
              :privacyStatus=> request_data[:title],
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
    end

    def create_entry_in_db(video_data)
      begin
        sql_query =  "INSERT INTO milacron_youtube_references "
        sql_query += "(id, youtube_video_id, message_id, media_content_id, content_type_id) "
        sql_query += "VALUES ('null', #{video_data['youtube_video_id']}, "
        sql_query += " #{video_data['message_id']}, #{video_data['media_content_id']}, #{video_data['content_type_id']}) "
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