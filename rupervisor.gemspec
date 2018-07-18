Gem::Specification.new do |s|
  s.name        = 'rupervisor'
  s.version     = '0.1'
  s.executables << 'rp'
  s.date        = '2018-07-14'
  s.summary     = 'Runs things'
  s.description = "If at first you don't succeed, you're probably doomed"
  s.authors     = %w(axocomm)
  s.email       = 'axocomm@gmail.com'
  s.homepage    = 'https://github.com/axocomm/rupervisor'
  s.files       = Dir['lib/**/*.rb']
  s.license     = 'GPL-3.0'

  s.add_dependency 'thor', '~> 0.20'
  s.add_dependency 'colorize', '~> 0.8'
end
