class PrettyFormatter < ActiveSupport::Logger::SimpleFormatter
  include ActiveSupport::TaggedLogging::Formatter
  SQL_WORDS = []
  # multi word
  SQL_WORDS << [ "ORDER BY", "INNER JOIN", "INSERT INTO", "IS NULL", "LEFT OUTER JOIN", "IS NOT NULL", "NOT IN" ]
  # single word
  SQL_WORDS << %w[
    BEGIN COMMIT SELECT ROLLBACK UPDATE COUNT DISTINCT FIRST LAST NULLS DELETE NULLIF
    CASE ILIKE WHEN NULL THEN ELSE LOWER UPPER END CONCAT
  ]
  # partial spaced word
  SQL_WORDS << %w[ AND ASC DESC FROM LIMIT OFFSET ON ORDER RETURNING SET SQL VALUES WHERE ].map { |word| " #{word}" }
  # fully spaced word
  SQL_WORDS << %w[ AS OR IN NOT ].map { |word| " #{word} " }
  SQL_REGEXES = SQL_WORDS.map { |group| Regexp.new "(#{group.join('|')})" }

  def call(severity, datetime, progname, msg)
    tagged progname do
      msg = msg.to_s.strip
      return if msg.blank?
      datetime = datetime.strftime("%m-%d %H:%M:%S")

      severity = severity.upcase.rjust(5, " ")
      severity = " WARN" if msg.starts_with? "ActionController::RoutingError"
      case severity
      when " INFO"
        severity = severity.green
        msg.gsub! /\A(Started ([A-Z]+)|Completed)/, '\1'.green
      when "DEBUG"
        severity = severity.cyan
        SQL_REGEXES.each { |regex| msg.gsub! regex, '\1'.cyan }
      when " WARN" then severity = severity.yellow
      when "ERROR", "FATAL" then severity = severity.red
      end

      tags = current_tags.map(&:to_s).map(&:strip).select(&:present?).uniq.collect { |tag| "[#{tag.blue}]" }.join(" ") << " "
      "#{datetime} #{severity} #{tags if tags.present?}-- #{msg}\n"
    end
  end
end
