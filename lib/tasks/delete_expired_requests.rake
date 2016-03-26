require 'date'

namespace :batch do
  desc "Delete Old CollectRequests"

  task :delete_expired_requests => :environment do
    now = DateTime.now()
    old_requests = CollectRequest.all.select do |request|
      request.updated_at < (now - Rational(1, 24) )
    end

    old_requests.each do |request|
      request.destroy!
    end
  end
end
