cc = search('chef',"*:*")
node.normal['chef_client']['version']=cc.map{|v| v['version']}.flatten.uniq.sort.last

search('chef',"version:#{node['chef_client']['version']}").each do |c|
  cache_file = File.join(Chef::Config[:file_cache_path], c['filename'])
  rm = remote_file cache_file do
    source c['source']
    checksum c['checksum']
  end
  rm.run_action :create
end


node['fileserver']['sublime'].each do |os, data|
  cache_file = File.join(Chef::Config[:file_cache_path], data['filename'])
  # Populate the cache
  rm = remote_file cache_file do
    source data['url']
    checksum data['checksum']
  end
  rm.run_action :create
end

node['fileserver']['vnc'].each do |os,remote_source|
  filename = File.basename(remote_source['url'])
  cache_file = File.join(Chef::Config[:file_cache_path], filename)

  # Populate the cache
  rm = remote_file cache_file do
    source remote_source['url']
    checksum remote_source['checksum']
  end
  rm.run_action :create
end
