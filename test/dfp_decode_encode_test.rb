require 'test/unit'
require 'json'
require 'tempfile'

require_relative '../lib/dfp/dfp_string'

class DFPDecodeEncodeTest < Test::Unit::TestCase
  def setup
    response_file = File.read(File.join(File.dirname(__FILE__),'fixtures','dfp-response.js'))
    @cleaned = response_file.gsub('googletag.impl.pubads.setAdContentsBySlotForSync(','').gsub(/\);$/,'')
    @response = JSON.parse(@cleaned)
  end

  def test_encoding_works_on_simple_string
    @response.each do |slot|
      slot_info = slot.values.first
      html = slot_info.fetch('_html_','')
      assert html.length
      assert DFPString.new(html).decode.length
    end

    @response.each do |slot|
      slot_info = slot.values.first
      html = slot_info.fetch('_html_','')
      # assert_equal html.length, DFPString.new(html).decode.encode.length
      assert_equal html[0..50], DFPString.new(html).decode.encode[0..50]
    end
  end

  def test_decoding_works
    slot = @response.first
    slot_info = slot.values.first
    html = slot_info.fetch('_html_','')
    assert_equal '<script type="text/javascript">' , DFPString.new(html).decode[0..30]
    assert_not_equal '<script type="text/javascript">' , html[0..30]
  end

  def test_encoding_works_on_full_string
    @response.each do |slot|
      slot_info = slot.values.first
      html = slot_info.fetch('_html_','')
      recode = DFPString.new(html).decode.encode
      # Big diff in FileMerge.app is easier to read
      if html != recode
        original = Tempfile.new('original')
        original.write(html)
        original.close

        recoded = Tempfile.new('recoded')
        recoded.write(recode)
        recoded.close

        command =  "opendiff #{original.path} #{recoded.path}"
        puts `#{command}`
      end
      assert_equal html, recode
    end
  end
end
