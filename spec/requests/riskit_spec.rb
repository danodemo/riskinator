# frozen_string_literal: true

require "rails_helper"

RSpec.describe "POST /riskit", type: :request do
  let(:valid_payload) do
    {
      "commuterId" => "COM-123",
      "actions" => [
        {
          "timestamp" => "2022-01-01 10:05:11",
          "action" => "walked on sidewalk",
          "unit" => "mile",
          "quantity" => 0.4
        },
        {
          "timestamp" => "2022-01-01 10:30:09",
          "action" => "rode a shark",
          "unit" => "minute",
          "quantity" => 3
        }
      ]
    }
  end

  describe "valid request" do
    it "returns 200 and processes the payload with risk and action counts" do
      post "/riskit", params: valid_payload, as: :json

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json["status"]).to eq("ok")
      expect(json["data"]["commuterId"]).to eq("COM-123")
      expect(json["data"]["risk"]).to eq(60.16)
      expect(json["data"]["valid_actions"]).to eq(2)
      expect(json["data"]["invalid_actions"]).to eq(0)
    end
  end

  describe "malformed requests" do
    it "rejects missing commuterId" do
      payload = valid_payload.except("commuterId")
      post "/riskit", params: payload, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to eq("commuterId is required and must be a string")
    end

    it "rejects non-string commuterId" do
      post "/riskit", params: valid_payload.merge("commuterId" => 123), as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to eq("commuterId is required and must be a string")
    end

    it "rejects empty commuterId" do
      post "/riskit", params: valid_payload.merge("commuterId" => ""), as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to eq("commuterId is required and must be a string")
    end

    it "rejects missing actions array" do
      payload = valid_payload.except("actions")
      post "/riskit", params: payload, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to eq("actions must be a non-empty array of action items")
    end

    it "rejects empty actions array" do
      post "/riskit", params: valid_payload.merge("actions" => []), as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to eq("actions must be a non-empty array of action items")
    end

    it "rejects invalid unit in action item" do
      payload = valid_payload.deep_dup
      payload["actions"][0]["unit"] = "invalid_unit"
      post "/riskit", params: payload, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to match(/unit must be one of/)
    end

    it "rejects invalid timestamp in action item" do
      payload = valid_payload.deep_dup
      payload["actions"][0]["timestamp"] = "not-a-datetime"
      post "/riskit", params: payload, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to match(/timestamp/)
    end

    it "rejects non-numeric quantity" do
      payload = valid_payload.deep_dup
      payload["actions"][0]["quantity"] = "lots"
      post "/riskit", params: payload, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to match(/quantity/)
    end

    context "when action items have timestamps from different days" do
      it "rejects the request with the required error message" do
        payload = valid_payload.deep_dup
        payload["actions"][0]["timestamp"] = "2022-01-01 10:05:11"
        payload["actions"][1]["timestamp"] = "2022-01-02 10:30:09"

        post "/riskit", params: payload, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body["error"]).to eq(
          "Configuration Error: request contains action items from different days"
        )
      end

      it "rejects when first action is one day and second is another" do
        payload = {
          "commuterId" => "COM-456",
          "actions" => [
            { "timestamp" => "2022-06-15 08:00:00", "action" => "walk", "unit" => "mile", "quantity" => 1 },
            { "timestamp" => "2022-06-16 09:00:00", "action" => "run", "unit" => "minute", "quantity" => 30 }
          ]
        }

        post "/riskit", params: payload, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body["error"]).to eq(
          "Configuration Error: request contains action items from different days"
        )
      end
    end
  end
end
