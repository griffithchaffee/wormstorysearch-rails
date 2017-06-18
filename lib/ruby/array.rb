class Array

  def all_present?
    select_present.size == size
  end

  def any_blank?
    !all_present?
  end

  def any_present?
    select_present.present?
  end

  def select_present
    select { |v| v.present? }
  end

  def order(columns)
    columns = Array(columns)
    sort_by { |v| columns.map { |column| v.send column } }
  end

  def squish(index = 1)
    self[0..index - 1] << self[index..-1].presence
  end

  def to_word_a
    map { |value| value.to_s.strip.presence }.compact
  end

  def to_uniq_word_csv
    to_word_a.uniq.join(",")
  end

  def to_queryable_list
    " #{to_word_a.join " "} "
  end

  def to_join_s(joiner)
    if size <= 2
      join " #{joiner} "
    else
      self[0..-2].join(', ') + ", #{joiner} #{last}"
    end
  end

  def to_or_s
    to_join_s 'or'
  end

  def to_and_s
    to_join_s 'and'
  end

  def nest(*nestings)
    self.map do |object|
      nestings.map do |method_or_proc|
        if method_or_proc.is_a? Proc
          object.instance_exec &method_or_proc
        else
          object.send method_or_proc
        end
      end
    end
  end

  def nest_to_hash(key, value)
    nest(key, value).to_h.with_indifferent_access
  end

  def find_in_ordered_batches(options = {}, &block)
    options = options.with_indifferent_access
    each_slice options[:batch_size] || 1000, &block
  end

  def find_each_in_order(options = {}, &block)
    find_in_ordered_batches(options).each { |group| group.each &block }
  end

end
