# SCM Extensions plugin for Redmine
# Copyright (C) 2010 Arnaud MARTEL
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
require 'redmine'
Dir::foreach(File.join(File.dirname(__FILE__), 'lib')) do |file|
  next unless /\.rb$/ =~ file
  require file
end

Redmine::Plugin.register :redmine_scm_extensions do
  name 'SCM extensions plugin'
  author 'Arnaud Martel'
  description 'plugin to allow write operations for subversion repositories and provide new wiki macro'
  version '0.2.0'
  requires_redmine :version_or_higher => '1.3.1'

  
  project_module :scm_extensions do
    permission :scm_write_access, {:scm_extensions => [:upload, :mkdir, :delete]}
  end

end