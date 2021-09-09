# frozen_string_literal: true

require 'open3'
require 'tempfile'

# Util Class for interaction with BOSH CLI
class BoshUtils
  def self.rename_service_prefix(deployment, prefix)
    key = 'service_deployment_prefix'
    tempfile = Tempfile.new(deployment)
    _out, status = Open3.capture2("bosh manifest -d #{deployment} > #{tempfile.path}")
    raise 'Error: Rename-Service-Prefix - Could not save manifest!' unless status.success?

    _out, status = Open3.capture2("sed -i -e 's/#{key}: .*/#{key}: #{prefix}/' #{tempfile.path}")
    raise 'Error: Rename-Service-Prefix - Could not replace key!' unless status.success?

    _out, status = Open3.capture2("bosh deploy -d #{deployment} #{tempfile.path} -n")
    raise 'Error: Rename-Service-Prefix - Could not redeploy deployment!' unless status.success?
  end
end
