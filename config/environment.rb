# Load the Rails application.
require File.expand_path('../application', __FILE__)

# Initialize the Rails application.
Rails.application.initialize!

case Rails.env
  when 'production' then
    ENV['R_HOME'] ||= '/app/vendor/R/bin'
  when 'staging' then
    ENV['R_HOME'] ||= '/app/vendor/R/bin'
  else
    ENV['R_HOME'] ||= case RbConfig::CONFIG['host_os']
                        when /linux/; '/usr/local/lib64/R'
                        when /darwin/; '/Library/Frameworks/R.framework/Resources'
                      end
end
