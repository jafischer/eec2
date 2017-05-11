require 'eec2/ec2_wrapper'

# Base class for sub-commands. Each contains a parser for the sub-options, and a method to perform the actual command.
class SubCommand
  attr_accessor :sub_parser, :sub_options, :global_parser, :global_options, :ec2_wrapper

  def initialize(global_parser, global_options)
    @global_parser  = global_parser
    @global_options = global_options

    # This is just here to get rid of a "cannot find declaration for @sub_parser" warning in RubyMine,
    # since the @sub_parser is actually created by the derived class.
    # I like to get files to a warning-free state when I can, even if that sometimes involves trickery like this...
    @sub_parser     = @sub_parser

    @ec2_wrapper    = Ec2Wrapper.new(global_parser, global_options)

    @RED = $stdout.isatty ? "\e[1;40;31m" : ''
    @GREEN = $stdout.isatty ? "\e[1;40;32m" : ''
    @NC = $stdout.isatty ? "\e[0m" : ''
  end

  def perform(args)
    Trollop::with_standard_exception_handling @sub_parser do
      @sub_options = @sub_parser.parse args
    end

    # NOCATCH: don't wrap the call; want to see the callstack if an exception occurs.
    if ENV['NOCATCH']
      _perform args
    else
      begin
        _perform args
      rescue => ex
        $stderr.puts "#{@RED}ERROR: #{ex}#{@NC}"
        exit 1
      end
    end
  end

  # This is a pure virtual method
  def _perform(args)
  end

  def sub_cmd_usage(message)
    $stderr.puts "#{@RED}#{message}#{@NC}\n\n"
    @global_parser.educate $stderr
    $stderr.puts "\n"
    @sub_parser.educate $stderr
    exit 1
  end
end
