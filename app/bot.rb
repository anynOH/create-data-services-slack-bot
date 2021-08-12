# frozen_string_literal: true

require 'json'
require 'net/http'
require 'yaml'
require_relative('concourse_utils')

# Slack-Bot logic
class Bot
  attr_reader :concourse, :map

  def initialize
    @concourse = ConcourseUtils.new('a9s')
    @map = YAML.safe_load(File.read([File.dirname(__FILE__), '/../config/config.yml'].join('')))
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
      rename_service(deployment_name, prefix(params[:user_id]))
      respond(params, "Service Instance created: #{deployment_name}", 'in_channel')
    end
  rescue StandardErrorr
    respond(params, 'Job could not be triggered - please check Concourse for Details', 'ephemeral')
  end

  def debug_slack_response(params)
    jobname = job_name(params[:text])
    if jobname.nil?
      respond(params, "Unknown command: `#{params[:text]}`, try `/help`", 'ephemeral')
    else
      respond(params, 'Command worked!', 'ephemeral')
    end
  end

  def rename_service(deployment, prefix)
    puts "Deployment #{deployment} will be prefixed with #{prefix}"
  end

  def job_name(command)
    map['commands'][command.strip]
  end

  def prefix(user_id)
    map['slack-users'][user_id]
  end

  def available_commands
    map['commands']
  end
end
