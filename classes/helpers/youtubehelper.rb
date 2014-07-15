# encoding: ASCII-8BIT
#
# YouTubeHelper. class which defines various attributes and behaviours
# which are used to upload videos to youtube
#
# Author::    Hanumantharaju  (mailto:hanumantharaju.tswamy@costrategix.com)
# Copyright:: Copyright (c) 2012 Crossroads
# License::   MIT
#
#
class YouTubeHelper

  def initialize
    # initialize required variables
  end

  class << self

    #
    # Function used to authenticate user
    #
    def get_authenticated_service
      begin
        client = ''
        youtube = ''
        credentials_file = Immutable.config.youtube_client_secrete_json
        if File.exist? credentials_file
          client = Google::APIClient.new(
              :application_name => Immutable.config.application_name,
              :application_version => Immutable.config.application_version
          )
          youtube = client.discovered_api(Immutable.config.youtube_service_name,
                                          Immutable.config.youtube_api_version
          )
          auth_util = CommandLineOAuthHelper.new(Immutable.config.youtube_scope)
          client.authorization = auth_util.authorize(Immutable.config.user_oauth_json)
          client.authorization
        else
          puts 'client auth info file required'
          abort
        end
        return client, youtube
      end
    end

    #
    # Function used to get client object
    #
    def get_yt_client_object
      begin
        client = YouTubeIt::Client.new(
            :username => Immutable.config.youtube_username,
            :password =>  Immutable.config.youtube_password,
            :dev_key  => Immutable.config.youtube_dev_key
        )
        client
      end
    end

    #
    # Function used to upload videos to youtube
    #
    def upload_video_to_youtube(video_data, class_name)
      begin
        request_body = self.create_request_body(video_data)
        uri = Mediahelper.get_url_encoded_file(video_data[:file])
        video_file_array = uri.path.split('/')
        video_destination_path = "#{Immutable.config.s3_video_download_local_path}#{video_file_array.last}"
        unless File.exists?(video_destination_path.to_s)
          Mediahelper.http_download_uri(uri, video_destination_path)
        else
          puts "Skipping download for '#{video_file_array.last}' It already exists."
        end
        client, youtube = self.get_authenticated_service
        videos_insert_response = client.execute!(
            :api_method => youtube.videos.insert,
            :body_object => request_body,
            :media => Google::APIClient::UploadIO.new(video_destination_path, 'video/*'),
            :parameters => {
                :uploadType => 'multipart',
                :part => request_body.keys.join(',')
            }
        )
        # delete the file if upload status is success
        if videos_insert_response.data.status.uploadStatus == 'uploaded'
          File.delete(video_destination_path) if File.exist?(video_destination_path)
        end
        return videos_insert_response
      rescue Google::APIClient::TransmissionError => e
        puts e.result.body
        puts 'Access token has been expired get the new access token and upload video again'
        class_name.new
      end
    end

    #
    # Function used to add videos to playlist
    #
    def add_video_to_playlist(playlist_id, video_id, position=1)
      begin
        client, youtube = self.get_authenticated_service
        request_body = self.get_playlist_request_body(playlist_id, video_id, position)
        playlist_response = client.execute!(
            :api_method => youtube.playlist_items.insert,
            :body_object => request_body,
            :parameters => {
                :part => request_body.keys.join(',')
            }
        )
        return playlist_response
      end
    end

    #
    # Function used to get all message videos to upload youtube
    #
    def get_message_video_data
      begin
        video_data_array = []
        series_data = Mediahelper.get_all_series
        if series_data.fetchable?
          series_data.each do |series|
            series_massage_data = Mediahelper.get_all_messages_for_series(series[0])
            video_data_array << self.get_message_video_list(series[0], series_massage_data)
          end
        end
        video_data_array
      end
    end

    #
    # Function used to get message video list to upload
    #
    def get_message_video_list(series_id, series_massage_data)
      begin
        message_video_data_array = {}
        if series_massage_data.fetchable?
          series_massage_data.each do |message|
            if message['MessageID'] > 0
              message_media_data = Mediahelper.get_video_media_content_for_message(message[0])
              message_video_data_array = self.get_message_video_content(series_id, message[0], message_media_data)
            end
          end
        end
        message_video_data_array
      end
    end

    #
    # Function used to get message video to upload
    # it filters the video which are already present youtube
    #
    def get_message_video_content(series_id, message_id, message_media_data)
      begin
        message_video_data_array = {}
        if message_media_data.fetchable?
          message_media_data.each do |media|
            video_exist_flag = self.check_video_exist_in_youtube(media)
            if video_exist_flag == 0
              if self.remote_file_exists?(media['iPodVideo'])
                message_video_data_array = self.create_video_data(media, series_id, message_id)
              else
                log_message = "Mediacontent Id  #{media['MediaContentID']}, file: #{media['iPodVideo']}"
                File.open('not_existing_message_video_files.log', 'a+') { |f| f.write(log_message + "\n") }
              end
            end
          end
        else
          Immutable.log.info "There are no video content available for media:#{message_id}"
        end
        message_video_data_array
      end
    end

    #
    # Function used to all videos
    #
    def get_only_video_data
      begin
        video_data_array = []
        ipod_video_data = Mediahelper.get_media_content
        if ipod_video_data.fetchable?
          video_data_array = self.get_video_list(ipod_video_data)
        else
          Immutable.log.info 'There are no video content available'
        end
        video_data_array
      end
    end

    #
    # Function used to get video list to upload
    # it filters the video which are already present youtube
    #
    def get_video_list(video_data_structure)
      begin
        video_data_list = []
        video_data_structure.each do |video_data|
          if video_data['iPodVideo'].length > 0
            video_exist_flag = self.check_video_exist_in_youtube(video_data)
            if video_exist_flag == 0
              if self.remote_file_exists?(video_data['iPodVideo'])
                video_data_list << create_video_data(video_data, 0, 0)
              else
                log_message = "Mediacontent Id  #{video_data['MediaContentID']}, file: #{video_data['iPodVideo']}"
                File.open('not_existing_video_files.log', 'a+') { |f| f.write(log_message + "\n") }
              end
            end
          end
        end
        video_data_list
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
        publish_at = video_data['ActiveDate'].utc.iso8601(1)
        record_date =video_data['RecordDate'].utc.iso8601(3)
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
          opt :channel_id, 'youtube channel id',
              :default => Immutable.config.youtube_channel_id,
              :type => String
          opt :tags, 'Video keywords, comma-separated',
              :default => '',
              :type => String
          opt :category_id, 'category',
              :default => 22,
              :type => :int
          opt :privacy_status, 'Video privacy status: public, private, or unlisted',
              :default => 'public',
              :type => String
          opt :publish_at, 'date time',
              :default => publish_at,
              :type => String
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
          opt :latitude, 'latitude value',
              :default => 39.1591796875,
              :type => :double
          opt :longitude, 'longitude value',
              :default => 84.4229736328,
              :type => :double
          opt :recording_date, 'video record date',
              :default => record_date,
              :type => String
          opt :series_id, 'message series_id',
              :default => series_id,
              :type => :int
          opt :message_id, 'video message_id',
              :default => message_id,
              :type => :int
          opt :media_content_id, 'video media_content_id',
              :default => video_data['MediaContentID'],
              :type => :int
          opt :media_content_type_id, 'video media_content_type_id',
              :default => video_data['ContentTypeID'],
              :type => :int
        end
        return opts
      end
    end

    #
    # Function used to create youtube request body
    # "publishedAt"=>"2014-07-11T06:10:07.000Z"
    # :publishAt=> request_data[:publish_at],
    #
    def create_request_body(request_data)
      begin
        body = {
            :snippet => {
                :title => request_data[:title],
                :description => request_data[:description],
                :tags => request_data[:tags].split(','),
                :categoryId => request_data[:category_id],
            },
            :status=> {
                :privacyStatus=> request_data[:privacy_status],
                :channelId => request_data[:channel_id],
                :license=> request_data[:license],
                :embeddable=> request_data[:embeddable],
                :publicStatsViewable=> request_data[:public_stats_viewable],

            },
            :recordingDetails=> {
                :locationDescription=> request_data[:location_description],
                :location=> {
                    :latitude=> request_data[:latitude],
                    :longitude=> request_data[:longitude],
                },
                :recordingDate=> request_data[:recording_date]
            }
        }
        body
      end
    end

    #
    # Function used to create youtube video reference entry in database
    #
    def create_entry_in_db(yt_response_data, video_data)
      begin
        sql_query = self.prepare_db_query(yt_response_data, video_data)
        Immutable.dbh.execute(sql_query)
        puts 'Record has been created in DB'
      rescue DBI::DatabaseError => e
        Immutable.log.error "Error code: #{e.err}"
        Immutable.log.error "Error message: #{e.errstr}"
        Immutable.log.error "Error SQLSTATE: #{e.state}"
        abort('An error occurred while DB insertion, Check migration log for more details')
      end
    end

    #
    # Function used to prepare db insert query
    #
    def prepare_db_query(yt_response_data, video_data)
      begin
        insert_data = Hash.new
        sql_query= ''
        date_time = Time.now.strftime('%Y-%m-%d %H:%M:%S')
        insert_data['video_id'] = yt_response_data['video_id']
        insert_data['embed_url']= yt_response_data['embed_url']
        insert_data['series_id'] = video_data[:series_id] ? video_data[:series_id] : 0
        insert_data['message_id'] = video_data[:message_id] ? video_data[:message_id] : 0
        insert_data['media_content_id'] = video_data[:media_content_id] ? video_data[:media_content_id] : 0
        insert_data['content_type_id'] =  video_data[:media_content_type_id] ? video_data[:media_content_type_id] : 0
        sql_query =  " INSERT INTO milacron_youtube_references "
        sql_query += " (id, video_id, embed_url, message_id, media_content_id, "
        sql_query += " content_type_id, create_dt_tm, update_dt_tm) "
        sql_query += " VALUES (null, '#{insert_data['video_id']}', '#{insert_data['embed_url']}', "
        sql_query += " #{insert_data['message_id']}, #{insert_data['media_content_id']}, "
        sql_query += " #{insert_data['content_type_id']}, '#{date_time}', '#{date_time}') "
        return sql_query
      end
    end

    #
    # Function used to get youtube response data
    #
    def normalize_response_data(response)
      begin
        response_data = Hash.new
        response_data['video_id'] = response.data.id
        response_data['video_title'] = response.data.snippet.title
        response_data['upload_status'] = response.data.status.uploadStatus
        if response_data['upload_status'] != 'uploaded'
          response_data['failure_reason'] = response.data.status.failureReason
          response_data['rejection_reason'] = response.data.status.rejectionReason
        end
        response_data['embed_url'] = 'http://www.youtube.com/v/'
        puts "Video has been successfully #{response_data['upload_status']}"
        response_data
      end
    end

    #
    # Function used to check the video file exist or not
    #
    def check_video_exist_in_youtube(video_data)
      begin
        flag = 0
        sql_query = "SELECT id FROM milacron_youtube_references WHERE  "
        sql_query += "media_content_id=#{video_data['MediaContentID']} AND "
        sql_query += "content_type_id=#{video_data['ContentTypeID']} AND delete_flag='0' "
        row = Immutable.dbh.select_one(sql_query)
        if !row.nil?
          if row[:id]
            flag = 1
          end
        end
        flag
      end
    end

    #
    # Function used to get video ids from db which
    # are need to add youtube playlist
    #
    def get_message_video_ids(content_type_id)
      begin
        sql_query = "SELECT * FROM milacron_youtube_references WHERE content_type_id=#{content_type_id} AND delete_flag='0'"
        results = Immutable.dbh.execute(sql_query)
        return results
      end
    end

    #
    # Function used to get messages youtube video id and embed url
    #
    #
    def get_message_video_yt_data(message_id, media_content_id, content_type_id)
      begin
        response_hash = Hash.new
        sql_query = "SELECT * FROM milacron_youtube_references "
        sql_query += "WHERE message_id=#{message_id} AND media_content_id=#{media_content_id} "
        sql_query += "AND content_type_id=#{content_type_id} AND delete_flag='0' "
        results = Immutable.dbh.execute(sql_query)
        if results.fetchable?
          results.each { |message_data|
            response_hash['video_id'] = message_data['video_id']
            response_hash['embed_url'] = message_data['embed_url']
          }
        end
        return response_hash
      end
    end

    #
    # Function used to get messages youtube video id and embed url
    #
    #
    def get_video_content_yt_data(media_content_id, content_type_id)
      begin
        response_hash = Hash.new
        sql_query = "SELECT * FROM milacron_youtube_references "
        sql_query += "WHERE media_content_id=#{media_content_id} "
        sql_query += "AND content_type_id=#{content_type_id} AND delete_flag='0' "
        results = Immutable.dbh.execute(sql_query)
        if results.fetchable?
          results.each { |video_data|
            response_hash['video_id'] = video_data['video_id']
            response_hash['embed_url'] = video_data['embed_url']
          }
        end
        return response_hash
      end
    end

    #
    # Function used to get uploaded video list from milacron_youtube_references table
    #
    #
    def get_uploaded_video_list
      begin
        sql_query = "SELECT * FROM milacron_youtube_references "
        sql_query += "WHERE delete_flag='0' "
        results = Immutable.dbh.execute(sql_query)
        return results
      end
    end

    #
    # Function used to check if file exists on a remote server
    #
    def remote_file_exists?(file)
      begin
        # Support for both good and bad URI's
        uri = Mediahelper.get_url_encoded_file(file)
        response = nil
        Net::HTTP.start(uri.host, uri.port) {|http|
          response = http.head(uri.path)
        }
        response.code =='200'
      rescue
        false
      end
    end

    #
    # Function used to get utc format datetime
    #
    def get_required_time_format(time)
      begin
        Time.utc(time.year,time.month,time.day,time.hour,time.min,time.sec,"#{time.usec}".to_r)
      end
    end

    #
    # Function used to prepare playlist item request body
    #
    def get_playlist_request_body(playlist_id, video_id, position)
      begin
        body = {
            :snippet=> {
                :channelId => Immutable.config.youtube_channel_id,
                :playlistId => playlist_id,
                :resourceId => {
                    :kind => 'youtube#video',
                    :videoId => video_id,
                },
            }
        }
        body
      end
    end
  end

end