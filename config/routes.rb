# frozen_string_literal: true

Jets.application.routes.draw do
  namespace :api do
    resources :agencies, only: %i[index show]
    resources :event_hours, only: %i[index show]
    resources :event_slots, only: :show
    resources :event_dates, only: :show do
      resources :event_hours, only: %i[index show] do
      end

      member do
        get :event_details
      end
    end
    resources :events, only: %i[index show]
    resources :foodbanks, only: :index
    resources :zip_codes, only: :index
  end

  root 'jets/public#show'

  # The jets/public#show controller can serve static utf8
  # content out of the public folder.
  # Note, as part of the deploy process Jets uploads
  # files in the public folder to s3
  # and serves them out of s3 directly.
  # S3 is well suited to serve static assets.
  # More info here: https://rubyonjets.com/docs/extras/assets-serving/
  any '*catchall', to: 'jets/public#show'
end
