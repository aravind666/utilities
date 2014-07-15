# encoding: ASCII-8BIT
#
# CommandLineOAuthHelper. helper for the sample apps for performing OAuth 2.0 flows from the command
# line. Starts an embedded server to handle redirects.
#
# Author::    Hanumantharaju  (mailto:hanumantharaju.tswamy@costrategix.com)
# Copyright:: Copyright (c) 2012 Crossroads
# License::   MIT
#
#
class CommandLineOAuthHelper

  def initialize(scope)
    credentials = Google::APIClient::ClientSecrets.load(Immutable.config.youtube_client_secrete_json)
    @authorization = Signet::OAuth2::Client.new(
        :authorization_uri => credentials.authorization_uri,
        :token_credential_uri => credentials.token_credential_uri,
        :client_id => credentials.client_id,
        :client_secret => credentials.client_secret,
        :redirect_uri => credentials.redirect_uris.first,
        :scope => scope
    )
  end

  #
  # function is used to Request authorization.
  # Checks to see if a local file with credentials is present, and uses that.
  # Otherwise, opens a browser and waits for response,
  # then saves the credentials locally.
  #
  def authorize(credentials_file)
    if File.exist? credentials_file
      File.open(credentials_file, 'r') do |file|
        credentials = JSON.load(file)
        #secs = credentials['token_expiry']/1000
        @authorization.access_token = credentials['access_token']
        @authorization.client_id = credentials['client_id']
        @authorization.client_secret = credentials['client_secret']
        @authorization.refresh_token = credentials['refresh_token']
        @authorization.expires_in = (Time.parse(credentials['token_expiry']) - Time.now).ceil
        if @authorization.expired?
          @authorization.fetch_access_token!
          save(credentials_file)
        end
      end
    else
      auth = @authorization
      url = @authorization.authorization_uri().to_s
      server = Thin::Server.new('0.0.0.0', 8080) do
        run lambda { |env|
          # Exchange the auth code & quit
          req = Rack::Request.new(env)
          auth.code = req['code']
          auth.fetch_access_token!
          server.stop()
          [200, {'Content-Type' => 'text/html'}, RESPONSE_HTML]
        }
      end
      Launchy.open(url)
      server.start()
      save(credentials_file)
    end
    return @authorization
  end

  #
  # function is used to save credentials to file.
  #
  def save(credentials_file)
    File.open(credentials_file, 'w', 0600) do |file|
      json = JSON.dump({
                         :access_token => @authorization.access_token,
                         :client_id => @authorization.client_id,
                         :client_secret => @authorization.client_secret,
                         :refresh_token => @authorization.refresh_token,
                         :token_expiry => @authorization.expires_at
                       })
      file.write(json)
    end
  end
end