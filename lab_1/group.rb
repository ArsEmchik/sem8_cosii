# encoding: utf-8
require_relative 'random_color'

class Group
  MAX_INTENSITY = 60000.freeze
  SQUARE_4 = [[-1, 0], [0, -1], [0, 1], [1, 0]].freeze
  SQUARE_8 = [[-1, 0], [-1, 1], [-1, -1], [0, -1], [0, 1], [1, -1], [1, 0], [1, 1]].freeze

  SQUARE = SQUARE_8

  attr_reader :mass, :count, :p, :comp, :dots, :decentered, :orient

  def initialize(image_arr)
    @mass = [1, 1]
    @p = 1
    @dots = []
    @image_arr = image_arr
    @orient = 0
  end


  def process
    calculate_mass
    calculate_perimeter
    count_metrics
  end

  def info
    return '' if @dots.empty?
    str ||= "Площадь: #{@count}; "
    str += "Периметр: #{@p}; "
    str += "Компактность: #{@comp}; "
    str += "Нецентрированность: #{@decentered.round(6)}; "
    str += "Ориентация: #{@orient.round(6)}; "
    str
  end

  def analyzing_params
    [self.count, self.p, self.comp, self.decentered.round(6)]
  end


  def self.item?(pixel)
    pixel.intensity > MAX_INTENSITY
  end

  private

  def calculate_mass
    @dots.each do |row, column|
      @mass[0] += row
      @mass[1] += column
    end
  end

  def calculate_perimeter
    @dots.each do |row, column|
      if row == @image_arr.length - 1 || column == @image_arr[0].length - 1
        @p += 1
        next
      end
      @p += 1 if border_pixel?(row, column)
    end
  end

  def border_pixel?(row, column)
    SQUARE.any? { |dx, dy| @image_arr[row + dx][column + dy] < 1 } #!?
  end

  def count_metrics
    return if @dots.empty?
    @count = @dots.size

    # #mass
    @mass[0] /= @count
    @mass[1] /= @count

    # #compact
    @comp = @p ** 2 / @count

    # #decentered
    m20 = moment(2, 0)
    m02 = moment(0, 2)
    m11 = moment(1, 1)
    s1 = m20 + m02
    s2 = ((m20 - m02) ** 2 + 4 * m11 * m11) ** 0.5
    @decentered = (s1 + s2) / (s1 - s2)

    # #orientation
    @orient = Math.atan(2 * m11 / (m20 - m02)) / 2

  rescue ZeroDivisionError
  end

  def moment(i, j)
    @dots.inject(0) { |sum, (x, y)| sum + ((x - @mass[0]) ** i) * ((y - @mass[1]) ** j) }
  end
end
