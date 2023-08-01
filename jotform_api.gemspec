Gem::Specification.new do |s|
  s.name               = "jotform_api"
  s.version            = "1.0.0"

  s.required_ruby_version = ">= 2.6"
  s.authors = ["Marcelo Miqueles"]
  s.date = %q{2023-08-01}
  s.description = %q{This is a gem to access the JotForm API.}
  s.email = %q{marcelo@paperco.de}
  s.files = ["Rakefile", "lib/jotform.rb", "bin/jotform"]
  s.test_files = ["test/test_jotform.rb"]
  s.homepage = %q{http://rubygems.org/gems/jotform_api}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.6.2}
  s.summary = %q{jotform!}

  s.license = "MIT"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end

