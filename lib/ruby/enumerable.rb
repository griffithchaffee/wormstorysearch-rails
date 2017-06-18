module Enumerable

  delegate :nest, :nest_to_hash, to: :to_a

  def get(params = {}, &block)
    if block
      get_all(params).find { |x| (x.is_a?(Hash) ? x.to_struct : x).instance_exec &block }
    else
      find { |x| params.each { |k,v| break false if (x.is_a?(Hash) ? x.to_struct : x).send(k) != v } }
    end
  end

  def get_all(params = {}, &block)
    result = self
    if block
      result = result.find_all { |x| (x.is_a?(Hash) ? x.to_struct : x).instance_exec &block }
    end
    result.find_all { |x| params.each { |k,v| break false if (x.is_a?(Hash) ? x.to_struct : x).send(k) != v } }
  end

end
