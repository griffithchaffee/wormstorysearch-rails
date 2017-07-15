class Numeric
  def min(num)
    self < num ? num : self
  end

  def max(num)
    self > num ? num : self
  end

  def to_i_or_round(precision: 2)
    to_s.ends_with?(".0") ? to_i : round(precision)
  end

  def to_human_size(precision: 2)
    return self if self < 1_000
    divide_and_round = -> (divider) { (to_f / divider).to_i_or_round(precision: precision).to_s }
    { "K" => 1_000, "M" => 1_000_000 }.each do |abbr, size|
      if self < size * 1_000
        return divide_and_round.call(size) + abbr
      end
    end
    divide_and_round.call(1_000_000_000) + "B"
  end
end
