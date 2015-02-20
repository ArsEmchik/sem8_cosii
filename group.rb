# encoding: utf-8

require_relative 'random_color'

class Group
  MAX_INTENSITY = 60000
  SQUARE_4 = [[-1, 0], [0, -1], [0, 1], [1, 0]]
  SQUARE_8 = [[-1, 0], [-1, 1], [-1, -1], [0, -1], [0, 1], [1, -1], [1, 0], [1, 1]]

  SQUARE = SQUARE_4

  attr_reader :mass, :count, :p, :comp, :dots, :process_queue, :decentered

  def initialize(img, checked)
    @img = img
    @mass = [1,1]
    @p = 1
    @dots = []
    @process_queue = []
    @checked = checked
  end

  def item?(c, r)
    SQUARE.any? { |dx, dy| @img.pixel_color(c + dx, r + dy).intensity > MAX_INTENSITY  }
  end

  def process
    while !@process_queue.empty?

      sc, sr = @process_queue.shift

      next if sc < 0 || sr < 0 || sc > @img.columns || sr > @img.rows
      next if @checked[sc][sr]

      # store all dots
      @dots << [sc, sr]

      # mark do as checked
      @checked[sc][sr] = true

      # calculate mass
      @mass[0] += sc
      @mass[1] += sr

      if item?(sc, sr)
        SQUARE.each { |dx, dy| (@process_queue << [sc + dx, sr + dy]) }
      else
        @p += 1
      end
    end
    count_metrics

  end

  def info
    return '' if @dots.empty?
    str ||=  "Площадь: #{@count}; "
    str += "Периметр: #{@p}; "
    str += "Компактность: #{@comp}; "
    str += "Нецентрированность: #{@decentered}; "
    str += "Ориентация: #{@orient}; "
    str
  end

  def analyzing_params
    [self.count, self.p]
  end

  private

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
