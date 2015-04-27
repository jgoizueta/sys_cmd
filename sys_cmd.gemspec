# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sys_cmd/version'

Gem::Specification.new do |spec|
  spec.name          = "sys_cmd"
  spec.version       = SysCmd::VERSION
  spec.authors       = ["Javier Goizueta"]
  spec.email         = ["jgoizueta@gmail.com"]

  spec.summary       = %q{Execute shell commands.}
  spec.description   = %q{Define and execute shell commands on Unix-like & Windows systems.}
  spec.homepage      = "https://github.com/jgoizueta/sys_cmd"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "os", "~> 0.9.6"

  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.4"

  spec.required_ruby_version = '>= 1.9.3'
end
