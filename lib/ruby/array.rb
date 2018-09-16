class Array

  def nest(*nestings)
    map do |object|
      nestings.map do |method|
        object.send(method)
      end
    end
  end

  def nest_to_h(key, value)
    nest(key, value).to_h.with_indifferent_access
  end

end
