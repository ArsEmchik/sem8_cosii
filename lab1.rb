# encoding: utf-8
require 'RMagick'
require 'k_means'
[File.expand_path('../group.rb', __FILE__)].each { |f| require f }

GROUPS = 6.freeze
MIN_SQUARE = 60.freeze
MIN_P = 10.freeze


####################################################
### Prepare images
####################################################
img = Magick::Image.read('images/image.jpg').first

# Changes the brightness, saturation, and hue
med = img.dup.modulate(0.4)
med.write 'images/result/med.jpg'

# Change the value of individual pixels based on the intensity of each pixel compared to threshold
bin = med.dup.threshold(Magick::MaxRGB * 0.15)
bin.write 'images/result/bin.jpg'
detect = bin.dup
####################################################


####################################################
### Detect items
####################################################
@image_arr = []
bin.rows.times { |i| @image_arr[i] = Array.new(bin.columns) }

bin.each_pixel do |pixel, column, row|
  @image_arr[row][column] = Group.item?(pixel) ? 1 : 0
end

@kn, @km, @a, @b, @c = 0, 0, 0, 0, 0
@group_number = 1

image_arr = @image_arr
image_arr.each_with_index do |row, i|
  row.each_with_index do |m_pixel, j|
    @kn = j - 1
    if @kn <= 0
      @kn = 1
      @b = 0
    else
      @b = @image_arr[i][@kn]
    end

    @km = i - 1
    if @km <= 0
      @km = 1
      @c = 0
    else
      @c = @image_arr[@km][j]
    end

    @a = @image_arr[i][j]
    if @a == 0
      next
    elsif @b == 0 && @c == 0 &&
        @group_number += 4
      @image_arr[i][j] = @group_number
    elsif @b != 0 && @c == 0
      @image_arr[i][j] = @b
    elsif @b == 0 && @c != 0
      @image_arr[i][j] = @c
    elsif @b != 0 && @c != 0
      if @b == @c
        @image_arr[i][j] = @c
      else
        if @b <= @c
          @image_arr[i - 1][j] = @image_arr[i][j - 1]
        else
          @image_arr[i][j - 1] = @image_arr[i - 1][j]
        end
        @image_arr[i][j] = @image_arr[i][j - 1]
      end
    end
  end
  print '.'
end

@groups = {}
@image_arr.each_with_index do |row, i|
  row.each_with_index do |m_pixel, j|
    next if m_pixel <= 1
    group = @groups[m_pixel.to_s] || Group.new(@image_arr)
    group.dots << [i, j]
    @groups[m_pixel.to_s] = group
  end
end

@groups = @groups.values
@groups.each { |group| group.process }

@groups.reject! { |g| g.dots.empty? || g.count < MIN_SQUARE || g.p < MIN_P }
@groups.each_with_index do |group, i|
  color = RandomColor.get
  puts "Группа ##{i}: #{group.info}"
  group.dots.each { |x, y| detect.pixel_color(y, x, color) }
end

detect.write 'images/result/detect.jpg'

# ####################################################
# ### Classify
# ####################################################
@classify = bin.dup

data = @groups.map { |g| g.analyzing_params }
kmeans = KMeans.new(data, :centroids => @groups.count).view
kmeans.each do |ind|
  color = RandomColor.get
  ind.each do |i|
    params = data[i]
    selected = @groups.select { |g| g.analyzing_params == params }
    selected.each do |group|
      group.dots.each { |x, y| @classify.pixel_color(y, x, color) }
    end
  end
end

@classify.write 'images/result/classify.jpg'
