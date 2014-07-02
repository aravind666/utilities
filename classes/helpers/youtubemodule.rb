require_relative('immutable')
module YouTubeModule
  YOUTUBE_READONLY_SCOPE = 'https://www.googleapis.com/auth/youtube.readonly'
  YOUTUBE_API_SERVICE_NAME = 'youtube'
  YOUTUBE_API_VERSION = 'v3'
  USER_ACCESS_TOKEN_INFO = Immutable.config.user_oauth_json
  YOUTUBE_CLIENT_SECRETE = Immutable.config.youtube_client_secrete_json
end