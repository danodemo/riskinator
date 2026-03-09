# frozen_string_literal: true

module RiskProcessor
  class Processor
    ACTION_MAP = YAML.load_file(Rails.root.join("config", "action_map.yml"))
    
    def self.process_risk(validated_hash)
      risk = 0
      validated_hash["actions"].each do |item|
        action = ACTION_MAP[ item["action"].to_s.downcase.strip ]
        if action.nil? || action["units"] != item["unit"]
          message = "Action #{item['action'].inspect} not found in action map or units do not match"
          Rails.logger.warn("[Riskinator] #{message}")
          next
        else
          risk += item["quantity"].to_f / action["increment"].to_f
        end
      end
        return { "commuterId" => validated_hash["commuterId"], "risk" => risk }
    end
  end
end
