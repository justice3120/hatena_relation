class CollectRequestsController < ApplicationController
  protect_from_forgery with: :null_session

  def create
    request_id = SecureRandom.uuid
    @collect_request = CollectRequest.new(:request_id => request_id, :completed => false)
    @collect_request.save

    CollectRelationJob.perform_later(@collect_request)

    respond_to do |format|
      format.json { render status: 202, json: @collect_request.to_json }
    end
  end

  def show
    @collect_request = CollectRequest.find_by(:request_id => params[:request_id])

    respond_to do |format|
      format.json { render json: @collect_request.to_json }
    end
  end

  def destroy
    @collect_request = CollectRequest.find_by(:request_id => params[:request_id])
    @collect_request.destroy!

    respond_to do |format|
      format.json { render status: 204, json: nil }
    end
  end
end
