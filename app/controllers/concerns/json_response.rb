# frozen_string_literal: true

module JsonResponse
  extend ActiveSupport::Concern

  private

  def json_response(object: {}, message: '', error: '', status: :ok, meta: {})
    success = status.to_i.between?(200, 399)

    render json: {
      success: success,
      message: success ? message : error,
      data: object,
      meta: meta
    }, status: status
  end

  def success_response(object: {}, message: 'Request successful', meta: {})
    json_response(
      object: object,
      message: message,
      meta: meta
    )
  end

  def error_response(message:, status: :bad_request)
    json_response(
      error: message,
      status: status
    )
  end
end