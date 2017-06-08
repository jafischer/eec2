gem uninstall --all --ignore-dependencies --executables eec2
Remove-Item *.gem
gem build eec2.gemspec
gem install *.gem
