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
require 'sort_helper'

module SCMExtensionsProjectMacro
  Redmine::WikiFormatting::Macros.register do
    desc "Display repository files. Examples:\n\n" +
      " !{{scm_show}} -- Show all default repository folders/files\n" +
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
      @repository = @project.repository
      @entries = @repository.entries(path, @rev)
      return "" if @entries.nil?

      o = ""
      o << render(:partial => 'scm_extensions/dir_list')

      return o.html_safe
    end
  end

  Redmine::WikiFormatting::Macros.register do
    desc "Display repository files for a specific repository. Examples:\n\n" +
    " !{{scm_show2(repo_id)}} -- Show all folders/files\n" +
    " !{{scm_show2(repo_id,path)}} -- Show folders/files in a specific folder\n" +
    " !{{scm_show2(repo_id,path,revision)}} -- Idem but at a specific revision\n" +
    " !{{scm_show2(repo_id,path,revision,show_rev)}} -- Idem with column revision displayed\n" +
    " !{{scm_show2(repo_id,path,revision,show_rev,link_to_details)}} -- Idem with links to details (no direct download)\n"
    macro :scm_show2 do |obj, args|

      return "" if !User.current.allowed_to?(:browse_repository, @project)
      repository_id = nil
      repository_id = args[0].strip if args[0]
      path = ""
      path = args[1].strip if args[1]
      @rev = nil
      @rev = args[2].strip if (args[2] && !args[2].empty?)
      @show_rev = nil
      @show_rev = !args[3].nil? && !args[3].empty?
      @link_details = nil
      @link_details = !args[4].nil? && !args[4].empty?
      #need @entries, @rev, @project
      @repository = @project.repositories.find_by_identifier_param(repository_id)
      return "" if @repository.nil?
      @entries = @repository.entries(path, @rev)
      return "" if @entries.nil?

      o = ""
      o << render(:partial => 'scm_extensions/dir_list')

      return o.html_safe
    end
  end

  Redmine::WikiFormatting::Macros.register do
    desc "Display list of issues. Examples:\n\n" +
      " !{{issue_box(query_id)}} -- Show issues filtered by a specific public query\n"
    macro :issue_box do |obj, args|
      
      return "" if !User.current.allowed_to?(:view_issues, @project)
      return "" if !args[0]
      queryId = args[0].strip
      cond = "project_id IS NULL"
      cond << " OR project_id = #{@project.id}" if @project
      @query = Query.find(queryId, :conditions => cond)
      @query.project = @project

      @issues = @query.issues(:include => [:assigned_to, :tracker, :priority, :category, :fixed_version],
                                :order => "issues.id desc")
        
      return "" if @issues.nil?

      o = ""
      o << render(:partial => 'scm_extensions/issue_box')

      return o.html_safe
    end
  end
end
