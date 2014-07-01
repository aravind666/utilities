# encoding: ASCII-8BIT
#
# CommandLineOAuthHelper  helper for the sample apps for performing OAuth 2.0
# flows from the command line. Starts an embedded server to handle redirects.
#
# Author::    Hanumantharaju  (mailto:hanumantharaju.tswamy@costrategix.com)
# Copyright:: Copyright (c) 2012 Crossroads
# License::   MIT
#

require 'google/api_client'
require 'google/api_client/client_secrets'
require 'json'
require 'launchy'
require 'thin'
require_relative 'youtubemodule'

FILE_POSTFIX = '-oauth2.json'
# This OAuth 2.0 access scope allows for read-only access to the authenticated
# user's account, but not other types of account access.
#YOUTUBE_READONLY_SCOPE = 'https://www.googleapis.com/auth/youtube.readonly'
#YOUTUBE_API_SERVICE_NAME = 'youtube'
#YOUTUBE_API_VERSION = 'v3'
#USER_ACCESS_TOKEN_INFO = Immutable.config.user_oauth_json
#YOUTUBE_CLIENT_SECRETE = Immutable.config.youtube_client_secrete_json

class CommandLineOAuthHelper

  def initialize(scope, client_secrete)
    credentials = Google::APIClient::ClientSecrets.load(client_secrete)
    #p credentials
    @authorization = Signet::OAuth2::Client.new(
      :authorization_uri => credentials.authorization_uri,
      :token_credential_uri => credentials.token_credential_uri,
      :client_id => credentials.client_id,
      :client_secret => credentials.client_secret,
      :redirect_uri => credentials.redirect_uris.first,
      :scope => scope,
      :grant_type => 'authorization_code',
      :access_type => 'offline'
    )
  end

  # Request authorization. Checks to see if a local file with credentials is present, and uses that.
  # Otherwise, opens a browser and waits for response, then saves the credentials locally.
  def authorize(credentials_file_name)
    credentials_file = credentials_file_name + FILE_POSTFIX
    if File.exist? credentials_file
      File.open(credentials_file, 'r') do |file|
        credentials = JSON.load(file)
        file.close
        #p credentials
        #abort
        @authorization.access_token = credentials['access_token']
        @authorization.client_id = credentials['client_id']
        @authorization.client_secret = credentials['client_secret']
        @authorization.refresh_token = credentials['refresh_token']
        #@authorization.expires_in = (Time.parse(credentials['expires_in'].to_enum) - Time.now).ceil
        #if @authorization.expired?
        #  @authorization.fetch_access_token!
        #  save(credentials_file)
        #end
      end
    else
      auth = @authorization
      url = @authorization.authorization_uri().to_s
      server = Thin::Server.new('0.0.0.0', 8080) do
        run lambda { |env|
          # Exchange the auth code & quit
          req = Rack::Request.new(env)
          auth.code = req['code']
          #puts req
          auth.fetch_access_token!
          server.stop()
          [200, {'Content-Type' => 'text/html'}, RESPONSE_HTML]
        }
      end
      Launchy.open(url)
      server.start()
      save(credentials_file) if @authorization.refresh_token
    end
    #p @authorization
    #abort
    return @authorization
  end

  def save(credentials_file)

    File.open(credentials_file, 'w', 0775) do |file|
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

  def self.refresh_access_token(credentials_file_name, client_secrete, class_to_initiate)
    credentials_file = credentials_file_name + FILE_POSTFIX
    new_credentials = ''
    old_credentials = ''
    client_data = ''
    # Read client secrete data
    File.open(client_secrete, 'r') do |client_info|
      client_data = JSON.load(client_info)
      client_info.close
    end
    #puts client_data['web']['client_id']
    #abort
    # Get refresh token
    File.open(credentials_file, 'r', 0775) do |line|
      old_credentials = JSON.load(line)
      line.close
    end
    curl_request_url = "https://accounts.google.com/o/oauth2/token -d '"
    curl_request_url+= "client_id=#{client_data['web']['client_id']}&"
    curl_request_url+= "client_secret=#{client_data['web']['client_secret']}&"
    curl_request_url+= "refresh_token=#{old_credentials['refresh_token']}&"
    curl_request_url+= "grant_type=refresh_token' -o #{Immutable.config.user_new_oauth_json}"
    #puts curl_request_url
    #abort
    system("curl --insecure #{curl_request_url}")

    # Read new access token info
    File.open(Immutable.config.user_new_oauth_json, 'r') do |oauth_file|
      new_credentials = JSON.load(oauth_file)
      oauth_file.close
    end
    p old_credentials
    json = JSON.dump({
      :access_token => new_credentials['access_token'],
      :token_type => new_credentials['token_type'],
      :refresh_token => old_credentials['refresh_token'],
      :expires_in => new_credentials['expires_in']
    })
    # Write new access token info to file
    user_new_credentials = File.open(credentials_file, 'w', 0775)
    user_new_credentials.write(json)
    user_new_credentials.close
    #sleep(5)
        if new_credentials['access_token']
          class_to_initiate.new
        end
    end
  end