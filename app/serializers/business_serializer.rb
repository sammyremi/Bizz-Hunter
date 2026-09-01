# app/serializers/business_serializer.rb

# frozen_string_literal: true

class BusinessSerializer
  def self.render(resource)
    if resource.is_a?(Enumerable)
      resource.map { |item| format(item) }
    elsif resource.present?
      format(resource)
    else
      nil
    end
  end

  private_class_method def self.format(business)
    return business unless business.is_a?(Hash)

    business.deep_symbolize_keys
  end
end
