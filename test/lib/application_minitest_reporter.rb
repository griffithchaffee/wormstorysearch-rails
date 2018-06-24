module Minitest
  module Reporters
    class ApplicationReporter < BaseReporter
      include ANSI::Code
      include RelativePosition

      attr_accessor(*%i[
        recorder
        indent
        active_suite_name
      ])

      def initialize(*params, &block)
        super
        self.recorder = Recorder.new(self)
        self.indent = "   "
        self.active_suite_name = nil
      end

      def start
        recorder.start!
        super
        puts
      end

      def before_suite(first_test)
        suite = first_test.class
        suite_test_count = suite.runnable_methods.size
        puts "#{first_test.class} - #{suite_test_count} tests"
      end

      def after_suite(last_result)
        puts
      end

      def before_test(first_test)
        suite_name = first_test.class.name
        if suite_name != active_suite_name
          # call after_suite when we change suites
          after_suite(active_suite_name) if !active_suite_name.nil?
          before_suite(first_test)
          self.active_suite_name = suite_name
        end
      end

      def after_test(result)
        # noop
      end

      def record(result)
        super
        print_recording_test_status(result)
        print_recording_test_failures_if_any(result)
      end

      def report
        recorder.stop!
        super
        print_reporting_failures_if_any
        print_reporting_results
      end

    protected

      def time_shorthand_s(time)
        if time < Time.at(60.seconds).gmtime
          time.strftime("%S.%L")
        elsif time < Time.at(60.minutes).gmtime
          time.strftime("%M:%S.%L")
        else
          time.strftime("%T.%L")
        end
      end

      def print_reporting_results
        puts "Finished After: #{time_shorthand_s(recorder.elapsed_time)}"
        # tests breakdown
        print "#{count} tests"
        print ", ", "#{assertions} assertions".green
        print ", ", "#{failures} failures".red if failures.nonzero?
        print ", ", "#{errors} errors".yellow if errors.nonzero?
        print ", ", "#{skips} skips".yellow if skips.nonzero?
        puts
        puts
      end

      def print_reporting_failures_if_any
        failed_tests = tests.select { |test| test.failure && !test.skipped? }
        if failed_tests.any?
          puts
          puts "=== ERROR MESSAGES ===".red
          failed_tests.each do |test|
            print_colored_status(test)
            puts "#{indent}#{test.class} #{test.name}"
            "#{test.failure.exception.class}: #{test.failure.exception.message}".each_line do |line|
              puts pad(line)
            end
            test.failure.backtrace.each do |line|
              puts pad(line) if line.include?(Rails.root.to_s)
            end
            puts
          end
          puts
        end
        puts
      end

      def print_recording_test_status(result)
        print "  "
        print_colored_status(result)
        print "  "
        print time_shorthand_s(recorder.elapsed_time)
        print "  #{result.name}"
        puts
      end

      def print_recording_test_failures_if_any(test)
        if !test.skipped? && test.failure
          puts pad("#{test.class} #{test.name}")
          "#{test.failure.exception.class}: #{test.failure.exception.message}".each_line do |line|
            puts pad(line)
          end
          test.failure.backtrace.each do |line|
            puts pad(line) if line.include?(Rails.root.to_s)
          end
          puts
        end
      end

      class Recorder
        attr_accessor(*%i[ start_time stop_time ])

        def initialize(reporter)
        end

        def time_at_now
          Time.now.gmtime
        end

        def start!
          self.start_time = time_at_now
        end

        def stop!
          self.stop_time = time_at_now
        end

        def active_time
          stop_time || time_at_now
        end

        def elapsed_duration
          active_time - start_time
        end

        def elapsed_time
          Time.at(elapsed_duration).gmtime
        end
      end
    end
  end
end
