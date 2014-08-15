require 'httparty'
require 'redis'
require 'json'
require 'yaml'
require 'erubis'

REDIS_URI = "redis://localhost:6379/"
CACHE_MINUTES_TO_LIVE = 5
LIB_LOCATION = File.dirname(__FILE__)

class MockOpenX

  attr_reader  :response_code,
               :content,
               :content_object

  def initialize
    @response_code = 0
    @response_headers = {}
    @content = ''
    @content_structure = {}
    @config_path = ''

    @default_ad_values = {'group_id' => 0, 'kind' => 'html', 'width' => 1, 'height' => 1, 'html' => "<p>..something..should..be..here..</p>"}

    begin
      @redis = Redis.new(:url => REDIS_URI)
      @redis.exists('this-is-just-here-to-force-a-connection')
    rescue Redis::CannotConnectError
      @redis = FakeRedis.new
    end
  end

  def set_config_path(path)
    @config_path = path
  end

  def request(openx_url, referrer)
    @referrer = referrer
    @openx_url = openx_url

    @response_code = 0
    @response_headers = {}
    @content = ''
    @content_structure = {}

    get_request_from_openx

    if success?
      remove_callback
      insert_custom_ad_units
      add_callback
    end
  end

  def headers
    # Only returns the ones I want, with the correct key conversion
    Hash[{:cache_control => "Cache-Control",
     :content_type => "Content-Type",
     :pragma => "Pragma",
     :server => "Server",
     :expires => "Expires",
     :set_cookie => "Set-Cookie"
    }.map{|k,v| [v,@response_headers[k].to_s]}].merge({
      "Content-Length" => @content.length,
      "Content-Type" => "application/javascript"
    })
  end

  def success?
    @response_code == 200
  end

  protected

  def callback_name
    /callback=(OX_[0-9]+)/.match(@openx_url)[1]
  end

  # URL of the page that this is being requested for.
  def chorus_url
    match = /ju=(.*)&jr/.match(@openx_url)
    match[1]
  end

  # Strip out the random stuff generated each time,
  # so that the key is more "stable
  def key_for_request
    "#{@referrer}-#{@openx_url.to_s.gsub(/o=[0-9]+&callback=OX_[0-9]+/,'')}v4"
  end

  def get_request_from_openx
    response = {}
    if !@redis.exists(key_for_request)
      openx_response = HTTParty.get(@openx_url)
      response = {'body' => openx_response.body,
                  'code' => openx_response.code,
               'headers' => openx_response.headers.to_h}
      # Cache this for 5 minutes
      @redis.setex(key_for_request, CACHE_MINUTES_TO_LIVE*60, response.to_json)
    else
      begin
        response = JSON.parse(@redis.get(key_for_request).to_s)
      rescue JSON::ParserError
        puts "\n\nREDIS PARSE ERROR: #{key_for_request}, #{@redis.get(key_for_request).to_s}\n\n"
      end
    end

    @response_code = response.fetch('code',500)
    @response_headers = response.fetch('headers',{})
    @content = response.fetch('body','OH NO SOMETHING BAD HAPPENED')
  end

  def remove_callback
    # Removes OX_2144423213(...) from the string
    @content.gsub!(/^\s*OX_([0-9]+\()/,'')
    @content.gsub!(/\);$/,'')
  end

  def add_callback
    # Remove this just in case
    remove_callback
    # Now wrap in the callback function
    @content = "#{callback_name}(#{@content});"
  end

  def insert_custom_ad_units
    ad_template = Erubis::Eruby.new(IO.read(File.join(LIB_LOCATION, 'ad_fragment.js.erb')))

    structured_content = JSON.parse(@content)

    ad_units = structured_content.fetch('ads',{}).fetch('adunits',{});

    # Pluck from config file
    begin
      applicable_ad_units = get_config_ad_units_for_url
    rescue Psych::SyntaxError => err
      puts "*"*80
      puts "Ignoring #{File.basename(@config_path)} until syntax error is resolved:\n#{err.message}"
      puts "*"*80
      applicable_ad_units = []
    end

    # Return an Array of integers as ad unit ids
    configured_ad_unit_ids = applicable_ad_units.map{|a| a['unit_id'].to_i}
    puts "Using custom ad units: #{configured_ad_unit_ids.join(', ')}"

    # Step through each ad unit and either keep it or replace it with overriding ad unit
    ad_units.map! do |ad_config|
      if configured_ad_unit_ids.include?(ad_config['auid'].to_i)
        configured_ad_unit_ids -= [ad_config['auid'].to_i]
        JSON.parse(ad_template.result(@default_ad_values.merge(applicable_ad_units.detect{|a| a['unit_id'].to_i == ad_config['auid'].to_i})))
      else
        ad_config
      end
    end

    # configured_ad_unit_ids now holds the un-replaced units, lets add them in
    ad_units += configured_ad_unit_ids.map do |unit_id|
      JSON.parse(ad_template.result(@default_ad_values.merge(applicable_ad_units.detect{|a| a['unit_id'].to_i == unit_id})))
    end


    structured_content['ads']['adunits'] = ad_units
    @content = JSON.pretty_generate(structured_content)
  end

  # Checks for a match of the URL pattern to what is being requested
  def get_config_ad_units_for_url(url = chorus_url)
    configuration = YAML.load_file(@config_path)
    ad_units_for_url = configuration['ad_units'].select do |ad_config|
                                                    # Pattern to normalize leadin/trailing
                                                    # regular exp slashes in config
                                                    # http://rubular.com/r/XXVRCayQvK
      !(Regexp.new(ad_config['url_pattern'].to_s.gsub(/^\/|\/$/,'')) =~ url).nil?
    end

    ad_units_for_url.map do |ad_unit|
      ad_unit['html'].gsub!('"','\"')
      ad_unit
    end
  end
end