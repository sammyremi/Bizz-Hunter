# app/serializers/prospecting_profile_serializer.rb

# frozen_string_literal: true

class ProspectingProfileSerializer
  def self.render(resource)
    if resource.is_a?(Enumerable) || resource.is_a?(ActiveRecord::Relation)
      resource.map { |item| format(item) }
    elsif resource.present?
      format(resource)
    else
      nil
    end
  end

  private_class_method def self.format(profile)
    {
      id: profile.id,
      user_id: profile.user_id,
      name: profile.name,
      service: profile.service,
      service_description: profile.service_description,
      target_businesses: profile.target_businesses || [],
      opportunity_signals: profile.opportunity_signals || [],
      contact_signals: profile.contact_signals || [],
      is_default: profile.is_default || false,
      created_at: profile.created_at,
      updated_at: profile.updated_at
    }
  end
end
