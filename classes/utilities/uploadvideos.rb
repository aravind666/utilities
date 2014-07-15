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
    self.upload_video
  end

  #
  # Function used to upload videos to youtube
  #
  def upload_video
    begin
      File.delete('not_existing_video_files.log') if File.exist?('not_existing_video_files.log')
      youtube_response = Hash.new
      youtube_response['youtube_video_id'] = 0
      get_all_video_data = YouTubeHelper.get_only_video_data
      get_all_video_data.each do |video_data|
        youtube_response = YouTubeHelper.upload_video_to_youtube(video_data, UploadVideos)
        puts "media_content_id: #{video_data[:media_content_id]}"
        puts "Video file '#{video_data[:file]}'"
        response_data = YouTubeHelper.normalize_response_data(youtube_response)
        if response_data['upload_status'] == 'uploaded'
          YouTubeHelper.create_entry_in_db(response_data, video_data)
        end
      end
    end
  end

end