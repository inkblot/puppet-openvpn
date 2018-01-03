notification :off

guard 'rake', :task => 'syntax' do
  watch(%r|^manifests\/(.+)\.pp$|)
end

guard 'rake', :task => 'lint' do
  watch(%r|^manifests\/(.+)\.pp$|)
end

guard 'rake', :task => 'spec' do
  watch(%r|^manifests\/(.+)\.pp$|)
  watch(%r|^spec\/classes\/(.+)\.rb$|)
  watch(%r|^spec\/defines\/(.+)\.rb$|)
end

