# encoding: ASCII-8BIT
#
# PlayList. class which defines various attributes and behaviours
# which are used to create a playlist
#
# Author::    Hanumantharaju  (mailto:hanumantharaju.tswamy@costrategix.com)
# Copyright:: Copyright (c) 2012 Crossroads
# License::   MIT
#
class PlayList

  #
  # Initialize the playlist create process
  #
  def initialize
    self.create_playlist
  end

  #
  # Function used to create new youtube playlist
  #
  def create_playlist
    begin
      opts = Trollop::options do
        opt :message, 'Upload video to milacron playlist',
            :default => 'Upload video to milacron playlist', :type => String
        opt :title, 'play list title', :default => 'Team Matrix', :type => String
        opt :description, 'Video description',
            :default => 'Test Description', :type => String
        opt :keywords, 'Video keywords comma-separated',
            :default => 'Crossroads', :type => String
        opt :privacy_status, 'Video privacy status: public, private, or unlisted',
            :default => 'public', :type => String
      end
      # You can post a message with or without an accompanying video or playlist.
      # However, you can't post a video and a playlist at the same time.
      Trollop::die :message, 'is required' unless opts[:message]
      client= YouTubeHelper.get_authenticated_service
      playlist = client.add_playlist(
          :title => opts[:title],
          :description => opts[:description],
          :privacy_status => opts[:privacy_status],
          :keywords => opts[:keywords]
      )
      puts "Playlist #{opts[:title]} created successfully"
      playlist
    end
  end

end

