class Numeric
  def min(num)
    self < num ? num : self
  end

  def max(num)
    self > num ? num : self
  end

  def to_i_or_round(precision: 2, pretty: false)
    rounded = round(precision)
    return rounded.to_s.remove(".0").to_i if rounded.to_s.ends_with?(".0")
    if pretty
      number, decimal = rounded.to_s.split(".")
      if number.length >= precision
        number.to_i
      else
        decimal =
        (number + "." + decimal[0..(precision - 1 - number.length)]).to_f
      end
    else
      rounded
    end
  end

  def to_human_size(precision: 2, pretty: false)
    return self if self < 1_000
    divide_and_round = -> (divider) { (to_f / divider).to_i_or_round(precision: precision, pretty: pretty).to_s }
    { "K" => 1_000, "M" => 1_000_000 }.each_with_index do |(abbr, size), i|
      if self < size * 1_000
        return divide_and_round.call(size) + abbr
      end
    end
    divide_and_round.call(1_000_000_000) + "B"
  end
end
