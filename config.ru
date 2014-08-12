# Proxy a call to openx, then inject custom ad units
# For faster local development with ads
require 'sinatra'

# Load the openx mock library
require_relative 'lib/mock_openx'
require_relative 'lib/mock_openx_js_tag.rb'


# Load the openx mock library
require_relative 'lib/fake_redis'

# YOLO, don't care
set :protection, :except => [:json_csrf]

configure do
  AD_SERVER = MockOpenX.new
  JS_TAG = MockOpenXJsTag.new
end

get '/mock' do
  # openx_url = request.params['url']
  openx_url = CGI::unescape(request.query_string[4,100000])
  puts "\n\n>> #{openx_url}\n\n"
  if openx_url
    AD_SERVER.request(openx_url, request.referrer)
    status  AD_SERVER.response_code
    headers AD_SERVER.headers
    body    AD_SERVER.content
  else
    [500,"Can't connect"]
  end
end

# This is to grab the jstag (the base openx library)
# It monkey patches it, and all fetchAds() urls will
# be redirected here
get '/jstag' do
  jstag_url = request.params['url']
  if jstag_url
    JS_TAG.request(jstag_url)
    status  JS_TAG.response_code
    headers JS_TAG.headers
    body    JS_TAG.content
  else
    [500,"Can't connect"]
  end
end

run Sinatra::Application