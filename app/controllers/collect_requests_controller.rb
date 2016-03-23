class CollectRequestsController < ApplicationController
  protect_from_forgery with: :null_session

  def create
    request_id = SecureRandom.uuid
    @collect_request = CollectRequest.new(:request_id => request_id, :completed => false)
    @collect_request.save

    CollectRelationJob.perform_later(@collect_request, collect_request_params)

    respond_to do |format|
      response.headers['Content-Type'] = 'application/json; charset=utf-8'
      format.any { render status: 202, json: @collect_request.to_json }
    end
  end

  def index
    @collect_requests = CollectRequest.all.map {|r| { :request_id => r[:request_id], :completed => r[:completed] }}

    respond_to do |format|
      response.headers['Content-Type'] = 'application/json; charset=utf-8'
      format.any { render json: @collect_requests.to_json }
    end
  end

  def show
    @collect_request = CollectRequest.find_by(:request_id => params[:request_id])

    respond_to do |format|
      response.headers['Content-Type'] = 'application/json; charset=utf-8'
      format.any { render json: @collect_request.to_json }
    end
  end

  def destroy
    @collect_request = CollectRequest.find_by(:request_id => params[:request_id])
    @collect_request.destroy!

    respond_to do |format|
      response.headers['Content-Type'] = 'application/json; charset=utf-8'
      format.any { render status: 204, json: nil }
    end
  end

  private

  def collect_request_params
    params.require(:collect_request).permit(:eid_list => [])
  end
end
