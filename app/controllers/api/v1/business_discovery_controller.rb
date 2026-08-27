module Api
  module V1
    class BusinessDiscoveryController < ApplicationController
      def search
        query = params[:query]

        if query.blank?
          return render json: {
            error: "query is required"
          }, status: :bad_request
        end

        result = GooglePlaces::BusinessSearch.new(
          query: query
        ).call

        render json: result
      end
    end
  end
end