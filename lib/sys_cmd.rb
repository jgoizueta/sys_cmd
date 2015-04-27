require "sys_cmd/version"

require 'shellwords'
require 'open3'
require 'os'

module SysCmd

  # This class has methods to build a command to be executed by the system
  #
  # The target OS can be defined with the +:os+ option, which accepts
  # values +:unix+ and +:windows+, and which defaults to the host system's type.
  #
  # All the methods to define command arguments (option, file, etc.)
  # accept options +:only_on+, +:except_on+ to conditionally
  # include the element depending on what the target OS is for the command.
  #
  class Definition

    def initialize(command, options = {})
      @shell = Shell.new(options)
      @options = options.dup
      @options.merge!(@options.delete(@shell.type) || {})
      @command = ''
      @command << (@options[command] || command)
      @last_arg = :command
    end

    attr_reader :command, :shell

    def to_s
      command
    end

    # Add an option. If the option is nor prefixed by - or /
    # then the default system option switch will be used.
    #
    #     option 'x' # will produce -x or /x
    #     option '-x' # will always produce -x
    #
    # A value can be given as an option and will be space-separated from
    # the option name:
    #
    #     option '-x', value: 123 # -x 123
    #
    # To avoid spacing the value use the +:join_value+ option
    #
    #     option '-x', join_value: 123 # -x123
    #
    # And to use an equal sign as separator, use +:equal_value+
    #
    #     option '-x', equal_value: 123 # -x=123
    #
    # If the option value is a file name, use the analogous
    # +:file+, +:join_file+ or +:equal_file+ options:
    #
    #     option '-i', file: 'path/filename'
    #
    # Several of this options can be given simoultaneusly:
    #
    #     option '-d', join_value: 'x', equal_value: '1' # -dx=1
    #
    def option(option, *args)
      options = args.pop if args.last.is_a?(Hash)
      options ||= {}
      raise "Invalid number of arguments (0 or 1 expected)" if args.size > 1
      return unless @shell.applicable?(options)
      value = args.shift || options[:value]
      if /\A[a-z]/i =~ option
        option = @shell.option_switch + option
      else
        option = option.dup
      end
      option << ' ' << @shell.escape_value(value) if value
      option << @shell.escape_value(options[:join_value]) if options[:join_value]
      option << '=' << @shell.escape_value(options[:equal_value]) if options[:equal_value]
      if file = options[:file]
        file_sep = ' '
      elsif file = options[:join_file]
        file_sep = ''
      elsif file = options[:equal_file]
        file_sep = '='
      end
      if file
        option << file_sep << @shell.escape_filename(file)
      end
      @command << ' ' << option
      @last_arg = :option
    end

    # Add a filename to the command.
    #
    #     file 'path/output'
    #
    def file(filename, options = {})
      return unless @shell.applicable?(options)
      @command << ' ' << @shell.escape_filename(filename)
      @last_arg = :file
    end

    # Add a filename to the command, joinning it without a separator to
    # the previous option added.
    #
    #     option '-i'
    #     join_file 'path/output' # -ipath/output
    #
    def join_file(filename, options = {})
      return unless @shell.applicable?(options)
      raise "An option is required for join_file" unless @last_arg == :option
      @command << @shell.escape_filename(filename)
      @last_arg = :file
    end

    # Add a filename to the command, attaching it with an equal sign to
    # the previous option added.
    #
    #     option '-i'
    #     equal_file 'path/output' # -i=path/output
    #
    def equal_file(filename, options = {})
      return unless @shell.applicable?(options)
      raise "An option is required for equal_file" unless @last_arg == :option
      @command << '=' << @shell.escape_filename(filename)
      @last_arg = :file
    end

    # Add the value of an option (or a quoted argument)
    #
    #    option '-x'
    #    join_value 123  # -x 123
    #
    def value(value, options = {})
      return unless @shell.applicable?(options)
      @command << ' ' << @shell.escape_filename(value.to_s)
      @last_arg = :value
    end

    # Add the value of an option, joinning it without a separator to
    # the previous option added.
    #
    #    option '-x'
    #    join_value 123  # -x123
    #
    def join_value(value, options = {})
      return unless @shell.applicable?(options)
      raise "An option is required for join_value" unless @last_arg == :option
      @command << @shell.escape_value(value)
      @last_arg = :value
    end

    # Add the value of an option, attaching it with an equal sign to
    # the previous option added.
    #
    #    option '-x'
    #    equal_value 123  # -x=123
    #
    def equal_value(value, options = {})
      return unless @shell.applicable?(options)
      raise "An option is required for equal_value" unless @last_arg == :option
      @command << '=' << @shell.escape_value(value)
      @last_arg = :value
    end

    # Add an unquoted argument to the command.
    # This is not useful for commands executed directly, since the arguments
    # are note interpreted by a shell in that case.
    def argument(value, options = {})
      return unless @shell.applicable?(options)
      @command << ' ' << value.to_s
      @last_arg = :argument
    end

  end

  # An executable system command
  class Command
    def initialize(command, options = {})
      if command.respond_to?(:shell)
        @command = command.command
        @shell = command.shell
      else
        @command = command
        @shell = Shell.new(options)
      end
      @output = nil
      @status = nil
      @error_output = nil
      @error = nil
    end

    attr_reader :command, :output, :status, :error_output, :error

    # Execute the command.
    #
    # By default the command is executed by a shell. In this case,
    # unquoted arguments are interpreted by the shell, e.g.
    #
    #   SysCmd.command('echo $BASH').run # /bin/bash
    #
    # When the +:direct+ option is set to true, no shell is used and
    # the command is directly executed; in this case unquoted arguments
    # are not interpreted:
    #
    #   SysCmd.command('echo $BASH').run # $BASH
    #
    # The exit status of the command is retained in the +status+ attribute
    # (and its numeric value in the +status_value+ attribute).
    #
    # The standard output of the command is captured and retained in the
    # +output+ attribute.
    #
    # By default, the standar error output of the command is not
    # captured, so it will be shown on the console unless redirected.
    #
    # Standard error can be captured and interleaved with the standard
    # output passing the option
    #
    #     error_output: :mix
    #
    # Error output can be captured and keep separate inthe +error_output+
    # attribute with this option:
    #
    #     error_output: :separate
    #
    # The value returned is by defaut, like in Kernel#system,
    # true if the command gives zero exit status, false for non zero exit status,
    # and nil if command execution fails.
    #
    # The +:return+ option can be used to make this method return other
    # attribute of the executed command.
    #
    def run(options = {})
      @output = @status = @error_output = @error = nil
      if options[:direct]
        command = @shell.split(@command)
      else
        command = [@command]
      end
      begin
        case options[:error_output]
        when :mix # mix stderr with stdout
          @output, @status = Open3.capture2e(*command)
        when :separate
          @output, @error_output, @status = Open3.capture3(*command)
        else # :console (do not capture stderr output)
          @output, @status = Open3.capture2(*command)
        end
      rescue => error
        @error = error.dup
      end
      case options[:return]
      when :status
        @status
      when :status_value
        status_value
      when :output
        @output
      when :error_output
        @error_output
      else
        @error ? nil : @status.success? ? true : false
      end
    end

    def status_value
      @status && @status.exitstatus
    end

    # did the command execution caused an exception?
    def error?
      !@error.nil?
    end

    # did the command execute without error and returned a success status?
    def success?
      !error? && @status.success?
    end

    def to_s
      command
    end

  end

  # Build a command.
  #
  # See the Definition class.
  #
  def self.command(command, options = {}, &block)
    definition = Definition.new(command, options)
    if block
      if block.arity == 1
        block.call definition
      else
        definition.instance_eval &block
      end
    end
    Command.new definition
  end

  # Build and run a command
  def self.run(command, options = {}, &block)
    command(command, options, &block).run
  end

  # Get the type of OS of the host.
  def self.local_os_type
    if OS.windows?
      :windows
    else
      :unix
    end
  end

  OS_TYPE_SYNONIMS = {
    unix: :unix,
    windows: :windows,
    bash: :unix,
    linux: :unix,
    osx: :unix,
    cmd: :windows
  }

  def self.os_type(options = {})
    options[:os] || local_os_type
  end

  def self.escape(text, options = {})
    case os_type(options)
    when :windows
      '"' + text.gsub('"', '""') + '"'
    else
      Shellwords.shellescape(text)
    end
  end

  def self.split(text, options = {})
    case os_type(options)
    when :windows
      words = []
      field = ''
      line.scan(/\G\s*(?>([^\s\^\'\"]+)|'([^\']*)'|"((?:[^\"\^]|\\.)*)"|(\^.?)|(\S))(\s|\z)?/m) do
        |word, sq, dq, esc, garbage, sep|
        raise ArgumentError, "Unmatched double quote: #{line.inspect}" if garbage
        field << (word || sq || (dq || esc).gsub(/\^(.)/, '\\1'))
        if sep
          words << field
          field = ''
        end
      end
      words
    else
      Shellwords.shellsplit(text)
    end
  end

  def self.line_separator(options = {})
    case os_type(options)
    when :windows
      '^\n'
    else
      '\\\n'
    end
  end

  def self.option_switch(options = {})
    case os_type(options)
    when :windows
      '/'
    else
      '-'
    end
  end

  class Shell

    def initialize(options = {})
      @type = SysCmd.os_type(options)
    end

    attr_reader :type

    def escape(text)
      SysCmd.escape(text, os: @type)
    end

    def split(text)
      SysCmd.split(text, os: @type)
    end

    def escape_filename(name)
      escape name
    end

    def escape_value(value)
      escape value.to_s
    end

    def line_separator
      SysCmd.line_separator(os: @type)
    end

    def option_switch
      SysCmd.option_switch(os: @type)
    end

    def applicable?(options = {})
      applicable = true
      only_on = Array(options[:only_on])
      unless only_on.empty?
        applicable = false unless only_on.include?(@type)
      end
      except_on = Array(options[:except_on])
      unless except_on.empty?
        applicable = false if except_on.include?(@type)
      end
      applicable
    end

  end

  # Execute a block of code only on some systems
  #
  #    cmd = nil
  #    SysCmd.only_on :unix do
  #      cmd = CmdSys.command('ls')
  #    end
  #    SysCmd.only_on :windows do
  #      cmd = CmdSys.command('dir')
  #    end
  #    cmd.run
  #    files = cmd.output
  #
  def self.only_on(*os_types)
    return if os_types.empty?
    yield if Shell.new.applicable?(only_on: os_types)
  end

  # Execute a block of code except on some system(s)
  def self.except_on(*os_types)
    yield if Shell.new.applicable?(except_on: os_types)
  end

  # Execute a block of code if the options +:only_on+,
  # +:except_on+ are satisfied in the host system.
  def self.execute(options = {})
    yield if Shell.new.applicable?(options)
  end

end
