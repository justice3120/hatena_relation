require 'date'

namespace :batch do
  desc "Delete Old CollectRequests"

  task :delete_expired_requests => :environment do
    now = DateTime.now()
    old_requests = CollectRequest.all.select do |request|
      request.updated_at < (now - Rational(1, 24) )
    end

    old_requests.each do |request|
      edges_csv_path = Rails.root.join("tmp", "#{request.request_id}_edges.csv")
      nodes_csv_path = Rails.root.join("tmp", "#{request.request_id}_nodes.csv")

      request.destroy!

      File.delete(edges_csv_path) if File.exist?(edges_csv_path)
      File.delete(nodes_csv_path) if File.exist?(nodes_csv_path)
    end
  end
end
