# frozen_string_literal: true

describe Api::ZipCodesController, type: :controller do
  let(:zip_code) { create(:zip_code) }

  before do
    create(:zip_code)
  end

  it 'is indexable by zip_code' do
    get '/api/zip_codes', zip_code: zip_code.zip_code
    expect(response.status).to eq 200
    response_body = JSON.parse(response.body)
    expect(response_body['zip_codes'].count).to eq(1)
  end

  it 'returns {} when no zip codes found' do
    get '/api/zip_codes', zip_code: 99_999
    expect(response.status).to eq 200
    response_body = JSON.parse(response.body)
    expect(response_body).to eq({})
  end
end
