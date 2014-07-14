# encoding: ASCII-8BIT
#
# AddVideosToPlayList. class which defines various attributes and behaviours
# which are used to add videos to playlist
#
# Author::    Hanumantharaju  (mailto:hanumantharaju.tswamy@costrategix.com)
# Copyright:: Copyright (c) 2012 Crossroads
# License::   MIT
#
class AddVideosToPlayList

  #
  # Initialize the add video to youtube playlist process
  #
  def initialize
    playlist_id = Immutable.config.youtube_playlist_id
    self.add_video_to_playlist(playlist_id)
  end

  #
  # Function used to add video to youtube playlist
  #
  def add_video_to_playlist(playlist_id)
    begin
      video_id_array = self.get_video_ids_to_add_playlist(4)
      if video_id_array.size > 0
        video_id_array.each { |video_id|
          playlist_response = YouTubeHelper.add_video_to_playlist(playlist_id, video_id, position=1)
          if playlist_response.success?
            puts "Video:'#{video_id}' add to playlist successfully"
         else
           puts "Error in addind video to playlist successfully#{playlist_response.body}"
         end
        }
      end
    end
  end

  #
  # Function used to get message video ids
  # param content_type_id=4  for message videos
  #
  def get_video_ids_to_add_playlist(content_type_id=4)
    begin
      video_id_array = Array.new
      video_id_result = YouTubeHelper.get_message_video_ids(content_type_id)
      if video_id_result.fetchable?
        video_id_result.each do |video_data|
          if video_data['id'] > 0
            video_id_array << video_data['video_id']
          end
        end
      end
      video_id_array
    end
  end

end