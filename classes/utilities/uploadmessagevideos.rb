# encoding: ASCII-8BIT
#
# UploadMessageVideos. class which defines various attributes and behaviours
# which are used to upload message videos to youtube
#
# Author::    Hanumantharaju  (mailto:hanumantharaju.tswamy@costrategix.com)
# Copyright:: Copyright (c) 2012 Crossroads
# License::   MIT
#
# Initiating this class leads to uploading videos to youtube
#
class UploadMessageVideos

  #
  # Initialize the message video uploading process
  #
  def initialize
    self.upload_message_video
  end

  #
  # Function used to upload message videos to youtube
  #
  def upload_message_video
    begin
      File.delete('not_existing_message_video_files.log') if File.exist?('not_existing_message_video_files.log')
      youtube_response = Hash.new
      youtube_response['youtube_video_id'] = 0
      video_data_array = YouTubeHelper.get_message_video_data
      video_data_array.each do |video_data|
        video_data.each do |data|
          youtube_response = YouTubeHelper.upload_video_to_youtube(data[0], UploadMessageVideos)
          puts "media_content_id: #{data[0][:media_content_id]}"
          puts "Video file '#{data[0][:file]}'"
          response_data = YouTubeHelper.normalize_response_data(youtube_response)
          if response_data['upload_status'] == 'uploaded'
            YouTubeHelper.create_entry_in_db(response_data, data[0])
          end
        end
      end
    end
  end

end