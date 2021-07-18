# frozen_string_literal: true

# Serializer to strip away the cruft in the locations table
class AgencySerializer < ActiveModel::Serializer
  attributes :id, :address, :city, :state, :zip, :phone
  attribute :loc_name, key: :name
  attribute :loc_nickname, key: :nickname
  attributes :latitude, :longitude
  attribute :estimated_distance

  has_many :events

  def address
    return object.address1 if object.address2.empty?

    "#{object.address1} #{object.address2}"
  end

  # Calculate estimated distance JSON field with the user
  # location and the model object location.  User location is
  # an object representing a location known by the user, e.g.,
  # zip code, lat/long derived from address, etc
  def estimated_distance
    user_location = @instance_options[:user_location]
    return '' if user_location.nil?

    Geo.distance_between(user_location, object)
  end

  def events
    zip_code = @instance_options[:zip_code]
    category = @instance_options[:category]
    if zip_code && category
      object.events.by_zip_code(zip_code).by_service_category(category)
    elsif zip_code
      object.events.by_zip_code(zip_code)
    else
      object.events
    end
  end
end
