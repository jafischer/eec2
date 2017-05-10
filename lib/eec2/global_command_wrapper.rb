# Trollop: a command-line argument parser that I prefer over 'optparse'.
# See: https://github.com/ManageIq/trollop and http://trollop.rubyforge.org/
require 'trollop'

# Our modules:
require 'eec2/create_command'
require 'eec2/delete_command'
require 'eec2/list_command'
require 'eec2/ren_command'
require 'eec2/scp_command'
require 'eec2/ssh_command'
require 'eec2/start_command'
require 'eec2/stop_command'
require 'eec2/ip_command'


class GlobalCommandWrapper
  def initialize(args)
    @args             = args
    @RED              = $stdout.isatty ? "\e[1;40;31m" : ''
    @GREEN            = $stdout.isatty ? "\e[1;40;32m" : ''
    @NC               = $stdout.isatty ? "\e[0m" : ''

    # noinspection RubyStringKeysInHashInspection
    @sub_commands     = {
      'create' => lambda { |global_parser, global_options| CreateCommand.new(global_parser, global_options) },
      'delete' => lambda { |global_parser, global_options| DeleteCommand.new(global_parser, global_options) },
      'ls'     => lambda { |global_parser, global_options| ListCommand.new(global_parser, global_options) },
      'ren'    => lambda { |global_parser, global_options| RenCommand.new(global_parser, global_options) },
      'scp'    => lambda { |global_parser, global_options| ScpCommand.new(global_parser, global_options) },
      'ssh'    => lambda { |global_parser, global_options| SshCommand.new(global_parser, global_options) },
      'start'  => lambda { |global_parser, global_options| StartCommand.new(global_parser, global_options) },
      'stop'   => lambda { |global_parser, global_options| StopCommand.new(global_parser, global_options) },
      'ip-add' => lambda { |global_parser, global_options| IpCommand.new(global_parser, global_options, 'add') },
      'ip-rm'  => lambda { |global_parser, global_options| IpCommand.new(global_parser, global_options, 'rm') },
      'ip-ls'  => lambda { |global_parser, global_options| IpCommand.new(global_parser, global_options, 'ls') },
    }

    # Directly placing #{@sub_commands.keys} in the string doesn't work, because (I think) @xxx is scoped to
    # the Parser object in the do block below. So we need to create a variable in this outer scope.
    sub_command_names = @sub_commands.keys

    @global_parser = Trollop::Parser.new do
      long_banner = <<-EOS
        eec2 -- Enhanced EC2 commands.

        Usage: #{File.basename __FILE__} [global options] COMMAND [command options] [COMMAND ARGUMENTS]
        Valid commands:
            #{sub_command_names.join ' '}

        Note: Help for each command can be displayed by entering -h after the command name.
        Global options:
      EOS

      banner long_banner.gsub /^ {8}/, ''

      opt :region, 'Specify an AWS region (e.g. us-east-2, us-west-1)', type: String, short: '-r'
      opt :key, 'AWS access key id', type: String, short: '-k'
      opt :secret, 'AWS secret access key', type: String, short: '-s'
      opt :verbose, 'Verbose output', default: false, short: '-v'

      stop_on sub_command_names
    end

    @global_options = Trollop::with_standard_exception_handling @global_parser do
      @global_parser.parse @args
    end

    global_usage "ERROR: Both --key and --secret must be specified together.\n\n" if @global_options[:key].nil? != @global_options[:secret].nil?
  end

  def global_usage(message)
    $stderr.puts "#{@RED}#{message}#{@NC}"
    @global_parser.educate $stderr
    exit 1
  end

  def run_command
    global_usage "No command specified.\n\n" if @args.count < 1

    command = @args.shift

    # Is there a handler for this command?
    global_usage "Unknown command #{command}.\n\n" unless @sub_commands.include? command

    sub_command = @sub_commands[command].call @global_parser, @global_options

    sub_command.perform @args
  end
end