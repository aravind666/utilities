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
class UploadVideos

  include YouTubeModule
  #
  # Initialize the video uploading process
  #
  def initialize(method_name)
    self.start_upload_videos(method_name)
  end

  #
  # Function used to upload videos to youtube
  #
  def start_upload_videos(method_name)
    case method_name
      when 'video'
        self.upload_video
      when 'message_video'
        self.upload_message_video
      else
        puts "undefined method name for the class:#{class_name}"
    end
  end

  #
  # Function used to upload message videos to youtube
  #
  def upload_message_video
    insert_data = Hash.new
    get_all_video_data = YouTubeHelper.get_message_video_data
    get_all_video_data.each do |video_data|
      body = YouTubeHelper.get_youtube_body_request_data(video_data)
      if video_data[:file]!= ''
        youtube_response = self.upload_video_to_youtube(video_data, body)
        #puts youtube_response
        #abort 'youtube response'
        insert_data['video_title'] = youtube_response['title']
        insert_data['youtube_video_id'] = youtube_response['id']
      end
      insert_data['youtube_video_id'] = 0
      insert_data['series_id'] = video_data['message_id']
      insert_data['message_id'] = video_data['message_id']
      insert_data['media_content_id'] = video_data['MediaContentID']
      insert_data['content_type_id'] = video_data['ContentTypeID']
      #result = YouTubeHelper.create_entry_in_db(insert_data)

      #To check how many video files need to be upload
      #migrated_audio_file_handler = File.open('/var/www/test_video_data.txt', 'a+')
      #migrated_audio_file_handler.write(body)
      #migrated_audio_file_handler.write("\n")
      #migrated_audio_file_handler.close
      puts "Video information saved to DB"
    end
  end

  #
  # Function used to upload videos to youtube
  #
  def upload_video
    insert_data = Hash.new
    get_all_video_data = YouTubeHelper.get_only_video_data
    get_all_video_data.each do |video_data|
      body = YouTubeHelper.get_youtube_body_request_data(video_data)
      #puts body
      #abort
      if video_data[:file]!= ''
        youtube_response = self.upload_video_to_youtube(video_data, body)
        insert_data['video_title'] = youtube_response['title']
        insert_data['youtube_video_id'] = youtube_response['id']
      end
      insert_data['youtube_video_id'] = 0
      insert_data['series_id'] = video_data['message_id']
      insert_data['message_id'] = video_data['message_id']
      insert_data['media_content_id'] = video_data['MediaContentID']
      insert_data['content_type_id'] = video_data['ContentTypeID']
      #result = YouTubeHelper.create_entry_in_db(insert_data)
      puts 'Video information saved to DB'
    end
  end

  #
  # Function used to upload videos to youtube
  #
  #
  def upload_video_to_youtube(opts, body)
    opts[:file] = '/var/www/test1234.mp4'
    if opts[:file].nil? or not File.file?(opts[:file])
      Trollop::die :file, 'does not exist'
    end
    response_result_array = Hash.new
    begin
      client, youtube = YouTubeHelper.get_authenticated_service
      videos_insert_response = client.execute!(
          :api_method => youtube.videos.insert,
          :body_object => body,
          :media => Google::APIClient::UploadIO.new(opts[:file], 'video/*'),
          :parameters => {
              :uploadType => 'multipart',
              :part => body.keys.join(',')
          }
      )
      #p videos_insert_response.data
      #videos_insert_response.resumable_upload.send_all(client)
      response_result_array['youtube_video_id'] = videos_insert_response.data.id
      response_result_array['youtube_video_title'] = videos_insert_response.data.snippet.title
      response_result_array['youtube_video_publish_at'] = videos_insert_response.data.snippet.publishedAt
      response_result_array['youtube_video_uploaded_status'] = videos_insert_response.data.status.uploadStatus
      puts "Video was successfully #{response_result_array['youtube_video_uploaded_status']}"
      return response_result_array
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
        CommandLineOAuthHelper.refresh_access_token(USER_ACCESS_TOKEN_INFO, YOUTUBE_CLIENT_SECRETE, UploadVideos)
      else
        puts e.result.body
      end
    end
  end
end