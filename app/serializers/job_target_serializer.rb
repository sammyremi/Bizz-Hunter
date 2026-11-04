# frozen_string_literal: true

# app/serializers/job_target_serializer.rb
class JobTargetSerializer
  def self.render(resource)
    if resource.is_a?(Enumerable) || resource.is_a?(ActiveRecord::Relation)
      resource.map { |item| format(item) }
    elsif resource.present?
      format(resource)
    else
      nil
    end
  end

  private_class_method def self.format(target)
    {
      id: target.id,
      job_id: target.job_id,
      country_id: target.country_id,
      country_code: target.country&.iso_country_code,
      country_name: target.country&.name,
      country_city_id: target.country_city_id,
      city_name: target.city_name,
      region_name: target.region_name,
      category: target.category,
      is_custom: target.country_city_id.nil?,
      is_active: target.is_active,
      search_count: target.search_count,
      total_discovered_count: target.total_discovered_count,
      last_searched_at: target.last_searched_at,
      rotation_priority: target.rotation_priority,
      created_at: target.created_at,
      updated_at: target.updated_at
    }
  end
end

