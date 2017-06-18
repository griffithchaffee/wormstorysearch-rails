module Comparable
  def not_between?(*params, &block)
    !between? *params, &block
  end
end
