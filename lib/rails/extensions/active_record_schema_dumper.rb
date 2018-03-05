module ActiveRecord
  class SchemaDumper
  private 
    def header(stream)
      stream.puts 'def change'
      stream.puts ''
    end

    alias_method :_table, :table
    def table(table, stream)
      table_stream = StringIO.new
      _table table, table_stream
      lines = table_stream.string.lines.select(&:present?)
      return stream if lines.blank?
      indexes = []
      header, trailer = nil
      lines = lines.map do |line|
        if line.strip.starts_with? "add_index "
          indexes << line
          nil
        elsif line.strip.starts_with? "create_table "
          header = line
          nil
        elsif line.strip == "end"
          trailer = line
          nil
        else line
        end
      end.compact
      stream.puts
      stream.puts header if header.present?
      lines.sort.each { |line| stream.puts line }
      stream.puts trailer if trailer.present?
      indexes.sort.each { |index| stream.puts index }
      stream.puts
      stream
    end
  end
end
