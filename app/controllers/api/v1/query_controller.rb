class Api::V1::QueryController < ApplicationController
  def ask
    query = params[:query]
    if query.blank?
      return render json: { error: "Query parameter cannot be blank." }, status: :bad_request
    end

    result = QueryService.new(query).process

    render json: result, status: :ok
  rescue StandardError => e
    render json: { error: "An unexpected error occurred: #{e.message}" }, status: :internal_server_error
  end
end
