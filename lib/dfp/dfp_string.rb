# http://defindit.com/ascii.html
class DFPString < String
  CONVERTABLE_CHARS = [34, 38, 39, 60, 61, 62, 96]

  def decode
    gsub(/x[0-7][A-Fa-f0-9]/) do |c|
      CONVERTABLE_CHARS.include?(c[1..2].hex) ? c[1..2].hex.chr : c
    end
  end

  def encode
    gsub(/./) do |c|
      CONVERTABLE_CHARS.include?(c.ord) ? 'x'+c.ord.to_s(16) : c
    end
  end
end