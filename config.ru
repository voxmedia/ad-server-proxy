# Proxy a call to openx, then inject custom ad units
# For faster local development with ads
require 'sinatra'

# If you want to use this to debug/develop
# Will reload this every refresh
begin
  require "sinatra/reloader"
  Dir.glob(File.join(File.dirname(__FILE__),"lib/*.rb")).each do |file|
    also_reload file
  end
rescue LoadError
  #no op
end
# Load the openx mock library
require_relative 'lib/mock_openx'
require_relative 'lib/mock_openx_js_tag'

# Load the fake redis library
require_relative 'lib/fake_redis'

# YOLO, don't care
set :protection, :except => [:json_csrf]

OVERRIDE_PATH = File.join(File.dirname(__FILE__),'overrides.yml')

if !File.exist?(OVERRIDE_PATH)
  puts "Oops, we can not start. Please make sure that a #{File.basename(OVERRIDE_PATH)} "
  puts "exists in #{File.dirname(OVERRIDE_PATH)}"
  puts ""
  puts "You can clone #{File.basename(OVERRIDE_PATH)}.example to start."
  exit 1
end

configure do
  AD_SERVER = MockOpenX.new
  AD_SERVER.set_config_path(OVERRIDE_PATH)
  JS_TAG = MockOpenXJsTag.new
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
