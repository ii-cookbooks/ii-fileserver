default['fileserver']['docroot'] = "/srv/mirror/fileserver"
default['fileserver']['chef_full'] = {}
default['fileserver']["vnc"] = {
  'osx' => {
    'checksum' => '20e910b6cbf95c3e5dcf6fe8e120d5a0911f19099128981fb95119cee8d5fc6b',
    'url' => 'http://hivelocity.dl.sourceforge.net/project/chicken/Chicken-2.2b2.dmg'
  },
  'windows' => {
    'checksum' => '622109d0414a63db49a9e293d2ef272b0adab14fa46852cb9189568746b306bb',
    'url' => 'http://www.tightvnc.com/download/2.5.2/tightvnc-2.5.2-setup-32bit.msi'
  }
}
default['fileserver']['ingredients']['ubuntu']['desc']='Ubuntu ISO'
default['fileserver']['ingredients']['windows']['desc']='Windows ISO'
default['fileserver']['ingredients']['virtualbox']['desc']='Virtualbox'
default['fileserver']['ingredients']['chef']['desc']='Chef Client'
default['fileserver']['ingredients']['chef_server']['desc']='Chef Server'
default['fileserver']['ingredients']['vagrant']['desc']='Vagrant'
default['fileserver']['ingredients']['emacs']['desc']='Emacs'
default['fileserver']['ingredients']['vim']['desc']='Vim'
default['fileserver']['ingredients']['sublimetext']['desc']='Sublime Text'
default['fileserver']['ingredients']['git']['desc']='Git'

# mac versions of git are usually newer, pin at most recent release of both
default['fileserver']['ingredients']['git']['version']='1.8.1.2'
# I'm not ready for newer versions of Ubuntu... yet
default['fileserver']['ingredients']['ubuntu']['version']='12.04.2'
# If I want to list multiple version of windows, this could get interesting
# Let's focus on 2008r2 for now
default['fileserver']['ingredients']['windows']['version']='7601'

