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

  YOUTUBE_READONLY_SCOPE = 'https://www.googleapis.com/auth/youtube.readonly'
  YOUTUBE_API_SERVICE_NAME = 'youtube'
  YOUTUBE_API_VERSION = 'v3'
  USER_ACCESS_TOKEN_INFO = Immutable.config.user_oauth_json
  YOUTUBE_CLIENT_SECRETE = Immutable.config.youtube_client_secrete_json

  #
  # Initialize the audio content migration process
  #
  def initialize
    self.add_video_to_playlist('PL4k-hIu-yqFLjBInZlowgVFYe7jZvWg8g', 'cTGbCscs35c', 1)
  end

  def add_video_to_playlist(playlist_id, video_id, position)
    begin
      client, youtube = YouTubeHelper.get_authenticated_service
      body = {
        #:kind=> 'youtube#playlistItem',
        :id=> playlist_id,
        :snippet=> {
            #:publishedAt=> 'datetime',
            #:channelId=> 'string',
            #:title=> 'string',
            #:description=> 'string',
          :channelTitle=> 'Test chanel',
          :playlistId=> playlist_id,
          #:position=> position,
          :resourceId=> {
              :kind=> 'youtube#video',
              :videoId=> video_id,
          }
        },
        :contentDetails=> {
          :videoId=> video_id,
        #:startAt=> 'string',
        #:endAt=> 'string',
        #:note=> 'string'
        },
        :status=> {
          :privacyStatus=> 'public'
        }
      }
      playlist_items_response = client.execute!(
          :api_method => youtube.playlist_items.insert,
          :parameters => {
              :part => body.keys.join(',')
          },
          :body_object => body
      )
      puts "Video add to playlist successfully #{playlist_items_response.data.id}"
    end
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
        CommandLineOAuthHelper.refresh_access_token(USER_ACCESS_TOKEN_INFO, YOUTUBE_CLIENT_SECRETE, AddVideosToPlayList)
      else
        puts e.result.body
      end
  end
end