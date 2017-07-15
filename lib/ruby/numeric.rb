class Numeric
  def min(num)
    self < num ? num : self
  end

  def max(num)
    self > num ? num : self
  end

  def to_human_size
    return self if self < 1_000
    divid_and_round = -> (divider) { (to_f / divider).round(2).to_s.remove(/\.0\z/) }
    { "K" => 1_000, "M" => 1_000_000 }.each do |abbr, size|
      if self < size * 1_000
        value = (to_f / size).round(2).to_s.remove(/\.0\z/) # convert 1.0 to 1
        return divid_and_round.call(size) + abbr
      end
    end
    divid_and_round.call(1_000_000_000) + "B"
  end
end
