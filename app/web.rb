require 'sinatra/base'
require 'net/http'
require 'json'
require 'yaml'
require_relative('bot')
require_relative('concourse_utils')

# Web-Endpoint to handle Slash Commands
class Web < Sinatra::Base
  attr_reader :bot, :config

  def initialize
    super()
    @config = YAML.safe_load(File.read('/var/vcap/jobs/slackbot/cfg/config.yml'))
    @bot = Bot.new(config)
  end

  helpers do
    def check_authenticity(request)
      secret = config['slack_secret']
      slack_timestamp = request.env['HTTP_X_SLACK_REQUEST_TIMESTAMP']
      body = request.body.read.to_s

      auth_string = "v0:#{slack_timestamp}:#{body}"

      digest = OpenSSL::Digest.new('sha256')
      signature = OpenSSL::HMAC.hexdigest(digest, secret, auth_string)

      "v0=#{signature}" == request.env['HTTP_X_SLACK_SIGNATURE']
    rescue StandardError
      false
    end
  end

  get '/' do
    halt 200
  end

  post '/help' do
    if check_authenticity(request)
      res = "usage: `/create <service-name>`\navailable services:\n"
      bot.available_commands.each do |command|
        res << "- #{command[0]}\n"
      end
      res
    else
      halt 200
    end
  end

  post '/create' do
    if check_authenticity(request)
      Thread.new { bot.process_request(params) }
      'Job triggered, I will ping you as soon as I am ready'
    else
      halt 200
    end
  end
end
