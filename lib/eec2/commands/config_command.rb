require 'eec2/ec2_wrapper'
require 'eec2/sub_command'

class ConfigCommand < SubCommand
  def initialize(global_parser, global_options)
    @aws_dir    = "#{Dir.home}/.aws"
    @sub_parser = Trollop::Parser.new do
      long_banner = <<-EOS
        config -- Set your AWS credentials and/or region

        Command usage: #{'config [options]'.green}
      EOS

      banner long_banner.gsub(/^ {8}/, '')

      opt :region, 'AWS region (e.g. us-east-1, us-west-2)', type: String
      opt :key, 'Your AWS access key id', type: String
      opt :secret, 'Your AWS secret access key', type: String
    end

    super(global_parser, global_options)
  end

  def _perform(args)
    unless args.empty?
      sub_cmd_usage "ERROR: unknown argument #{args.join ' '}"
    end
    if @sub_options[:region].nil? && @sub_options[:key].nil? && @sub_options[:secret].nil?
      sub_cmd_usage 'ERROR: nothing to do. Neither region nor credentials were provided.'
    end
    if @sub_options[:key].nil? != @sub_options[:secret].nil?
      sub_cmd_usage 'ERROR: both key and secret must be specified.'
    end

    Dir.mkdir(@aws_dir, 0o700) unless Dir.exist? @aws_dir

    if @sub_options[:region]
      config_file = "#{@aws_dir}/config"

      $stderr.puts 'Setting region.'

      # In case the file exists as a symlink, delete it first.
      File.delete config_file if File.exist? config_file
      File.open(config_file, 'w') do |f|
        contents = <<-EOS
          [default]
          output = json
          region = #{@sub_options[:region]}
        EOS
        f.puts contents.gsub(/^ +/, '')
      end
      File.chmod 0o600, config_file
    end

    if @sub_options[:key]
      credentials_file = "#{@aws_dir}/credentials"

      $stderr.puts 'Setting credentials.'

      File.delete credentials_file if File.exist? credentials_file
      File.open(credentials_file, 'w') do |f|
        contents = <<-EOS
          [default]
          aws_access_key_id = #{@sub_options[:key]}
          aws_secret_access_key = #{@sub_options[:secret]}
        EOS
        f.puts contents.gsub(/^ +/, '')
      end
      File.chmod 0o600, credentials_file
    end

    puts 'eec2 successfully configured.'
  end
end
