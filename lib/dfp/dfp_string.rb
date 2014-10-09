# http://defindit.com/ascii.html
class DFPString < String
  CONVERTABLE_CHARS = [34, 38, 39, 60, 61, 62, 96]

  def decode
    gsub(/x[0-7][A-Fa-f0-9]/) do |c|
      c[1..2].hex.chr
      CONVERTABLE_CHARS.include?(c[1..2].hex) ? c[1..2].hex.chr : c
    end
  end

  def encode
    gsub(/./) do |c|
      case c.ord
      when 34, 38, 39, 60, 61, 62, 96
        'x'+c.ord.to_s(16)
      else
        c
      end
    end
  end
end