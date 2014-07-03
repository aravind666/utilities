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
      video_id_array = self.get_video_ids_to_add_playlist
      if video_id_array.size > 0
        video_id_array.each { |video_id|
          YouTubeHelper.add_video_to_playlist(playlist_id, video_id, position=1)
          puts "Video:'#{video_id}' add to playlist successfully"
        }
      end
    end
  end

  #
  # Function used to get video ids
  #
  def get_video_ids_to_add_playlist
    begin
      video_id_array = Array.new
      video_id_result = YouTubeHelper.get_video_ids
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