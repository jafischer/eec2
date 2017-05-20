# Trollop: a command-line argument parser that I prefer over 'optparse'.
# See: https://github.com/ManageIq/trollop and http://trollop.rubyforge.org/
require 'trollop'

# Our modules:
require 'eec2/string_colorize'
require 'eec2/commands/config_command'
require 'eec2/commands/create_command'
require 'eec2/commands/delete_command'
require 'eec2/commands/list_command'
require 'eec2/commands/ren_command'
require 'eec2/commands/scp_command'
require 'eec2/commands/ssh_command'
require 'eec2/commands/start_command'
require 'eec2/commands/stop_command'
require 'eec2/commands/ip_command'
require 'eec2/commands/tag_command'


class GlobalCommandWrapper
  def initialize(args)
    @args             = args

    # noinspection RubyStringKeysInHashInspection
    @sub_commands     = {
      'create' => lambda { |global_parser, global_options| CreateCommand.new(global_parser, global_options) },
      'config' => lambda { |global_parser, global_options| ConfigCommand.new(global_parser, global_options) },
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
      'tag'    => lambda { |global_parser, global_options| TagCommand.new(global_parser, global_options) },
    }

    # Directly placing #{@sub_commands.keys} in the string doesn't work, because (I think) @xxx is scoped to
    # the Parser object in the do block below. So we need to create a variable in this outer scope.
    sub_command_names = @sub_commands.keys

    @global_parser = Trollop::Parser.new do
      long_banner = <<-EOS
        eec2 -- Enhanced EC2 commands.

        Usage: eec2 [global options] COMMAND [command options] [command arguments]
        Valid commands:
            #{sub_command_names.sort.join "\n    "}
        Note: Help for each command can be displayed by specifying 'help COMMAND' or 'COMMAND -h'

        Global options:
      EOS

      banner long_banner.gsub(/^ {8}/, '')

      opt :region, 'Override the currently configured region', type: String, short: '-r'

      stop_on sub_command_names
    end

    @global_options = Trollop::with_standard_exception_handling @global_parser do
      @global_parser.parse @args
    end
  end

  def global_usage(message)
    $stderr.puts message.red.bold
    @global_parser.educate $stderr
    exit 1
  end

  def run_command
    global_usage "No command specified.\n" if @args.count < 1

    command = @args.shift

    if command == 'help'
      global_usage "Help: no command specified.\n" if @args.count < 1
      command = @args.shift
      @args = ['--help']
    end

    # Is there a handler for this command?
    global_usage "Unknown command #{command}.\n\n" unless @sub_commands.include? command

    begin
      sub_command = @sub_commands[command].call @global_parser, @global_options

    rescue Aws::Errors::MissingRegionError, Aws::Errors::MissingCredentialsError
      message = <<-EOS
        It looks like this is the first time you've run this script.
        As a one-time configuration step, please use the 'config' command to setup eec2.
        (see below for help).

        Note: if you have not yet created your AWS access key id and secret access key,
        you can do so here: https://console.aws.amazon.com/iam/home

      EOS
      $stderr.puts message.brown
      @global_parser.educate $stderr
      exit 1
    end

    sub_command.perform @args
  end
end
