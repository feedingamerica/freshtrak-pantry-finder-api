# frozen_string_literal: true

# Defines ZipCode, attributes to be returned in JSON
class ZipCodeSerializer < ApplicationSerializer
  attributes :id, :zip_code, :latitude, :longitude
end
