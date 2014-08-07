# Proxy a call to openx, then inject custom ad units
# For faster local development with ads
require 'sinatra'

# Load the openx mock library
require_relative 'lib/mock_openx'

# Load the openx mock library
require_relative 'lib/fake_redis'

# YOLO, don't care
set :protection, :except => [:json_csrf]

configure do
  AD_SERVER = MockOpenX.new
end

get '/mock' do
  openx_url = request.params['url']
  if openx_url
    AD_SERVER.request(openx_url, request.referrer)
    status  AD_SERVER.response_code
    headers AD_SERVER.headers
    body    AD_SERVER.content
  else
    [500,"Can't connect"]
  end
end

run Sinatra::Application
