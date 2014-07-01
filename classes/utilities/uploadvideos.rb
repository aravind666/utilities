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

  #
  # Initialize the video uploading process
  #
  def initialize
    self.process_upload_video
    #self.upload_video
  end

  #
  # Function used to process each media content detail
  # and upload video to youtube
  #
  #
  def process_upload_video
    insert_data = []
    get_all_video_data = YouTubeHelper.get_all_video_from_db
    get_all_video_data.each do |video_data|
      opts = YouTubeHelper.create_video_data(video_data)
      body = YouTubeHelper.get_youtube_body_request_data(opts)
    youtube_response = self.upload_video(opts, body)
    insert_data['video_title'] << youtube_response['title']
    insert_data['youtube_video_id'] << youtube_response['id']
    insert_data['message_id'] << video_data['message_id']
    insert_data['media_content_id'] << video_data['MediaContentID']
    insert_data['content_type_id'] << video_data['ContentTypeID']
      result = YouTubeHelper.create_entry_in_db(youtube_response)
      puts "Video information saved to DB #{result}"
    end
  end

  #
  # Function used to upload videos to youtube
  #
  #
  def upload_video(opts, body)
  #def upload_video
    opts = Trollop::options do
      opt :file, 'Video file to upload',
          :default => system('curl -s https://s3.amazonaws.com/crossroadsvideomessages/go-forth-01.mp4 -o go-forth-01.mp4'),
      #'/var/www/csurgeries_20130530101513.mp4',
          :type => String
      opt :title, 'Video title',
          :default => 'Milacron Test video upload',
          :type => String
      opt :description, 'Video description',
          :default => 'Test Description',
          :type => String
      opt :keywords, 'Video keywords, comma-separated',
          :default => 'Test',
          :type => String
      opt :privacy_status, 'Video privacy status: public, private, or unlisted',
          :default => 'public',
          :type => String
    end
    if opts[:file].nil? or not File.file?(opts[:file])
      Trollop::die :file, 'does not exist'
    end

    begin
      client, youtube = YouTubeHelper.get_authenticated_service
      body = {
          :snippet => {
              :title => opts[:title],
              :description => opts[:description],
              :tags => opts[:keywords].split(','),
              :categoryId => opts[:category_id],
          },
          :status => {
              :privacyStatus => opts[:privacy_status]
          }
      }
      videos_insert_response = client.execute!(
          :api_method => youtube.videos.insert,
          :body_object => body,
          :media => Google::APIClient::UploadIO.new(opts[:file], 'video/*'),
          :parameters => {
              :uploadType => 'multipart',
              :part => body.keys.join(',')
          }
      )
      response_result_array = []
      #p videos_insert_response
      #videos_insert_response.resumable_upload.send_all(client)
      response_result_array['youtube_video_id'] << videos_insert_response.data.id
      puts 'Video was successfully uploaded.'
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