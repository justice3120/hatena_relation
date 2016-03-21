class CollectRequestsController < ApplicationController
  def create()
    request_id = SecureRandom.uuid
    @collect_request = CollectRequest.new(:request_id => request_id)

    respond_to do |format|
      format.json { render json: @collect_request.to_json }
    end
  end
end
