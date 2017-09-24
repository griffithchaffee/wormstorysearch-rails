module Minitest
  module Reporters
    class SuiteReporter < BaseReporter
      include ANSI::Code
      include RelativePosition

      attr_accessor :reporter_options, :recorder, :indent

      def initialize(*params, &block)
        super
        self.recorder = Recorder.new(self)
        self.indent = "   "
      end

      def start
        recorder.start!
        super
        puts
      end

      def before_suite(suite)
        if suite != NilClass
          recorder.started_suite!
          puts "#{suite} - #{suite.runnable_methods.size} tests".pluralize(suite.runnable_methods.size)
        end
      end

      def after_suite(suite)
        if suite != NilClass
          recorder.completed_suite!(suite)
          puts "#{indent}Duration: #{time_shorthand_s(recorder.completed_suite_time)}"
          puts
        end
      end

      def record(test)
        super
        clear_recording_test_instance_variables(test)
        print_recording_test_status(test)
        print_recording_test_failures_if_any(test)
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
        puts "Time Per Suite: #{time_shorthand_s(recorder.average_suite_time)}"
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

      def clear_recording_test_instance_variables(test)
        # save memory
        (test.instance_variables - %i[ @NAME @failures @assertions ]).each do |variable|
          next if variable.to_s.starts_with?("@_")
          test.instance_variable_set(variable, nil)
        end
      end

      def print_recording_test_status(test)
        print "  "
        print_colored_status(test)
        print "  "
        print time_shorthand_s(recorder.elapsed_time)
        print pad_test(test.name)
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
        attr_accessor *%i[
          start_time stop_time
          started_suite_time completed_suite_time
          completed_suite_count completed_test_count
        ]

        def initialize(reporter)
          self.completed_suite_count = 0
          self.completed_test_count = 0
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

        def started_suite!
          self.started_suite_time = time_at_now
        end

        def active_time
          stop_time || time_at_now
        end

        def active_suite_time
          completed_suite_time || time_at_now
        end

        def elapsed_duration
          active_time - start_time
        end

        def elapsed_time
          Time.at(elapsed_duration).gmtime
        end

        def average_test_time
          completed_test_count = 1 if completed_test_count.to_i < 1
          Time.at(elapsed_time.to_f / completed_test_count).gmtime
        end

        def average_suite_time
          self.completed_suite_count = 1 if completed_suite_count.to_i < 1
          Time.at(elapsed_time.to_f / completed_suite_count).gmtime
        end

        def completed_suite!(suite)
          self.completed_suite_time = Time.at(time_at_now - started_suite_time)
          self.completed_suite_count += 1
          self.completed_test_count += suite.runnable_methods.size
        end
      end
    end
  end
end
