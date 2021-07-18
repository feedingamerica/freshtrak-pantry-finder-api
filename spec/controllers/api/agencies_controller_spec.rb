# frozen_string_literal: true

describe Api::AgenciesController, type: :controller do
  let(:zip_code) do
    create(:zip_code, zip_code: 43_219, latitude: 40.01310,
                      longitude: -82.92363)
  end
  let(:date) { (Date.today + 5).to_s }
  let(:agency) { create(:agency) }
  let(:form) { create(:form) }
  let(:event) do
    create(:event, agency: agency, event_address_status_id: 0,
                   form_master_num: form.form_master_num)
  end
  let(:event_geography) { create(:event_geography) }
  let!(:event_zip_code) do
    create(:event_zip_code, event: event, zip_code: zip_code.zip_code,
                            event_geography: event_geography)
  end
  let!(:event_date) do
    create(:event_date, event: event, date: date.delete('-'),
                        start_time_key: 930, end_time_key: 2200)
  end

  before do
    other_zip = create(:zip_code)
    other_date = (Date.today + 2).to_s.delete('-')
    other_foodbank = create(:foodbank, county_ids: other_zip.county.id)
    other_agency = create(:agency, foodbank: other_foodbank)
    other_event = create(:event, agency: other_agency)
    create(:event_date, event: other_event, date: other_date)
  end

  it 'shows the agency' do
    get "/api/agencies/#{agency.id}"

    expect(response.status).to eq 200
    agency_response = JSON.parse(response.body)['agency']
    expect(agency_response['id']).to eq(agency.id)
  end

  it 'responds with no agencies without filter params' do
    get '/api/agencies'
    expect(response.status).to eq 200
    response_body = JSON.parse(response.body)
    expect(response_body).to be_empty
  end

  it 'is indexable by zip_code' do
    get '/api/agencies', zip_code: event_zip_code.zip_code
    expect(response.status).to eq 200
    response_body = JSON.parse(response.body).deep_symbolize_keys
    expect(response_body).to eq(expected_response(zip_code.lat, zip_code.long))
  end

  it 'is indexable by event_date' do
    get '/api/agencies', event_date: date
    expect(response.status).to eq 200
    response_body = JSON.parse(response.body).deep_symbolize_keys
    expect(response_body).to eq(expected_response(nil, nil, false))
  end

  it 'is indexable by zip_code and event_date' do
    get '/api/agencies', zip_code: event_zip_code.zip_code, event_date: date
    expect(response.status).to eq 200
    response_body = JSON.parse(response.body).deep_symbolize_keys
    expect(response_body).to eq(expected_response(zip_code.lat, zip_code.long))
  end

  it 'is indexable by zip_code and distance' do
    get '/api/agencies', zip_code: event_zip_code.zip_code, distance: '10'
    expect(response.status).to eq 200
    response_body = JSON.parse(response.body).deep_symbolize_keys
    expect(response_body).to eq(expected_response(zip_code.lat, zip_code.long))
  end

  it 'is indexable by zip_code and includes lat & long params' do
    get '/api/agencies', zip_code: event_zip_code.zip_code, lat: event.lat.to_s,
                         long: event.long.to_s
    expect(response.status).to eq 200
    response_body = JSON.parse(response.body).deep_symbolize_keys
    expect(response_body).to eq(expected_response(event.lat, event.long))
  end

  it 'is indexable by event_date and includes lat & long params' do
    get '/api/agencies', event_date: date, lat: event.lat.to_s,
                         long: event.long.to_s
    expect(response.status).to eq 200
    response_body = JSON.parse(response.body).deep_symbolize_keys
    expect(response_body).to eq(expected_response(event.lat, event.long, false))
  end

  it 'is indexable by event_date and zip_code and includes lat & long params' do
    get '/api/agencies', zip_code: event_zip_code.zip_code, event_date: date,
                         lat: event.lat.to_s, long: event.long.to_s
    expect(response.status).to eq 200
    response_body = JSON.parse(response.body).deep_symbolize_keys
    expect(response_body).to eq(expected_response(event.lat, event.long))
  end

  it 'is indexable by zip_code and includes non-numeric lat & long params' do
    get '/api/agencies', zip_code: event_zip_code.zip_code, lat: 'dog',
                         long: 'cat'
    expect(response.status).to eq 200
    response_body = JSON.parse(response.body).deep_symbolize_keys
    expect(response_body).to eq(expected_response(zip_code.lat, zip_code.long))
  end

  it 'is indexable by event_date and includes invalid lat & long params' do
    get '/api/agencies', event_date: date, lat: 100.1, long: -190.9
    expect(response.status).to eq 200
    response_body = JSON.parse(response.body).deep_symbolize_keys
    expect(response_body).to eq(expected_response(100.1, -190.9, false))
  end

  context 'when agencies by event location if event_address_status_id is 1' do
    let(:event) do
      create(:event, agency: agency, event_address_status_id: 1,
                     latitude: 39.86397, longitude: -83.12886,
                     form_master_num: form.form_master_num)
    end

    it 'is indexable by zip_code and distance' do
      get '/api/agencies', zip_code: event_zip_code.zip_code, distance: '25'
      expect(response.status).to eq 200
      response_body = JSON.parse(response.body).deep_symbolize_keys
      expect(response_body).to eq(
        expected_response(zip_code.lat, zip_code.long)
      )
    end
  end

  def expected_response(lat = nil, long = nil, has_zip = true)
    {
      agencies: [
        {
          id: agency.id,
          address: "#{agency.address1} #{agency.address2}",
          city: agency.city,
          state: agency.state,
          zip: agency.zip,
          phone: agency.phone,
          name: agency.loc_name,
          nickname: agency.loc_nickname,
          latitude: agency.latitude.to_f.to_s,
          longitude: agency.longitude.to_f.to_s,
          estimated_distance: Geo.distance_between(
            OpenStruct.new(lat: lat, long: long), agency
          ),
          events: [
            {
              id: event.id,
              address: "#{event.address1} #{event.address2}",
              city: event.city,
              state: event.state,
              zip: event.zip,
              latitude: event.pt_latitude.to_f.to_s,
              longitude: event.pt_longitude.to_f.to_s,
              agency_id: event.loc_id,
              name: event.event_name,
              estimated_distance: Geo.distance_between(
                OpenStruct.new(lat: lat, long: long), event
              ),
              exception_note: has_zip ? event_geography.exception_note : '',
              event_details: event.pub_desc_long,
              agency_name: agency.loc_name,
              agency_phone: agency.phone,
              event_dates: [
                {
                  id: event_date.id,
                  event_id: event.id,
                  capacity: 25,
                  start_time: '9:30 AM',
                  end_time: '10 PM',
                  date: date,
                  accept_walkin: 1,
                  accept_reservations: 1,
                  accept_interest: 1
                }
              ],
              forms: [
                {
                  id: form.id,
                  display_age_adult: form.max_age_child + 1,
                  display_age_senior: form.max_age_adult + 1
                }
              ],
              service_category:
                {
                  id: event.service_category.id,
                  service_category_name:
                    event.service_category.service_category_name
                }
            }
          ]
        }
      ]
    }
  end
end
