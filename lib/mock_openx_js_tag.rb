require 'rest_client'

# Used to request this type of thing:
#   http://ox-d.sbnation.com/w/1.0/jstag
class MockOpenXJsTag
  attr_reader  :response_code,
               :content,

  def initialize
    @response = ''
    @response_headers = {}
    @response_code = 404
    @content = ''
    @has_been_requested = false
  end

  def headers
    # Only returns the ones I want, with the correct key conversion
    Hash[{:cache_control => "Cache-Control",
     :content_type => "Content-Type",
     :pragma => "Pragma",
     :server => "Server",
     :expires => "Expires"
    }.map{|k,v| [v,@response_headers[k].to_s]}].merge({
      "Content-Length" => @content.length,
      "Content-Type" => "application/javascript"
    })
  end

  def request(url)
    # We only need to do this once,
    # it doesn't change after the first one
    if !@has_been_requested
      openx_response = RestClient.get(url)
      @content = rewrite_fetch_proxy(openx_response.to_s)
      @response_code = openx_response.code
      @response_headers = openx_response.headers
      @has_been_requested = true
    end
  end

  private

  def rewrite_fetch_proxy(js_content)
    # http://rubular.com/r/EOe9mq9sir
    regex_to_get_fetch_ads_url = /createAdRequestURL\(\);(\w+)=(\w+).template\(F.Templates.SCRIPT\,{src:(\w+),/
    js_content.gsub(regex_to_get_fetch_ads_url) do |url|
      url.gsub('src:k','src:(\'http://localhost:9292/mock?url=\'+encodeURIComponent(k))')
    end
  end
end
