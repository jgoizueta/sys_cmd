# SysCmd

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

Example:

    cmd = SysCmd.command 'ffmpeg' do
      option '-i', file: 'input video file.mkv'
      option '-vcodec', 'mjpeg'
      file 'output.mkv'
    end
    puts cmd.to_s # ffmpeg -i input\ video\ file.mkv -vcodec mjpeg output.mkv
    cmd.run
    if cmd.success?
      puts cmd.output
    end

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/[my-github-username]/sys_cmd/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
