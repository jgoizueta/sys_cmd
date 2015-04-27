require 'minitest_helper'

class TestSysCmd < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::SysCmd::VERSION
  end

  def test_command_generation
    cmd = SysCmd.command 'ps2pdf', os: :unix do
      file 'input_file'
      file 'output file'
    end
    assert_equal 'ps2pdf input_file output\\ file', cmd.to_s

    cmd = SysCmd.command 'ps2pdf', os: :windows do
      file 'input_file'
      file 'output file'
    end
    assert_equal 'ps2pdf "input_file" "output file"', cmd.to_s

  end

  def test_block_with_argument
    outer_self = self.object_id
    inner_self = nil
    cmd = SysCmd.command 'ps2pdf', os: :unix do |cmd|
      inner_self = self.object_id
      cmd.file 'input_file'
      cmd.file 'output file'
    end
    assert_equal 'ps2pdf input_file output\\ file', cmd.to_s
    assert_equal outer_self, inner_self
  end

  def test_command_replacement
    cmd = SysCmd.command 'gs', os: :unix, 'gs' => '/usr/local/bin/gs' do
      option '-q'
    end
    assert_equal '/usr/local/bin/gs -q', cmd.to_s
  end

  def test_os_command_replacement
    cmd = SysCmd.command 'gs', os: :unix, windows: { 'gs' => 'gswin32c' } do
      option '-q'
    end
    assert_equal 'gs -q', cmd.to_s

    cmd = SysCmd.command 'gs', os: :windows, windows: { 'gs' => 'gswin32c' } do
      option '-q'
    end
    assert_equal 'gswin32c -q', cmd.to_s
  end

  def test_os_arguments
    cmd = SysCmd.command 'test', os: :unix do
      option '-a'
      option '-b', only_on: :unix
      option '-c', only_on: :windows
      option '-d', except_on: :unix
      option '-e', except_on: :windows
    end
    assert_equal 'test -a -b -e', cmd.to_s

    cmd = SysCmd.command 'test', os: :windows do
      option '-a'
      option '-b', only_on: :unix
      option '-c', only_on: :windows
      option '-d', except_on: :unix
      option '-e', except_on: :windows
    end
    assert_equal 'test -a -c -d', cmd.to_s
  end

  def test_os_blocks
    OS.stub :windows?, true do
      executed = false
      SysCmd.only_on(:windows) do
        executed = true
      end
      assert executed

      executed = false
      SysCmd.execute(only_on: :windows) do
        executed = true
      end
      assert executed

      executed = false
      SysCmd.except_on(:unix) do
        executed = true
      end
      assert executed

      executed = false
      SysCmd.execute(except_on: :unix) do
        executed = true
      end
      assert executed

      executed = false
      SysCmd.only_on(:unix) do
        executed = true
      end
      refute executed

      executed = false
      SysCmd.execute(only_on: :unix) do
        executed = true
      end
      refute executed

      executed = false
      SysCmd.except_on(:windows) do
        executed = true
      end
      refute executed

      executed = false
      SysCmd.execute(except_on: :windows) do
        executed = true
      end
      refute executed
    end

    OS.stub :windows?, false do
      executed = false
      SysCmd.only_on(:windows) do
        executed = true
      end
      refute executed

      executed = false
      SysCmd.execute(only_on: :windows) do
        executed = true
      end
      refute executed

      executed = false
      SysCmd.except_on(:unix) do
        executed = true
      end
      refute executed

      executed = false
      SysCmd.execute(except_on: :unix) do
        executed = true
      end
      refute executed

      executed = false
      SysCmd.only_on(:unix) do
        executed = true
      end
      assert executed

      executed = false
      SysCmd.execute(only_on: :unix) do
        executed = true
      end
      assert executed

      executed = false
      SysCmd.except_on(:windows) do
        executed = true
      end
      assert executed

      executed = false
      SysCmd.execute(except_on: :windows) do
        executed = true
      end
      assert executed

    end
  end

  def test_commmand_execution
    path_value = ENV['PATH']
    if OS.windows?
      path_name = '%PATH%'
    else
      path_name = '$PATH'
    end

    cmd = SysCmd.command 'echo' do
      argument path_name
    end
    cmd.run
    assert_equal path_value, cmd.output.strip
    cmd.run direct: true
    assert_equal path_name, cmd.output.strip

    cmd = SysCmd.command 'echo' do
      value path_name
    end
    cmd.run
    assert_equal path_name, cmd.output.strip
    cmd.run direct: true
    assert_equal path_name, cmd.output.strip
  end
end
