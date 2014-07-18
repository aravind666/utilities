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
      client, youtube = YouTubeHelper.get_authenticated_service
      request_body = self.get_playlist_request_body
      playlist_response = client.execute!(
          :api_method => youtube.playlists.insert,
          :body_object => request_body,
          :parameters => {
              :part => request_body.keys.join(',')
          }
      )
      puts "Playlist '#{request_body[:snippet][:title]}' created successfully"
      return playlist_response
    end
  end

  #
  # Function used to prepare playlist create request body
  #
  def get_playlist_request_body
    begin
      publish_at = Time.now.utc.iso8601(1)
      opts = Trollop::options do
        opt :message, 'Upload video to milacron playlist',
            :default => 'Upload video to milacron playlist', :type => String
        opt :title, 'play list title', :default => 'Test Message Playlist', :type => String
        opt :description, 'Video description',
            :default => 'Testing playlist create', :type => String
        opt :keywords, 'Video keywords comma-separated',
            :default => 'Crossroads', :type => String
        opt :publish_at, 'date time',
            :default => publish_at,
            :type => String
        opt :channel_id, 'Video description',
            :default => Immutable.config.youtube_channel_id,
            :type => String
        opt :privacy_status, 'Video privacy status: public, private, or unlisted',
            :default => 'public', :type => String
      end
      # You can post a message with or without an accompanying video or playlist.
      # However, you can't post a video and a playlist at the same time.
      Trollop::die :message, 'is required' unless opts[:message]
      body = {
          :snippet => {
              :title => opts[:title],
              :description => opts[:description],
              :publishedAt => opts[:publish_at],
              :channelId => opts[:channel_id]
          },
          :status => {
              :privacyStatus => opts[:privacy_status]
          }
      }
      body
    end
  end
end

