module StorySearcher
  class UniversalSearcher

    def convert_word_count_to_i(word_count)
      case word_count
      when /\d+/ then word_count.to_i
      when /\d+k/ then word_count.remove(/\D/).to_i * 1_000
      when /\d+m/ then word_count.remove(/\D/).to_i * 1_000_000
      when "" then 0
      else raise ArgumentError, "unknown word_count format: #{word_count.inspect}"
      end
    end

    class << self
      def search!(updated_after)
        new.search!(updated_after)
      end
    end

  end
end
