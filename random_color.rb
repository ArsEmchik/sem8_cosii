class RandomColor
  class << self
    def get
      "##{color_byte}#{color_byte}#{color_byte}"
    end

    def color_byte
      '%02X' % rand(155)
    end
  end
end
