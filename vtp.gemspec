Gem::Specification.new do |s|
  s.name              = 'vtp'
  s.version           = '0.0.0'
  s.licenses          = %w( Apache-2.0 )
  s.platform          = Gem::Platform::RUBY
  s.authors           = [ 'Saku Ytti' ]
  s.email             = %w( saku@ytti.fi )
  s.homepage          = 'http://github.com/ytti/ruby-vtp'
  s.summary           = 'Ruby VTP'
  s.description       = 'Ruby listener for Cisco VTP'
  s.rubyforge_project = s.name
  s.files             = `git ls-files`.split("\n")
  s.executables       = %w( vtpd )
  s.require_path      = 'lib'

  s.required_ruby_version =            '>= 1.9.3'
  s.add_runtime_dependency 'slop',     '~> 3.5'
  s.add_runtime_dependency 'ffi-pcap', '~> 0.2'
end
