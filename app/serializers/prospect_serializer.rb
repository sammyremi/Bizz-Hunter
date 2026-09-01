# app/serializers/prospect_serializer.rb

# frozen_string_literal: true

class ProspectSerializer
  def self.render(resource)
    if resource.is_a?(Enumerable) || resource.is_a?(ActiveRecord::Relation)
      resource.map { |item| format(item) }
    elsif resource.present?
      format(resource)
    else
      nil
    end
  end

  private_class_method def self.format(prospect)
    opp = OpportunityScoreCalculator.call(
      website: prospect.website,
      phone: prospect.phone_number || prospect.international_phone_number,
      rating: prospect.rating,
      review_count: prospect.review_count
    )

    {
      id: prospect.id,
      user_id: prospect.user_id,
      google_place_id: prospect.google_place_id,
      business_name: prospect.business_name,
      category: prospect.category,
      address: prospect.address,
      latitude: prospect.latitude,
      longitude: prospect.longitude,
      rating: prospect.rating,
      review_count: prospect.review_count,
      phone_number: prospect.phone_number,
      international_phone_number: prospect.international_phone_number,
      website: prospect.website,
      google_maps_url: prospect.google_maps_url,
      status: prospect.status,
      notes: prospect.notes,
      follow_up_at: prospect.follow_up_at,
      created_at: prospect.created_at,
      updated_at: prospect.updated_at,
      opportunity_score: opp[:score],
      opportunity_level: opp[:level],
      opportunity_signals: opp[:signals]
    }
  end
end
