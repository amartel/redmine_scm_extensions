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

module SCMExtensionsProjectMacro
  Redmine::WikiFormatting::Macros.register do
    desc "Display repository files. Examples:\n\n" +
      " !{{scm_show}} -- Show all repository folders/files\n" +
      " !{{scm_show(path)}} -- Show folders/files in a specific folder\n" +
      " !{{scm_show(path,revision)}} -- Idem but at a specific revision\n" +
      " !{{scm_show(path,revision,show_rev)}} -- Idem with column revision displayed\n" +
      " !{{scm_show(path,revision,show_rev,link_to_details)}} -- Idem with links to details (no direct download)\n"
    macro :scm_show do |obj, args|
      
      return "" if !User.current.allowed_to?(:browse_repository, @project)
      path = ""
      path = args[0].strip if args[0]
      @rev = nil
      @rev = args[1].strip if (args[1] && !args[1].empty?)
      @show_rev = nil
      @show_rev = !args[2].nil? && !args[2].empty?
      @link_details = nil
      @link_details = !args[3].nil? && !args[3].empty?
      #need @entries, @rev, @project
      @entries = @project.repository.entries(path, @rev)
      return "" if @entries.nil?

      o = ""
      o << render(:partial => 'scm_extensions/dir_list')

      return o
    end
  end
end
