require 'test/unit'
require_relative '../lib/fake_redis.rb'
require_relative '../lib/mock_openx.rb'
require_relative '../lib/cartridge_based_openx.rb'

# Test our entries API
class CartridgeOpenXProxyTest < Test::Unit::TestCase
  SAMPLE_OPENX_URL = 'http://ox-d.sbnation.com/w/1.0/acj?o=6565676137&callback=OX_6565676137&ju=http%3A//local.daverge.com%3A3000/2014/4/22/5638658/Resident-Evil-6-movie-production-begins&jr=&tid=17&pgid=13823&auid=561878%2C623001%2C549376%2C551724%2C304996&c.browser_width=xlarge&c.device_type=desktop&c.network=polygon&c.entry_id=5402699&c.entry_type=article&c.entry_group=12127%2C12129%2C12131%2C12153%2C12463&c.hub_page=playstation%2Cnintendo%2Cxbox-360&c.forum=resident-evil&c.polygon_game=9315&c.polygon_game_genre=15&res=1920x1200x24&plg=swf%2Csl%2Cqt%2Cshk%2Cpm&ch=UTF-8&tz=300&ws=1486x962&vmt=1&si=6319208572&sd=4'

  def setup
    # Not a real fixture
    cartridge_path = File.join(File.dirname(__FILE__),'fixtures')
    config_path = File.join(File.dirname(__FILE__),'fixtures','overrides.yml')

    @ad_server = CartridgeOpenX.new()
    @ad_server.debug_cartridges
    @ad_server.load_cartridges(cartridge_path)
    @ad_server.set_config_path(config_path)
  end

  # Test that we can retrieve a specific thing
  def test_request_responds_to_data
    @ad_server.request(SAMPLE_OPENX_URL,'http://theverge.com')

    assert_equal 200, @ad_server.response_code
    assert @ad_server.content.include?('"ads": {')
    assert @ad_server.content.include?('"adunits":')
  end
end
