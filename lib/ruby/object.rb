class Object
  def not_in?(*params, &block)
    !in? *params, &block
  end
end
