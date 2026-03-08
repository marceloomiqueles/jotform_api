require 'test/unit'
require 'tmpdir'

class PackagingTest < Test::Unit::TestCase
  def test_gem_build_succeeds_and_produces_expected_artifact
    spec = Gem::Specification.load('jotform_api.gemspec')
    expected_gem_name = "jotform_api-#{spec.version}.gem"

    Dir.mktmpdir('jotform-gem-build') do |dir|
      output = `gem build jotform_api.gemspec --output #{File.join(dir, expected_gem_name)} 2>&1`
      assert_equal(0, $?.exitstatus, "gem build failed:\n#{output}")

      artifact = File.join(dir, expected_gem_name)
      assert(File.exist?(artifact), "Expected built gem artifact at #{artifact}")
      assert(File.size(artifact) > 0, 'Built gem artifact is empty')
    end
  end
end
