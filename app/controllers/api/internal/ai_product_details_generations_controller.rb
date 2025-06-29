# frozen_string_literal: true

class Api::Internal::AiProductDetailsGenerationsController < Api::Internal::BaseController
  before_action :authenticate_user!
  after_action :verify_authorized

  def create
    authorize current_user, :generate_product_details_with_ai?

    prompt = params[:prompt]

    if prompt.blank?
      render json: { error: "Prompt is required" }, status: :bad_request
      return
    end

    begin
      service = ::Ai::ProductDetailsGeneratorService.new(current_seller: current_seller)
      result = service.generate_product_details(prompt: prompt)

      render json: {
        success: true,
        data: {
          name: result[:name],
          description: result[:description],
          summary: result[:summary],
          number_of_content_pages: result[:number_of_content_pages],
          price: result[:price],
          currency_code: result[:currency_code],
          price_frequency_in_months: result[:price_frequency_in_months],
          native_type: result[:native_type],
          duration_in_seconds: result[:duration_in_seconds]
        }
      }
    rescue => e
      Rails.logger.error "Product details generation using AI failed: #{e.message}"
      Bugsnag.notify(e)
      render json: {
        success: false,
        error: "Failed to generate product details. Please try again."
      }, status: :internal_server_error
    end
  end
end
