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

directory node['fileserver']['docroot'] do
  owner node['apache']['user']
  mode 00755
  recursive true
end

directory File.join(node['fileserver']['docroot'],'slides') do
  owner node['apache']['user']
  mode 00755
end

targets_listing_dir = File.join(node['fileserver']['docroot'],'targets')
directory targets_listing_dir do
  owner node['apache']['user']
  mode 00755
end

target_list = []
Dir.glob('/var/lib/lxc/target*').each do |target_dir| 
  target_name = File.basename(target_dir)
  target_list << target_name
  link File.join(targets_listing_dir,target_name) do
    to File.join(target_dir,'rootfs')
    owner node['apache']['user']
  end
end

workstation_list = []
Dir.glob('/var/lib/lxc/workstation*').each do |workstation_dir| 
  workstation_name = File.basename(workstation_dir)
  workstation_list << workstation_name
end

index_data << "<br /><a href=\"chef-repo.zip\">Chef Repository zip file</a>"

template File.join(node['fileserver']['docroot'], "index.html") do
  owner node['apache']['user']
  mode 00644
  variables({
      :index_data => index_data,
      :workstation_list => workstation_list,
      :target_list => target_list
    })
end

node['fileserver']['sublime'].each do |os, data|

  index_data << "<br /><a href=\"#{data['filename']}\">Sublime for #{os.capitalize}</a>"

  remote_file File.join(node['fileserver']['docroot'], data['filename']) do
    source data['url']
    checksum data['checksum']
    owner node['apache']['user']
    mode 00644
  end

end

node['fileserver']['chef_full']['platforms'].each do |os, data|

  v = node['fileserver']['chef_full']['version']
  p = data['platform']
  pv = data['platform_version']
  m = data['machine']

  ext = data['platform'] =~ /ubuntu/ ? "deb" : "rpm"
  if data.has_key?("url")
    url = data['url']
  else
    url = "https://www.opscode.com/chef/download?v=#{v}&p=#{p}&pv=#{pv}&m=#{m}"
  end

  if data.has_key?("filename")
    filename = data['filename']
  else
    filename = "chef-full-#{v}.#{m}.#{ext}"
  end

  index_data << "<br /><a href=\"#{filename}\">Chef Full Stack for #{os.capitalize}</a>"

  remote_file File.join(node['fileserver']['docroot'], filename) do
    source url
    checksum data['checksum']
    owner node['apache']['user']
    mode 00644
  end

end

# index_data << "<br /><a href=\"cotvnc.dmg\">VNC Client for OSX</a>"

# remote_file File.join(node['fileserver']['docroot'], "cotvnc.dmg") do
#   source "http://hivelocity.dl.sourceforge.net/project/chicken/Chicken-2.2b2.dmg"
#   checksum "20e910b6cbf95c3e5dcf6fe8e120d5a0911f19099128981fb95119cee8d5fc6b"
#   owner node['apache']['user']
#   mode 00644
# end

index_data << "<br /><a href=\"tightvnc.msi\">VNC Client for Windows</a>"

remote_file File.join(node['fileserver']['docroot'], "tightvnc.msi") do
  source "http://www.tightvnc.com/download/2.5.2/tightvnc-2.5.2-setup-32bit.msi"
  checksum "622109d0414a63db49a9e293d2ef272b0adab14fa46852cb9189568746b306bb"
  owner node['apache']['user']
  mode 00644
end

index_data << "<br /><a href=\"Anatomy-of-Chef-Run-AuthN.pdf\">Anatomy of a Chef Run (PDF)</a>"

remote_file File.join(node['fileserver']['docroot'], "Anatomy-of-Chef-Run-AuthN.pdf") do
  source "https://opscode-chef-training.s3.amazonaws.com/Anatomy-of-Chef-Run-AuthN.pdf"
  checksum "7fc9c66d64d8aec02014dc930e4436cb6d945d24c75944d1efaf4e9edc623d3b"
  owner node['apache']['user']
  mode 00644
end

index_data << "<br /><a href=\"Chef-Workshop-CheatSheet.pdf\">Chef Workshop Cheat Sheet (PDF)</a>"

remote_file File.join(node['fileserver']['docroot'], "Chef-Workshop-CheatSheet.pdf") do
  source "https://opscode-chef-training.s3.amazonaws.com/Chef-Workshop-CheatSheet.pdf"
  checksum "4328cc2073a3a4133cb82649b6903729a8d3947bb1f866dc62845eeb986fa9f0"
  owner node['apache']['user']
  mode 00644
end

index_data << "<br /><a href=\"Chef101-Terminology.pdf\">Chef 101 Terminology (PDF)</a>"

remote_file File.join(node['fileserver']['docroot'], "Chef101-Terminology.pdf") do
  source "https://opscode-chef-training.s3.amazonaws.com/Chef101-Terminology.pdf"
  checksum "e396fffda73e19bd7ff7ad3affc1e8c0ea9b697a8f3d1ed19b090c0930f389f6"
  owner node['apache']['user']
  mode 00644
end

link "chef-full.deb" do
  to node['fileserver']['chef_full']['debian_32']['filename']
end if node['fileserver']['chef_full'].has_key?('debian_32')

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
