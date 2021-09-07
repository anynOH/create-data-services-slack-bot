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
    user_prefix = prefix(params[:user_id])
    deployment_name = concourse.trigger_and_watch(jobname)
    BoshUtils.rename_service_prefix(deployment_name, user_prefix)
    respond(params, "Service Instance created: `#{deployment_name}`", 'in_channel')
  rescue StandardError => e
    respond(params, "Job could not be triggered - Error: #{e.message}", 'ephemeral')
  end

  def job_name(command)
    return mapping['commands'][command.strip] unless mapping['commands'][command.strip].nil?

    raise StandardError, "Unkown command `#{command}`"
  end

  def prefix(user_id)
    return config['slack_users'][user_id] unless config['slack_users'][user_id].nil?

    raise StandardError, "Unknown mapping for Slack-ID `#{user_id}`"
  end

  def available_commands
    mapping['commands']
  end
end
