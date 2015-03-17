class K_Means
  def initialize(array, groups = 7, cluster_centers = [], max_operations = 10)
    @array = array # array of array of dots
    @max_operations = max_operations
    @groups = groups
    @cluster_centers = cluster_centers

    if @cluster_centers.empty?
      indexes = (0..array.size).to_a.shuffle
      @groups.times { |i |@cluster_centers << @array[i] }
    end

    @prev_array = []
    @array.size.times { @prev_array << @cluster_centers.first }
  end

  def view
    while features_clusters_changed?
      break if (@max_operations -= 1) == 0
      new_cluster_centers
    end

    groped_array = Array.new(@groups)

    @cluster_centers.each_with_index do |cluster_center, index|
      groped_array[index] = (@prev_array.each_with_index.map { |p_a, m_index| m_index if p_a == cluster_center }).compact
    end
    groped_array
  end

  def cluster_centers
    @cluster_centers
  end

  private

  def features_clusters_changed?
    changed = false

    @array.each_with_index do |group, index|
      min_distance = get_distance_to_center(group, @cluster_centers.first)
      nearest_cluster = @cluster_centers.first

      @cluster_centers.each do |cluster_center|
        distance = get_distance_to_center(group, cluster_center)
        if distance < min_distance
          min_distance = distance
          nearest_cluster = cluster_center
        end
      end

      changed = true if @prev_array[index] != nearest_cluster
      @prev_array[index] = nearest_cluster
    end
    changed
  end

  def get_distance_to_center(group, cluster_center)
    result = 0
    group.zip(cluster_center).each { |group_dot, cluster_dot| result += (group_dot - cluster_dot)**2 }
    Math.sqrt(result)
  end

  def new_cluster_centers
    new_center = Array.new(@array.first.size)

    @cluster_centers.map! do |cluster_center|
      new_center.map! { |e| e = 0.0 }
      num_contours_in_cluster = 0.0

      @array.zip(@prev_array).each do |group, nearest_cluster|
        if nearest_cluster == cluster_center
          new_center = new_center.zip(group).map { |center_dot, group_dot| center_dot + group_dot }
          num_contours_in_cluster += 1.0
        end
      end

      cluster_center = new_center.zip(cluster_center).map! do |new_dot, cluster_dot|
        new_dot /= num_contours_in_cluster
        new_dot = new_dot.round(6)
        cluster_dot = new_dot
      end
    end
  end
end
