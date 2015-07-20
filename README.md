# SysCmd

[![Gem Version](https://badge.fury.io/rb/sys_cmd.svg)](http://badge.fury.io/rb/sys_cmd)
[![Build Status](https://travis-ci.org/jgoizueta/sys_cmd.svg)](https://travis-ci.org/jgoizueta/sys_cmd)

SysCmd is a DSL to define commands to be executed by the system.

The command arguments will we escaped properly for bash or
Windows cmd.exe.

The commands can be executed capturing its exit status and output.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sys_cmd'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sys_cmd

## Usage

A command can be defined with a simple DSL (passing a block that defines
the command arguments to the SysCmd.command method):

```ruby
cmd = SysCmd.command 'ffmpeg' do
  option '-i', file: 'input video file.mkv'
  option '-vcodec', 'mjpeg'
  file 'output.mkv'
end
```

The block is executed with +instance_eval+ inside the command definition
(an instance of SysCmd::Definicion), so +self+ and instance variables refer
to the definition. If this is not desirable an argument can be passed to
the block with the +Definition+ object:

```ruby
cmd = SysCmd.command 'ffmpeg' do |cmd|
  cmd.option '-i', file: 'input video file.mkv'
  cmd.option '-vcodec', 'mjpeg'
  cmd.file 'output.mkv'
end
```

The command can be converted to a String which represents it with
arguments quoted for the target OS/shell (here we assume a UN*X system)

```ruby
puts cmd.to_s # ffmpeg -i input\ video\ file.mkv -vcodec mjpeg output.mkv
```

A command can be generated for a system different from the current host
by passing the +:os+ option:

```ruby
wcmd = SysCmd.command 'ffmpeg', os: :windows do |cmd|
  cmd.option '-i', file: 'input video file.mkv'
  cmd.option '-vcodec', 'mjpeg'
  cmd.file 'output.mkv'
end
puts cmd.to_s # ffmpeg -i "input video file.mkv" -vcodec mjpeg "output.mkv"
```

Currently only +:windows+ (for CMD.EXE syntax) and +:unix+ (for bash syntax) are
accepted for the +:os+ parameter. +:unix+ represent any UN*X-like system
(including linux, OSX, etc.)

A Command can also be executed:

```ruby
cmd.run
if cmd.success?
  puts cmd.output
end
```

By default execution is done by launching a shell to interpret the command.
Unquoted arguments will be interpreted by the shell in that case:

```ruby
cmd = SysCmd.command 'echo' do
  argument '$BASH'
end
cmd.run
puts cmd.output # /bin/bash
```

Shell execution can be avoided by passing the +:direct+ option with value
+true+ to the +run+ method. In that case the command is executed directly,
and no shell interpretation takes place, so:

```ruby
cmd.run direct: true
puts cmd.output # $BASH
```

If the command options include
an option with the name of the command being defined it is used to
replace the command name. This can be handy to pass user configuration
to define the location/name of commands in a particular system:

```ruby
options = {
  curl: "/usr/local/bin/curl"
}
cmd = SysCmd.command 'curl', options do
  file 'http://jsonip.com'
end
puts cmd.to_s # /usr/local/bin/curl http://jsonip.com
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/[my-github-username]/sys_cmd/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
