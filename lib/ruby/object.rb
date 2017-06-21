class Object
  def not_in?(*params, &block)
    !in?(*params, &block)
  end

  def is_not_a?(*params, &block)
    !is_a?(*params, &block)
  end
end
