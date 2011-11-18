# encoding: utf-8

require 'optparse'
#require 'ostruct'

module CukeStepBm
  class Cli

    class Options
      #SCOPES = [:step, :feature]
      def parse!(args)
        options = {}
        opt_parser = OptionParser.new("", 30, '  ') do |opts|
          opts.banner = "Usage: cuke-step-bm options"

          opts.on("-f", "--feature FEATURE", String, "In specify feature") do |feature|
            options[:feature] = feature
          end

          opts.on("-M", "--most", "Show the most time-consuming step") do
            options[:act] = [ :most ]
          end

          opts.on("-t", "--total", "Show the total time-consuming") do
            options[:act] = [ :total ]
          end

          opts.on("-w", "--within from,to", Array, "Show the steps time-consuming within the given range (use: -w 1,2)") do |from_to|
            if from_to.size < 2
              puts "wrong argument size"
              exit
            end
            options[:act] = [ :within, [from_to.first, from_to.last] ]
          end

          opts.on("-l", "--less VALUE", Float, "Show the steps time-consuming less than or equal the given(Mean value)") do |v|
            options[:act] = [ :less, v ]
          end

          opts.on("-m", "--more VALUE", Float, "Show the steps time-consuming more than or equal the given(Mean value)") do |v|
            options[:act] = [ :more, v ]
          end

          #opts.on("-s", "--scope value", "Show messages within scope (all/feature_filepath)") do |v|
          #  v = v.to_sym
          #  v = :step unless SCOPES.include? v
          #  options[:scope] = v
          #end

          opts.separator ""
          opts.separator "Common options:"

          opts.on_tail("-h", "--help", "Show this usage message") do
            puts opts
            exit
          end

          opts.on_tail("-v", "--version", "Show version") do
            puts "cuke-step-bm #{CukeStepBm::VERSION}"
            exit
          end
        end
        opt_parser.parse! args
        options
      end
    end # Options


    def self.execute(args)
      new(args).execute
    end

    #attr_reader :opt_parser

    def initialize(args)
      @config = CukeStepBm
      @log_file = @config.log_file
      bm_validate!
      @options = Options.new.parse! args
      @options = default_options.merge @options
      @options[:act] = [ :most ] unless @options[:act]
      #@scope = @options.delete :scope
    end

    def execute
      parse_bms!
      self.send *@options[:act]
    end

    private
    def most
      the_most = @bms.sort_by { |item| item[:consume] }.last
      if in_feature?
        msg = "The most time-consuming in %s:\n\tLine: %s, Step: [ %s ], take %s seconds." % [
            msg_color(the_most[:feature], "red"),
            the_most[:line],
            msg_color(the_most[:step], "red"),
            msg_color(the_most[:consume])
        ]
        info(msg)
      else
        msg = "The most time-consuming in all features:In %s, Line: %s, Step: [ %s ], take %s seconds.\n\n" % [
            msg_color(the_most[:feature], "red"),
            the_most[:line],
            msg_color(the_most[:step], "red"),
            msg_color(the_most[:consume])
        ]
        info(msg)
        feature_grp_hash = @bms.group_by { |item| item[:feature] }
        feature_grp_hash.each do |feature, value|
          the_most = value.sort_by { |item| item[:consume] }.last
          msg = "In feature [ %s ]\n\tLine: %s, Step: [ %s ], take %s seconds.\n\n" % [
            msg_color(the_most[:feature] || feature, "red"),
            the_most[:line],
            msg_color(the_most[:step], "red"),
            msg_color(the_most[:consume])
          ]
          info(msg)
        end # grp_hash

      end # in_feature?
    end # most

    def total
      t_ary = @bms.collect { |item| item[:consume] }
      sum = t_ary.inject(:+)
      if in_feature?
        feature = @bms.first[:feature]
        info "Feature %s, %s steps total consume: %s seconds." % [msg_color(feature), msg_color(t_ary.size), msg_color(sum)]
      else
        msg = "Total consume: %s seconds.\n\n" % msg_color(sum)
        info msg
        feature_grp_hash = @bms.group_by { |item| item[:feature] }
        feature_grp_hash.each do |feature, value|
          t_ary = value.collect { |item| item[:consume] }
          sum = t_ary.inject(:+)
          msg = "\tFeature %s, %s steps total consume: %s seconds.\n\n" % [msg_color(feature), msg_color(t_ary.size), msg_color(sum)]
          info msg
        end
      end # in_feature?
    end # total

    def within(args)
      from, to = args.collect{ |arg| arg.to_f }
      from, to = to, from if to < from
      #grp_by = @bms.group_by { |item| in_feature? ? item[:step] : item[:feature] }
      if in_feature?
        grp_by_step = @bms.group_by { |item| item[:step] }
        step_mean_hash= grp_by_step.inject({}) do |h, item|
          key = item.shift
          consumings = item.flatten.collect { |bm| bm[:consume] }
          h[key] = consumings.inject(:+) / consumings.size
          h
        end
        results = step_mean_hash.select { |k, v| (v >= from ) && (v <= to) }
        feature = @bms.first[:feature]
        unless results.empty?
          info "In %s, Steps within %s .. %s" % [msg_color(feature), msg_color(from), msg_color(to)]
        end
        results.sort_by { |k, v| v }.each do |k, v|
          info "\t Step %s, it average take %s seconds" % [msg_color(k), msg_color(v, "red")]
        end
      else
        grp_by_feature = @bms.group_by { |item| item[:feature] }
        grp_by_feature.each do |feature, all_steps|
          grp_by_step = all_steps.group_by { |item| item[:step] }
          step_mean_hash= grp_by_step.inject({}) do |h, item|
            key = item.shift
            consumings = item.flatten.collect { |bm| bm[:consume] }
            h[key] = consumings.inject(:+) / consumings.size
            h
          end
          results = step_mean_hash.select { |k, v| (v >= from ) && (v <= to) }
          unless results.empty?
            info "In %s, Steps within %s .. %s" % [msg_color(feature), msg_color(from), msg_color(to)]
          end
          results.sort_by { |k, v| v }.each do |k, v|
            info "\t Step %s, it average take %s seconds" % [msg_color(k), msg_color(v, "red")]
          end
        end # grp_by_feature
      end # in_feature?
    end # within

    def less_or_more(value, lom = "less")
      value = value.to_f
      if in_feature?
        grp_by_step = @bms.group_by { |item| item[:step] }
        step_mean_hash= grp_by_step.inject({}) do |h, item|
          key = item.shift
          consumings = item.flatten.collect { |bm| bm[:consume] }
          h[key] = consumings.inject(:+) / consumings.size
          h
        end
        results = step_mean_hash.select { |k, v| v.send((lom=="less") ? :<= : :>=, value) }
        feature = @bms.first[:feature]
        unless results.empty?
          info "In %s, Steps %s than %s" % [msg_color(feature), msg_color(lom), msg_color(value)]
        end
        results.sort_by { |k, v| v }.each do |k, v|
          info "\t Step %s, it average take %s seconds" % [msg_color(k), msg_color(v, "red")]
        end
      else
        grp_by_feature = @bms.group_by { |item| item[:feature] }
        grp_by_feature.each do |feature, all_steps|
          grp_by_step = all_steps.group_by { |item| item[:step] }
          step_mean_hash= grp_by_step.inject({}) do |h, item|
            key = item.shift
            consumings = item.flatten.collect { |bm| bm[:consume] }
            h[key] = consumings.inject(:+) / consumings.size
            h
          end
          results = step_mean_hash.select { |k, v| v.send((lom=="less") ? :<= : :>=, value) }
          unless results.empty?
            info "In %s, Steps %s than %s" % [msg_color(feature), msg_color(lom), msg_color(value)]
          end
          results.sort_by { |k, v| v }.each do |k, v|
            info "\t Step %s, it average take %s seconds" % [msg_color(k), msg_color(v, "red")]
          end
        end
      end # in_feature?
    end # less_or_more

    def less(value)
      less_or_more(value, "less")
    end

    def more(value)
      less_or_more(value, "more")
    end

    def default_options
      { scope: :step, feature: :all }
    end

    def bm_validate!
      abort "please make sure that record log file exist!" unless File.exist? @log_file
      @bms ||= File.read(@log_file)
      @bms.strip!
      abort "record log file is empty!" if @bms.empty?
    end

    def parse_bms!
      bms = @bms.split("\n")
      bms.delete ""
      bms.compact!
      @bms = bms.inject([]) do |ary, item|
        tmp_ary = item.split(@config.delimiter)
        consume_time, step_name, file_colon_line = tmp_ary
        feature, line = file_colon_line.split(":")
        tmp_ary = { feature: feature, step: step_name, line: line, consume: consume_time.to_f }
        ary << tmp_ary if @options[:feature].is_a?(Symbol) or (@options[:feature] == feature)
        ary
      end
      abort msg_color("empty", "r") if @bms.empty?
    end

    def in_feature?
      !@options[:feature].is_a?(Symbol)
    end

    def msg_color(msg, color="green")
      color = (color == "green") ? 32 : 31
      "\033[4;1;#{color};40m#{msg}\033[0m"
    end

    def info(msg)
      puts msg
    end

  end
end
