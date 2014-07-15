# encoding: ASCII-8BIT
#
# MyUploads. class which defines various attributes and behaviours
# which are used to check the status of uploaded videos and log the
# rejected video with the rejection reason to a DB or a file
#
# Author::    Hanumantharaju  (mailto:hanumantharaju.tswamy@costrategix.com)
# Copyright:: Copyright (c) 2012 Crossroads
# License::   MIT
#
class MyUploads

  #
  # Initialize to check the uploaded video status and log the rejected videos
  #
  def initialize
    self.process_uploaded_videos
  end

  #
  # Function used to process each video to check the uploaded video status
  #
  def process_uploaded_videos
    begin
      File.delete('rejected_video.log') if File.exist?('rejected_video.log')
      uploaded_video_list = YouTubeHelper.get_uploaded_video_list
      if uploaded_video_list.fetchable?
        uploaded_video_list.each { |video_data|
          self.get_video_status(video_data)
        }
        puts "Logged the rejected video to 'rejected_video.log' file"
      end
    end
  end

  #
  # Function used to get the uploaded video status from youtube
  #
  def get_video_status(video_data)
    begin
      client, youtube = YouTubeHelper.get_authenticated_service
      video_status_data = client.execute!(
          :api_method => youtube.videos.list,
          :parameters => {
              :id => video_data['video_id'],
              :part => 'status'
          }
      )
      self.log_rejected_video(video_status_data, video_data)
    rescue Google::APIClient::TransmissionError => e
      puts e.result.body
    end
  end

  #
  # Function used to log the rejected video with reason
  #
  def log_rejected_video(video_status_data, video_data)
    begin
      log_message = ''
      video_status_data.data.items.each do |video_response|
        if video_response['status']['uploadStatus'] == 'rejected'
          upload_status = video_response['status']['uploadStatus']
          rejection_reason = video_response['status']['rejectionReason']
          log_message = "media_content_id : #{video_data['media_content_id']} \n"
          log_message += "video_id : #{video_data['video_id']} \n"
          log_message += "video upload_status : #{upload_status} \n"
          log_message += "video rejection_reason : #{rejection_reason}\n"
          log_message += "================================================\n"
          File.open('rejected_video.log', 'a+') { |f| f.write(log_message + "\n") }
        end
      end
    end
  end

end