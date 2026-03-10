# frozen_string_literal: true

module RiskProcessor
  class Processor
    ACTION_MAP = YAML.load_file(Rails.root.join("config", "action_map.yml"))
    
    def self.process_risk(validated_hash)
      risk = 0
      valid_actions = 0
      invalid_actions = 0

      validated_hash["actions"].each do |item|
        action = ACTION_MAP[ item["action"].to_s.downcase.strip ]
        if action.nil? || action["units"] != item["unit"]
          message = "Action #{item['action'].inspect} not found in action map or units do not match"
          Rails.logger.warn("[Riskinator] #{message}")
          invalid_actions += 1
          next
        else
          risk += item["quantity"].to_f / action["increment"].to_f
          valid_actions += 1
        end
      end
      return { "commuterId" => validated_hash["commuterId"], "risk" => risk, "valid_actions" => valid_actions, "invalid_actions" => invalid_actions }
    end
  end
end
