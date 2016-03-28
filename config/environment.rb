# Load the Rails application.
require File.expand_path('../application', __FILE__)

# Initialize the Rails application.
Rails.application.initialize!

ENV['R_HOME'] ||= case RbConfig::CONFIG['host_os']
                  when /linux/; '/usr/local/lib64/R'
                  when /darwin/; '/Library/Frameworks/R.framework/Resources'
                  end
