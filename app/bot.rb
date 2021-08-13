# frozen_string_literal: true

require 'json'
require 'net/http'
require 'yaml'
require_relative('bosh_utils')
require_relative('concourse_utils')

# Slack-Bot logic
class Bot
  attr_reader :concourse, :mapping, :config

  def initialize(config)
    @mapping = YAML.safe_load(File.read([File.dirname(__FILE__), '/../config/config.yml'].join('')))
    @config = config
    @concourse = ConcourseUtils.new(config)
  end

  def respond(params, message, type)
    uri = URI(params[:response_url])
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    req = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')
    req.body = { text: "<@#{params[:user_id]}> #{message}", response_type: type }.to_json
    http.request(req)
  end

  def process_request(params)
    jobname = job_name(params[:text])
    if jobname.nil?
      respond(params, "Unknown command: `#{params[:text]}`, try `/help`", 'ephemeral')
    else
      deployment_name = concourse.trigger_and_watch(jobname)
      BoshUtils.rename_service_prefix(deployment_name, prefix(params[:user_id]))
      respond(params, "Service Instance created: #{deployment_name}", 'in_channel')
    end
  rescue StandardError
    respond(params, "Job could not be triggered - Error: #{StandardError.message}", 'ephemeral')
  end

  def debug_slack_response(params)
    jobname = params[:text].strip
    if jobname.nil?
      respond(params, "Unknown command: `#{params[:text]}`, try `/help`", 'ephemeral')
    else
      deployment = concourse.trigger_and_watch(jobname)
      respond(params, "Command worked! Deployment: #{deployment}", 'in_channel')
    end
  end

  def job_name(command)
    mapping['commands'][command.strip]
  end

  def prefix(user_id)
    prefix = mapping['slack-users'][user_id]
    raise 'Could not find user-mapping!' if prefix.nil?
  end

  def available_commands
    mapping['commands']
  end
end
