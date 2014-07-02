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
  # Initialize the audio content migration process
  #
  def initialize
    self.add_video_to_playlist('PL4k-hIu-yqFLQ0lZ_jJkFm7atqmMlWn3z', 'xFE3o0ASf94', 1)
  end

  def add_video_to_playlist(playlist_id, video_id, position=1)
    begin
      YouTubeHelper.add_video_to_playlist(playlist_id, video_id, position)
      puts "Video:'#{video_id}' add to playlist successfully"
    end
  end

end