require 'eec2/ec2_wrapper'

# Base class for sub-commands. Each contains a parser for the sub-options, and a method to perform the actual command.
class SubCommand
  attr_accessor :sub_parser, :sub_options, :global_parser, :global_options, :ec2_wrapper

  def initialize(global_parser, global_options)
    @global_parser  = global_parser
    @global_options = global_options

    @ec2_wrapper = Ec2Wrapper.new(global_parser, global_options)
  end

  def perform(args)
    Trollop::with_standard_exception_handling @sub_parser do
      @sub_options = @sub_parser.parse args
    end

    begin
      _perform args
    rescue => ex
      $stderr.puts "ERROR: #{ex}"
    end
  end

  def _perform(args)

  end

  def sub_cmd_usage(message)
    $stderr.puts "#{message}\n\n"
    @global_parser.educate $stderr
    $stderr.puts "\n"
    @sub_parser.educate $stderr
    exit 1
  end
end
