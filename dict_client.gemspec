Gem::Specification.new do |s|
  s.name          = 'dict_client'
  s.version       = '0.0.1'
  s.homepage      = 'https://github.com/leikind/dict_client'
  s.date          = '2013-07-15'
  s.summary       = 'A simple client side DICT library and executable'
  s.description   = 'The Dictionary Server Protocol (DICT) is a TCP transaction based '  +
                  'query/response protocol that allows a client to access dictionary ' +
                  'definitions from a set of natural language dictionary databases. '  +
                  'See RFC 2229 for details. http://tools.ietf.org/html/rfc2229'
  s.authors       = ['Dave Pearson', 'Yuri Leikind']
  s.email         = 'yuri.leikind@gmail.com'
  s.files         = `git ls-files`.split($/)
  s.executables   = s.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})

end