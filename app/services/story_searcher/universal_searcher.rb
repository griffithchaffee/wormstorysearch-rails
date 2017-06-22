module StorySearcher
  class UniversalSearcher

    def convert_word_count_to_i(word_count)
      case word_count
      when /\A\d+\z/ then word_count.to_i
      when /\A\d+(\.\d+)?k\z/ then word_count.remove(/[^\d.]/).to_f * 1_000
      when /\A\d+(\.\d+)?m\z/ then word_count.remove(/[^\d.]/).to_f * 1_000_000
      when "" then 0
      else raise ArgumentError, "unknown word_count format: #{word_count.inspect}"
      end.to_i
    end

    class << self
      def search!(updated_after)
        new.search!(updated_after)
      end
    end

  end
end
