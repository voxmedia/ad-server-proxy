require 'erubis'

LIB_LOCATION = File.dirname(__FILE__)
CARTRIDGES_DIR = File.join(File.dirname(__FILE__),'..','cartridges')
DEFAULT_CARTRIDGE = File.join(CARTRIDGES_DIR,'default.cart')

class CartridgeOpenX < MockOpenX

  attr_reader :cartridges

  def initialize
    @cartridges = {}
    load_cartridges
    super
  end

  # Load cartridges from the directory...
  def load_cartridges(location = CARTRIDGES_DIR)
    @cartridges = {}
    Dir.glob("#{location}/**.cart").each do |cart_file|
      cart = File.read(cart_file)
      # if enabled -- http://rubular.com/r/wBOcCprhuS
      if cart =~ /^\s*enabled:\s*(true|yes|okay|sure|yep|yarp)\s*$/i
        # where it is it targeted http://rubular.com/r/1SbLWxdCOs
        target = cart.match(/^\s*url_pattern:\s*(\S+)\s*$/i)
        # get the response - http://rubular.com/r/tzXfmVxbT8
        content = cart.match(/^\s*OX_[0-9]+\({.*/im)
        if target.size > 1 && content.size > 0
          # matching regexp is the hash key
          @cartridges[target[1].gsub(/^\/|\/$/,'')] = content[0]
        end
      end
    end
  end

  def debug_cartridges
    puts "\nCARTS:"
    @cartridges.each{|k,v| puts ">#{("/"+k.to_s+"/").ljust(8)} | #{v.to_s[0,30]}..."}
  end

  protected

  def get_first_cartridge_for_request
    cart = @cartridges.detect(){|cart|
      Regexp.new(cart[0].to_s) =~ chorus_url
    }
    cart.nil? ? "" : cart[1]
  end

  def get_request_from_openx
    content = get_first_cartridge_for_request

    @response_code = content.size > 0 ? 200 : 404
    @content = content || ""
  end

end