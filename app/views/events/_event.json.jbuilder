json.extract! event, :id, :name, :capacity, :timeout, :created_at, :updated_at
json.url event_url(event, format: :json)
