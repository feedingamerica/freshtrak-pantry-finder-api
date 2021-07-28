# frozen_string_literal: true

module Api
  # Exposes the zip_code data
  class ZipCodesController < Api::BaseController
    def index
      zip_codes = ZipCode.by_zip_code(search_params)
      serialized_zip_codes =
        ActiveModelSerializers::SerializableResource.new(zip_codes).as_json

      if zip_codes.blank?
        render json: {}
      else
        render json: serialized_zip_codes
      end
    end

    private

    def search_params
      params.require(:zip_code)
    end
  end
end
