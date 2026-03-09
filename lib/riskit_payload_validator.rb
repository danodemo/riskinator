# frozen_string_literal: true

class RiskitPayloadValidator
  VALID_UNITS = %w[mile floor minute quantity].freeze

  attr_reader :payload, :error_message

  def initialize(payload)
    @payload = payload
    @error_message = nil
  end

  def valid?
    return fail_with("commuterId is required and must be a string") unless valid_commuter_id?
    return fail_with("actions must be a non-empty array of action items") unless valid_actions_array?
    return fail_with("Configuration Error: request contains action items from different days") unless same_day_timestamps?

    payload["actions"].each_with_index do |item, index|
      next if item.is_a?(Hash) && valid_action_item?(item)

      error = action_item_error(item, index)
      return fail_with(error) if error
    end

    true
  end

  private

  def fail_with(message)
    @error_message = message
    false
  end

  def valid_commuter_id?
    payload.is_a?(Hash) && payload["commuterId"].is_a?(String) && payload["commuterId"].present?
  end

  def valid_actions_array?
    payload.is_a?(Hash) &&
      payload["actions"].is_a?(Array) &&
      payload["actions"].any? &&
      payload["actions"].all? { |a| a.is_a?(Hash) }
  end

  def valid_action_item?(item)
    valid_timestamp?(item["timestamp"]) &&
      item["action"].is_a?(String) &&
      VALID_UNITS.include?(item["unit"].to_s) &&
      valid_quantity?(item["quantity"])
  end

  def action_item_error(item, index)
    return "action item at index #{index}: timestamp is required and must be a valid datetime string" unless valid_timestamp?(item&.[]("timestamp"))
    return "action item at index #{index}: action is required and must be a string" unless item["action"].is_a?(String)
    return "action item at index #{index}: unit must be one of #{VALID_UNITS.join(', ')}" unless VALID_UNITS.include?(item["unit"].to_s)
    return "action item at index #{index}: quantity must be a numeric value (up to 2 decimal places)" unless valid_quantity?(item["quantity"])

    nil
  end

  def valid_timestamp?(value)
    return false if value.blank?

    parsed = Time.zone.parse(value.to_s)
    parsed.present?
  rescue ArgumentError
    false
  end

  def valid_quantity?(value)
    return false if value.nil?

    num = Float(value)
    # Allow up to 2 decimal places
    (num * 100).round == num * 100
  rescue ArgumentError, TypeError
    false
  end

  def same_day_timestamps?
    return true unless payload["actions"].is_a?(Array) && payload["actions"].any?

    dates = payload["actions"].filter_map do |item|
      ts = item["timestamp"]
      next unless ts.present?

      t = Time.zone.parse(ts.to_s)
      t&.to_date
    end

    dates.uniq.size <= 1
  end
end
