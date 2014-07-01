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

  include YouTubeModule

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
    opts = Trollop::options do
      opt :message, 'Upload video to milacron playlist',
          :default => 'Upload video to milacron playlist', :type => String
      opt :title, 'Video title', :default => 'Messages', :type => String
      opt :description, 'Video description',
          :default => 'Test Description', :type => String
      opt :keywords, 'Video keywords, comma-separated',
          :default => 'Test', :type => String
      opt :privacy_status, 'Video privacy status: public, private, or unlisted',
          :default => 'public', :type => String
    end
    # You can post a message with or without an accompanying video or playlist.
    # However, you can't post a video and a playlist at the same time.
    Trollop::die :message, 'is required' unless opts[:message]
    client, youtube = YouTubeHelper.get_authenticated_service
    begin
      body = {
          :snippet => {
              :title => opts[:title],
              :description => opts[:description],
              :tags => opts[:keywords].split(','),
          },
          :status => {
              :privacyStatus => opts[:privacy_status]
          }
      }
      # Call the youtube.activities.insert method to post the channel bulletin.
      playlist_response = client.execute!(
          :api_method => youtube.playlists.insert,
          :parameters => {
              :part => body.keys.join(',')
          },
          :body_object => body
      )


    puts "Playlist created successfully #{playlist_response.data.id}"
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
        CommandLineOAuthHelper.refresh_access_token(USER_ACCESS_TOKEN_INFO, YOUTUBE_CLIENT_SECRETE, PlayList)
      else
        puts e.result.body
      end
    end
  end
end

