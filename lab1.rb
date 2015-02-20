# encoding: utf-8
require 'RMagick'
require 'k_means'
[File.expand_path('../group.rb', __FILE__)].each {|f| require f}

GROUPS = 6.freeze
MIN_SQUARE = 60.freeze
MIN_P = 10.freeze


####################################################
### Prepare images
####################################################
img = Magick::Image.read('images/image.jpg').first

# Changes the brightness, saturation, and hue
@med = img.dup.modulate(0.4)
@med.write 'images/result/med.jpg'

# Change the value of individual pixels based on the intensity of each pixel compared to threshold
@bin = @med.dup.threshold(Magick::MaxRGB * 0.10)
@bin.write 'images/result/bin.jpg'
####################################################


####################################################
### Detect items
####################################################
checked = []
2000.times { |i| checked[i] = Array.new(2000) }
@groups = []

@detect = @bin.dup
@detect.each_pixel do | _, column, row|
  group ||= Group.new(@detect, checked)

  if group.item?(column, row)
    group.process_queue << [column, row]
    group.process
    @groups << group
    group = Group.new(@detect, checked)
  end

  print '.' if column == 0
end

print "\n"

@groups.reject!{|g| g.dots.empty? || g.count < MIN_SQUARE || g.p < MIN_P}
@groups.each_with_index do |group, i|
  color = RandomColor.get
  puts "Группа ##{i}: #{group.info}"
  group.dots.each { |x,y| @detect.pixel_color(x, y, color) }
end

@detect.write 'images/result/detect.jpg'


####################################################
### Classify using k-medians algorythm
####################################################
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

@classify.write 'images/result/classify.jpg'

# Shoes.app(height: 600, width: 800) do
#   @img = image('images/image.jpg')
#
#   flow do
#     %w(image med bin detect classify).each do |type|
#       button(type) { @img.path = "images/#{type}.jpg" }
#     end
#   end#
# end
