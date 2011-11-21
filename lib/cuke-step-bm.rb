# encoding: utf-8
require "cuke-step-bm/cli"

module CukeStepBm
  # cuke_step_bm bm-cuke-step cuke-step-bm.rb
  # :bm => BenchMark(only for display)
  # :std => SimpleTimeDiff
  # :std_with_log => SimpleTimeDiff log
  # :off => Cucumber default do nothing

  BM_SUPPORTED_OUTPUT_MODES = [:bm, :std, :std_with_log, :off]

  class << self
    attr_accessor :root, :log_file, :output_mode, :delimiter

    def configure
      yield self
    end

    def suite!
      use_defaults!
      paths = [
          File.expand_path("config/cuke_step_bm.rb", root),
          File.expand_path(".cuke_step_bm", root),
          "#{ENV["HOME"]}/.cuke_step_bm"
      ]
      paths.each { |path| load(path) if File.exist?(path) }
      self.output_mode = :std unless BM_SUPPORTED_OUTPUT_MODES.include? output_mode
    end

    def use_defaults!
      configure do |config|
        config.root = File.expand_path('.', Dir.pwd)
        config.output_mode = :std
        config.log_file = File.join(config.root, 'features', 'steps_consuming.bms')
        config.delimiter = "-#{[20879].pack("U*")}-"
      end
    end

    def write_to_log(msg)
      File.open(log_file, "a+") { |f| f.write msg }
    rescue
      nil
    end

    #remove log file before cuke working with :std_with_log
    def remove_log!
      File.delete log_file if File.exist?(log_file) && (output_mode == :std_with_log)
    rescue Exception => e
      warn e.message
    end

  end # class << self
end # CucumberStepsBm

CukeStepBm.suite!

if defined?(Cucumber) && defined?(Cucumber::VERSION) && (Cucumber::VERSION >= "1.1.1") && (CukeStepBm.output_mode != :off)
  CukeStepBm.remove_log!

  module Cucumber
    module Ast
      class StepInvocation #:nodoc:
        def invoke(step_mother, configuration)
          exec_proc = Proc.new {
            find_step_match!(step_mother, configuration)
              unless @skip_invoke || configuration.dry_run? || @exception || @step_collection.exception
                @skip_invoke = true
                begin
                  @step_match.invoke(@multiline_arg)
                  step_mother.after_step
                  status!(:passed)
                rescue Pending => e
                  failed(configuration, e, false)
                  status!(:pending)
                rescue Undefined => e
                  failed(configuration, e, false)
                  status!(:undefined)
                rescue Cucumber::Ast::Table::Different => e
                  @different_table = e.table
                  failed(configuration, e, false)
                  status!(:failed)
                rescue Exception => e
                  failed(configuration, e, false)
                  status!(:failed)
                end
              end
          }

          if (CukeStepBm.output_mode == :bm) && defined?(Benchmark)
            Benchmark.bm do |reporter|
              reporter.report("Time consuming:") { exec_proc.call }
            end
          else
            time_begin = Time.now
            exec_proc.call
            time_end = Time.now
            time_for_output = "Step consume %s seconds.\n" % ["#{time_end - time_begin}"]
            time_consuming_message = ["#{time_end - time_begin}", @name, file_colon_line].join(CukeStepBm.delimiter)
            time_consuming_message << "\n"
            if CukeStepBm.output_mode == :std_with_log
              puts time_for_output
              CukeStepBm.write_to_log time_consuming_message
            else
              puts time_for_output
            end
          end
        end # invoke

      end # StepInvocation
    end # Ast
  end #  Cucumber
end
