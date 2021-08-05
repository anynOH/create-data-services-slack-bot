# frozen_string_literal: true

require 'net/http'
require 'open3'

# Concourse / fly-CLI Utilities
class ConcourseUtils
  attr_reader :team_name

  def initialize(team_name)
    @team_name = team_name
  end

  def trigger_and_watch(jobname)
    out, status = Open3.capture2("fly -t #{team_name} trigger-job --job oh-dsa428/#{jobname} -w")
    raise 'Job triggered unsuccessfully!' unless status.success?

    extract_deployment(out)
  end

  def extract_deployment(job_output)
    job_output.match(/Deployment: [A-Za-z0-9-]+\r/)[0].split[1]
  end
end
