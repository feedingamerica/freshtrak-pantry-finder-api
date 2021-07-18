# frozen_string_literal: true

describe AgencySerializer do
  context 'with attributes' do
    let(:zip_code) do
      create(:zip_code, zip_code: 43_219, latitude: 40.01310,
                        longitude: -82.92363)
    end
    let(:service_category) { create(:service_category) }
    let(:date) { (Date.today + 5).to_s }
    let(:agency) { create(:agency) }
    let(:event) do
      create(:event, agency: agency, event_address_status_id: 0,
                     form_master_num: form.form_master_num)
    end
    let(:form) { create(:form) }
    let(:event_geography) { create(:event_geography, exception_note: '') }
    # let!(:event_zip_code) do
    # end
    let!(:event_date) do
      create(:event_date, event: event, date: date.delete('-'),
                          start_time_key: 930, end_time_key: 2200)
    end

    before do
      create(:event_zip_code, event: event, zip_code: zip_code.zip_code,
                              event_geography: event_geography)
    end

    it 'json without user_location, zip_code, category' do
      serialized_object = JSON.parse(described_class.new(agency).to_json)
      serialized_object.should == expected_response
    end

    it 'json with user_location, zip_code, category' do
      serialized_object2 = JSON.parse(
        described_class.new(
          agency, user_location: zip_code, zip_code: zip_code.zip_code,
                  category: service_category.service_category_name
        ).to_json
      )
      serialized_object2.should == expected_response1
    end

    def expected_response
      {
        'id' => agency.id,
        'address' => "#{agency.address1} #{agency.address2}",
        'city' => agency.city,
        'state' => agency.state,
        'zip' => agency.zip,
        'phone' => agency.phone,
        'name' => agency.loc_name,
        'nickname' => agency.loc_nickname,
        'latitude' => agency.latitude.to_f.to_s,
        'longitude' => agency.longitude.to_f.to_s,
        'estimated_distance' => '',
        'events' => [
          {
            'id' => event.id,
            'address' => "#{event.address1} #{event.address2}",
            'city' => event.city,
            'state' => event.state,
            'zip' => event.zip,
            'agency_id' => event.loc_id,
            'latitude' => event.pt_latitude.to_f.to_s,
            'longitude' => event.pt_longitude.to_f.to_s,
            'name' => event.event_name,
            'estimated_distance' => '',
            'exception_note' => '',
            'event_details' => event.pub_desc_long,
            'agency_name' => event.agency_name,
            'agency_phone' => event.agency_phone,
            'event_dates' => [
              {
                'id' => event_date.id,
                'event_id' => event_date.event_id,
                'capacity' => event_date.capacity,
                'accept_walkin' => event_date.accept_walkin,
                'accept_reservations' => event_date.accept_reservations,
                'accept_interest' => event_date.accept_interest,
                'start_time' => '9:30 AM',
                'end_time' => '10 PM',
                'date' => date
              }
            ],
            'forms' => [
              {
                'id' => form.id,
                'display_age_adult' => form.display_age_adult,
                'display_age_senior' => form.display_age_senior
              }
            ],
            'service_category' => {
              'id' => event.service_category.id,
              'service_category_name' =>
                event.service_category.service_category_name
            }
          }
        ]
      }
    end

    def expected_response1
      {
        'id' => agency.id,
        'address' => "#{agency.address1} #{agency.address2}",
        'city' => agency.city,
        'state' => agency.state,
        'zip' => agency.zip,
        'phone' => agency.phone,
        'name' => agency.loc_name,
        'nickname' => agency.loc_nickname,
        'latitude' => agency.latitude.to_f.to_s,
        'longitude' => agency.longitude.to_f.to_s,
        'estimated_distance' => '',
        'events' => [
          {
            'id' => event.id,
            'address' => "#{event.address1} #{event.address2}",
            'city' => event.city,
            'state' => event.state,
            'zip' => event.zip,
            'agency_id' => event.loc_id,
            'latitude' => event.pt_latitude.to_f.to_s,
            'longitude' => event.pt_longitude.to_f.to_s,
            'name' => event.event_name,
            'estimated_distance' => event.estimated_distance(zip_code),
            'exception_note' => '',
            'event_details' => event.pub_desc_long,
            'agency_name' => event.agency_name,
            'agency_phone' => event.agency_phone,
            'event_dates' => [
              {
                'id' => event_date.id,
                'event_id' => event_date.event_id,
                'capacity' => event_date.capacity,
                'accept_walkin' => event_date.accept_walkin,
                'accept_reservations' => event_date.accept_reservations,
                'accept_interest' => event_date.accept_interest,
                'start_time' => '9:30 AM',
                'end_time' => '10 PM',
                'date' => date
              }
            ],
            'forms' => [
              {
                'id' => form.id,
                'display_age_adult' => form.display_age_adult,
                'display_age_senior' => form.display_age_senior
              }
            ],
            'service_category' => {
              'id' => event.service_category.id,
              'service_category_name' =>
                event.service_category.service_category_name
            }
          }
        ]
      }
    end
  end
end
