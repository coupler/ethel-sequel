guard 'test' do
  watch(%r{^lib/ethel/([^/]+/)*([^/]+)\.rb$}) do |m|
    "test/unit/#{m[1]}test_#{m[2]}.rb"
  end
  watch(%r{^test/unit/([^/]+/)*test_.+\.rb$})
  watch(%r{^test/integration/test_.+\.rb$})
  watch('test/helper.rb') { 'test' }
end
