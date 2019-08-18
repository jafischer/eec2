Gem::Specification.new do |s|
  s.name        = 'eec2'
  s.version     = '2.2.3'
  # s.date        = Date.today.to_s
  s.summary     = 'Enhanced EC2 commands'
  s.description = 'A set of convenient commands for working with EC2 instances'
  s.authors     = ['Jonathan Fischer']
  s.email       = 'eec2gem@gmail.com'
  s.files       = %w(
                  bin/eec2
                  lib/eec2.rb
                  lib/eec2/ec2_wrapper.rb
                  lib/eec2/string_colorize.rb
                  lib/eec2/global_command_wrapper.rb
                  lib/eec2/sub_command.rb
                  lib/eec2/commands/config_command.rb
                  lib/eec2/commands/create_command.rb
                  lib/eec2/commands/delete_command.rb
                  lib/eec2/commands/ip_command.rb
                  lib/eec2/commands/list_command.rb
                  lib/eec2/commands/ren_command.rb
                  lib/eec2/commands/scp_command.rb
                  lib/eec2/commands/ssh_command.rb
                  lib/eec2/commands/start_command.rb
                  lib/eec2/commands/stop_command.rb
                  lib/eec2/commands/tag_command.rb
                  )
  s.executables << 'eec2'
  s.homepage = 'https://github.com/jafischer/eec2'
  s.license  = 'MIT'

  s.add_dependency 'optimist', ['~> 3.0']
  s.add_dependency 'aws-sdk', ['~> 2.3']
  s.add_dependency 'concurrent-ruby', ['~> 1.0']
  s.add_dependency 'os', ['~> 1.0']
end
