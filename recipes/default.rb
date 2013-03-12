#
# Cookbook Name:: fileserver
# Recipe:: default
#
# Author:: Joshua Timberman <joshua@opscode.com>
# Copyright:: Copyright (c) 2012, Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

index_data = []
node.set['apache']['listen_ports'] = [80]

include_recipe "apache2"
# set attributes for and cache data_bag based ingredients
include_recipe 'ii-fileserver::ingredients'
directory node['fileserver']['docroot'] do
  owner node['apache']['user']
  mode 00755
  recursive true
end

# directory File.join(node['fileserver']['docroot'],'slides') do
#   owner node['apache']['user']
#   mode 00755
# end

# targets_listing_dir = File.join(node['fileserver']['docroot'],'targets')
# directory targets_listing_dir do
#   owner node['apache']['user']
#   mode 00755
# end

# target_list = []
# Dir.glob('/var/lib/lxc/target*').each do |target_dir| 
#   target_name = File.basename(target_dir)
#   target_list << target_name
#   link File.join(targets_listing_dir,target_name) do
#     to File.join(target_dir,'rootfs')
#     owner node['apache']['user']
#   end
# end

# workstation_list = []
# Dir.glob('/var/lib/lxc/workstation*').each do |workstation_dir| 
#   workstation_name = File.basename(workstation_dir)
#   workstation_list << workstation_name
# end

index_data << "<br /><a href=\"chef-repo.zip\">Chef Repository zip file</a>"

template File.join(node['fileserver']['docroot'], "index.html") do
  owner node['apache']['user']
  mode 00644
  variables({
      :index_data => index_data,
      #:workstation_list => workstation_list,
      #:target_list => target_list
    })
end


node['fileserver']['ingredients'].each do |data_bag,attrs|
  search(data_bag,"version:#{node['fileserver']['ingredients'][data_bag]['version']}").each do |ing|
    # cache file should already be created
    cache_file = File.join(Chef::Config[:file_cache_path], ing['filename'])
    target_file = File.join(node['fileserver']['docroot'], ing['filename'])

    archs = case ing['arch']
            when Array
              ''
            when /x86_64/
              ''
            else
              ing['arch']
            end
    ostext = ing['os'].map do |os,versions|
      if versions and ing['flavor']
        "#{os} #{ing['flavor']} #{versions.join(', ')}"
      elsif versions
        "#{os} #{versions.join(', ')}"
      else
        ''
      end
    end.join('; ')
    ostext = ostext.empty? ? '' : "for #{archs} #{ostext} "
    index_data << "<br /><a href=\"#{ing['filename']}\">#{ing['desc']} #{node['fileserver']['ingredients'][data_bag]['version']} #{ostext}</a>"
    # going to try symlinks vs file copies
    # we may run into issues later with file perms to reach the cache, but let's deal with it later
    # 'copy' file out of cache
    # ruby_block "copy file #{cache_file} to #{target_file}" do
    #   block do
    #     ::FileUtils.cp cache_file, target_file
    #   end
    #   if ::File.exist?(target_file)
    #     not_if do
    #       #::FileUtils.compare_file(cache_file, target_file)
    #       # cheap checking, should maybe look at time as well
    #       File.size(cache_file) == File.size(target_file)
    #     end
    #   end
    # end
    # make sure perms are good
    # file target_file do
    #   owner node['apache']['user']
    #   mode 00644
    #   #content open(cache_file).read
    #   #not_if {::File.exists? target_file }
    # end
    link target_file do
      to cache_file
      owner node['apache']['user']
    end
    if data_bag == 'chef' && ostext =~ /windows/
      link File.join(node['fileserver']['docroot'], 'chef-client.msi') do
        to cache_file
        owner node['apache']['user']
      end
    end
  end

end

node['fileserver']['vnc'].each do |os,remote_source|
  index_data << "<br /><a href=\"cotvnc.dmg\">VNC Client for #{os}</a>"
  filename = File.basename(remote_source['url'])
  cache_file = File.join(Chef::Config[:file_cache_path], filename)
  target_file = File.join(node['fileserver']['docroot'], filename)
  
  # Populate the cache
  # may already be cached to to ii-fileserver::cache-files
  Chef::Log.fatal remote_source
  rm = remote_file cache_file do
    source remote_source['url']
    checksum remote_source['checksum']
  end
  rm.run_action :create

  file target_file do
    content open(cache_file).read
    owner node['apache']['user']
    mode 00644
    not_if {::File.exists? target_file }
  end
end

# link "chef-full.deb" do
#   to node['fileserver']['chef_full']['debian_32']['filename']
# end if node['fileserver']['chef_full'].has_key?('debian_32')

cookbook_file File.join(node['fileserver']['docroot'], "chef-repo.zip") do
  source "chef-repo.zip"
  owner node['apache']['user']
  mode 00644
end

apache_site "000-default" do
  enable false
end

# the web_app definition creates a template + apache_site
# the reload for service[apache2] is :delayed
# we need it asap so we can retrieve files later
service 'apache2' do
  action :nothing
  subscribes :restart, "execute[a2ensite fileserver.conf]", :immediately
end

web_app "fileserver" do
  server_name "fileserver"
  server_aliases [node['fqdn'], "fileserver.#{node['domain']}"]
  docroot node['fileserver']['docroot']
  template "apache2.conf.erb"
  port "80"
end

