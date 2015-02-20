# encoding: utf-8
require 'RMagick'
require 'k_means'
require 'colorize'
[File.expand_path('../group.rb', __FILE__)].each {|f| require f}

GROUPS = 6
MIN_SQUARE = 60
MIN_P = 10

#
# Prepare images and data
#

img = Magick::Image.read('images/image.jpg').first

@med = img.dup.modulate(0.4)
@med.write 'images/med.jpg'

@bin = @med.dup.threshold(Magick::MaxRGB * 0.25)
@bin.write 'images/bin.jpg'

@groups = []
checked = []
2000.times { |i| checked[i] = Array.new(2000) }

#
# Detect items
#
@detect = @bin.dup

@detect.each_pixel do |p, c, r|
  group ||= Group.new(@detect, checked)

  if group.item?(c,r)
    group.process_queue << [c,r]
    group.process
    @groups << group
    group = Group.new(@detect, checked)
  end
  print "." if c == 0
end

print "\n"

@groups.reject!{|g| g.dots.empty? || g.count < MIN_SQUARE || g.p < MIN_P}

@groups.each_with_index do |group, i|
  color = RandomColor.get
  puts "Группа ##{i}: #{group.info}"
  group.dots.each { |x,y| @detect.pixel_color(x, y, color) }
end


@detect.write 'images/detect.jpg'

# Classify using k-medians algorythm

@classify = @bin.dup

data = @groups.map{|g| g.analyzing_params}
kmeans = KMeans.new(data, :centroids => GROUPS).view
kmeans.each do |ind|
  color = RandomColor.get
  ind.each do |i|
    params = data[i]
    selected = @groups.select{|g| g.analyzing_params == params }
    selected.each do |group|
      group.dots.each {|x,y| @classify.pixel_color(x, y, color) }
    end
  end
end

@classify.write 'images/classify.jpg'

# Shoes.app(height: 600, width: 800) do
#   @img = image('images/image.jpg')
#
#   flow do
#     %w(image med bin detect classify).each do |type|
#       button(type) { @img.path = "images/#{type}.jpg" }
#     end
#   end
#
# end
