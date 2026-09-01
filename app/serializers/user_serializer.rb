# app/serializers/user_serializer.rb

# frozen_string_literal: true

class UserSerializer
  def self.render(resource)
    if resource.is_a?(Enumerable)
      resource.map { |item| format(item) }
    elsif resource.present?
      format(resource)
    else
      nil
    end
  end

  private_class_method def self.format(user)
    {
      id: user.id,
      name: user.name,
      email: user.email,
      created_at: user.created_at
    }
  end
end
