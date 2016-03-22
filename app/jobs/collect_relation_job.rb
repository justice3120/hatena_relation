class CollectRelationJob < ActiveJob::Base
  queue_as :default

  def perform(collect_request)
    sleep 10
    collect_request.update(:completed => true)
  end
end
