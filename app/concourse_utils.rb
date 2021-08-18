# frozen_string_literal: true

require 'net/http'
require 'open3'

# Concourse / fly-CLI Utilities
class ConcourseUtils
  attr_reader :fly_target, :fly_username, :fly_password, :fly_url, :pipeline

  def initialize(config)
    @fly_target = config['fly_target']
    @fly_url = config['fly_url']
    @fly_username = config['fly_username']
    @fly_password = config['fly_password']
    @pipeline = config['concourse_pipeline']
    fly_login
  end

  def fly_login
    out, status = Open3.capture2("fly --target #{fly_target} login --concourse-url #{fly_url} -u #{fly_username} -p #{fly_password}")
    raise "Login failed! Error: #{out}" unless status.success?
  end

  def trigger_and_watch(jobname)
    out, status = Open3.capture2("fly -t #{fly_target} trigger-job --job #{pipeline}/#{jobname} -w")
    raise 'Job triggered unsuccessfully!' unless status.success?

    extract_deployment(out)
  end

  def extract_deployment(job_output)
    job_output.match(/Deployment: [A-Za-z0-9-]+\r/)[0].split[1]
  end
end
