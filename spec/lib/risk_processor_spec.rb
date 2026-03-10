# frozen_string_literal: true

require "rails_helper"

RSpec.describe RiskProcessor::Processor do
  describe ".process_risk" do
    it "returns risk from valid actions only when some actions do not match the action map" do
      # 3 items: 2 unknown actions, 1 valid ("walked on sidewalk" → mile, increment 2.5)
      # Valid item: 0.4 miles → 0.4 / 2.5 = 0.16 micromorts
      validated_hash = {
        "commuterId" => "COM-456",
        "actions" => [
          { "timestamp" => "2022-01-01 08:00:00", "action" => "unknown action", "unit" => "mile", "quantity" => 1 },
          { "timestamp" => "2022-01-01 09:00:00", "action" => "walked on sidewalk", "unit" => "mile", "quantity" => 0.4 },
          { "timestamp" => "2022-01-01 10:00:00", "action" => "another fake action", "unit" => "minute", "quantity" => 5 }
        ]
      }

      result = described_class.process_risk(validated_hash)

      expect(result).to eq(
        "commuterId" => "COM-456",
        "risk" => 0.16,
        "valid_actions" => 1,
        "invalid_actions" => 2
      )
    end

    it "skips actions with matching name but wrong unit and still returns risk from valid items" do
      # "walked on sidewalk" is in map with unit "mile"; send one with "minute" (wrong) and one with "mile" (correct)
      validated_hash = {
        "commuterId" => "COM-111",
        "actions" => [
          { "timestamp" => "2022-01-01 08:00:00", "action" => "walked on sidewalk", "unit" => "minute", "quantity" => 10 },
          { "timestamp" => "2022-01-01 09:00:00", "action" => "walked on sidewalk", "unit" => "mile", "quantity" => 2.5 }
        ]
      }
      # Only second item counts: 2.5 / 2.5 = 1 micromort

      result = described_class.process_risk(validated_hash)

      expect(result).to eq(
        "commuterId" => "COM-111",
        "risk" => 1.0,
        "valid_actions" => 1,
        "invalid_actions" => 1
      )
    end

    it "returns sum of risk for multiple valid actions" do
      # walked on sidewalk: 0.4 mile → 0.4/2.5 = 0.16; rode a shark: 3 min → 3/0.05 = 60; total 60.16
      validated_hash = {
        "commuterId" => "COM-SUM",
        "actions" => [
          { "timestamp" => "2022-01-01 08:00:00", "action" => "walked on sidewalk", "unit" => "mile", "quantity" => 0.4 },
          { "timestamp" => "2022-01-01 09:00:00", "action" => "rode a shark", "unit" => "minute", "quantity" => 3 }
        ]
      }

      result = described_class.process_risk(validated_hash)

      expect(result["commuterId"]).to eq("COM-SUM")
      expect(result["risk"]).to eq(60.16)
      expect(result["valid_actions"]).to eq(2)
      expect(result["invalid_actions"]).to eq(0)
    end
  end
end
