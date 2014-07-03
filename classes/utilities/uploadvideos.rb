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
  # Initialize the video uploading videos process
  #
  def initialize
    self.upload_video
  end

  #
  # Function used to upload videos to youtube
  #
  def upload_video
    begin
      youtube_response = Hash.new
      youtube_response['youtube_video_id'] = 0
      get_all_video_data = YouTubeHelper.get_only_video_data
      get_all_video_data.each do |video_data|
        youtube_response = YouTubeHelper.upload_video_to_youtube(video_data)
        puts "Video file '#{video_data[:file]}' uploaded successfully"
        video_id = YouTubeHelper.normalize_response_data(youtube_response)
        YouTubeHelper.create_entry_in_db(video_id, video_data)
        abort
      end
    end
  end

end