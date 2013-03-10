node['fileserver']['ingredients'].each do |data_bag,attrs|
  # getting all the the artifacts may be expensive
  # only retrieve if it hasn't been set in a role
  Chef::Log.fatal node['fileserver']['ingredients'][data_bag]
  if not node['fileserver']['ingredients'][data_bag]['version']
    all_artifacts = search(data_bag,"*:*")
    node.default['fileserver']['ingredients'][data_bag]['version']=all_artifacts.map{|v|
      v['version']}.flatten.uniq.sort.last
  end
  search(data_bag,"version:#{node['fileserver']['ingredients'][data_bag]['version']}").each do |ing|

    cache_file = File.join(Chef::Config[:file_cache_path], ing['filename'])
    # Populate the cache and checksums
    chksumf="#{cache_file}.checksum"
    rf = remote_file cache_file do
      source ing['source']
      checksum ing['checksum']
      not_if do
        (::File.exists? chksumf) && (open(chksumf).read == ing['checksum'])
      end
    end
    rf.run_action :create

    cs=file "#{cache_file}.checksum" do
      content ing['checksum']
    end
    cs.run_action :create
  end
end
