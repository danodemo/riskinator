# frozen_string_literal: true

class RiskitController < ActionController::API
  def create
    payload = request.request_parameters

    validator = RiskitPayloadValidator.new(payload)

    unless validator.valid?
      return render json: { error: validator.error_message }, status: :unprocessable_entity
    end

    result = RiskProcessor::Processor.process_risk(payload)

    render json: { status: "ok", data: result }, status: :ok
  end
end
