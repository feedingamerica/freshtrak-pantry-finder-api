# frozen_string_literal: true

describe Api::AgenciesController, type: :controller do
  let(:zip_code) { create(:zip_code) }
  let(:date) { (Date.today + 5).to_s }
  let(:agency) { create(:agency) }
  let(:event) { create(:event, agency: agency) }
  let!(:event_zip_code) do
    create(:event_zip_code, event: event, zip_code: zip_code.zip_code)
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

  it 'responds with no agencies without filter params' do
    get '/api/agencies'
    expect(response.status).to eq 200
    response_body = JSON.parse(response.body)
    expect(response_body['agencies']).to be_empty
  end

  it 'is indexable by zip_code' do
    get '/api/agencies', zip_code: event_zip_code.zip_code
    request_params = request.params.query_params
    expect(response.status).to eq 200
    response_body = JSON.parse(response.body).deep_symbolize_keys
    expect(response_body).to eq(expected_response(request_params))
  end

  it 'is indexable by event_date' do
    get '/api/agencies', event_date: date
    request_params = request.params.query_params
    expect(response.status).to eq 200
    response_body = JSON.parse(response.body).deep_symbolize_keys
    expect(response_body).to eq(expected_response(request_params))
  end

  it 'is indexable by zip_code and event_date' do
    get '/api/agencies', zip_code: event_zip_code.zip_code, event_date: date
    request_params = request.params.query_params
    expect(response.status).to eq 200
    response_body = JSON.parse(response.body).deep_symbolize_keys
    expect(response_body).to eq(expected_response(request_params))
  end

  it 'is indexable by zip_code and includes lat & long params' do
    get '/api/agencies', zip_code: event_zip_code.zip_code, lat: event.lat.to_s,
                         long: event.long.to_s
    request_params = request.params.query_params
    expect(response.status).to eq 200
    response_body = JSON.parse(response.body).deep_symbolize_keys
    expect(response_body).to eq(expected_response(request_params))
  end

  it 'is indexable by event_date and includes lat & long params' do
    get '/api/agencies', event_date: date, lat: event.lat.to_s,
                         long: event.long.to_s
    request_params = request.params.query_params
    expect(response.status).to eq 200
    response_body = JSON.parse(response.body).deep_symbolize_keys
    expect(response_body).to eq(expected_response(request_params))
  end

  it 'is indexable by event_date and zip_code and includes lat & long params' do
    get '/api/agencies', zip_code: event_zip_code.zip_code, event_date: date,
                         lat: event.lat.to_s, long: event.long.to_s
    request_params = request.params.query_params
    expect(response.status).to eq 200
    response_body = JSON.parse(response.body).deep_symbolize_keys
    expect(response_body).to eq(expected_response(request_params))
  end

  it 'is indexable by zip_code and includes non-numeric lat & long params' do
    get '/api/agencies', zip_code: event_zip_code.zip_code, lat: 'dog',
                         long: 'cat'
    request_params = request.params.query_params
    expect(response.status).to eq 200
    response_body = JSON.parse(response.body).deep_symbolize_keys
    expect(response_body).to eq(expected_response(request_params))
  end

  it 'is indexable by event_date and includes invalid lat & long params' do
    get '/api/agencies', event_date: date, lat: '100.1', long: '-190.9'
    request_params = request.params.query_params
    expect(response.status).to eq 200
    response_body = JSON.parse(response.body).deep_symbolize_keys
    expect(response_body).to eq(expected_response(request_params))
  end

  def expected_response(request_params)
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
          estimated_distance: Geo.distance_between(
            user_location(request_params), agency
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
              service: event.service_description,
              estimated_distance: Geo.distance_between(
                user_location(request_params), event
              ),
              event_dates: [
                {
                  id: event_date.id,
                  event_id: event.id,
                  capacity: 25,
                  start_time: '9:30 AM',
                  end_time: '10 PM',
                  date: date
                }
              ]
            }
          ]
        }
      ]
    }
  end

  def user_location(request_params)
    return nil unless request_params.to_s.include?(':zip_code') ||
                      (request_params.to_s.include?(':lat') &&
                       request_params.to_s.include?(':long'))

    if valid_location(request_params)
      OpenStruct.new(lat: request_params[:lat].to_f,
                     long: request_params[:long].to_f)
    elsif request_params.to_s.include?(':zip_code')
      ::ZipCode.find_by(zip_code: request_params[:zip_code])
    end
  end

  def valid_location(request_params)
    return true if request_params.to_s.include?(':lat') &&
                   request_params.to_s.include?(':long') &&
                   request_params[:lat].numeric? &&
                   request_params[:long].numeric? &&
                   Geo.validate_coordinate_values(request_params[:lat].to_f,
                                                  request_params[:long].to_f)

    false
  end
end
