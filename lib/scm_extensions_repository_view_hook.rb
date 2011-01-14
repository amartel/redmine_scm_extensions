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
class ScmExtensionsRepositoryViewHook < Redmine::Hook::ViewListener
  def view_repositories_show_contextual(context = { })
    @project = context[:project]
    @path = context[:controller].instance_variable_get("@path")
    @revision = context[:controller].instance_variable_get("@rev")
    output = ""
    return output if (@revision && !@revision.empty? && @revision != "HEAD"  && @project.repository.is_a?(Repository::Subversion))
    return output if !(User.current.allowed_to?(:scm_write_access, @project) && User.current.allowed_to?(:commit_access, @project))
    entry = @project.repository.entry(@path)
    if entry.is_dir?
      output << link_to(l(:label_scm_extensions_upload), {:controller => 'scm_extensions', :action => 'upload', :id => @project, :path => @path, :only_path => true}, :class => 'icon icon-add') if @project.repository.scm.respond_to?('scm_extensions_upload')
      output << "&nbsp;&nbsp;"
      output << link_to(l(:label_scm_extensions_new_folder), {:controller => 'scm_extensions', :action => 'mkdir', :id => @project, :path => @path, :only_path => true}, :class => 'icon icon-add') if @project.repository.scm.respond_to?('scm_extensions_mkdir')
      output << "&nbsp;&nbsp;"
      output << link_to(l(:label_scm_extensions_delete_folder), {:controller => 'scm_extensions', :action => 'delete', :id => @project, :path => @path, :only_path => true},  :class => 'icon icon-del', :confirm => l(:text_are_you_sure)) if @project.repository.scm.respond_to?('scm_extensions_delete')
    else
      output << link_to(l(:label_scm_extensions_delete_file), {:controller => 'scm_extensions', :action => 'delete', :id => @project, :path => @path, :only_path => true},  :class => 'icon icon-del', :confirm => l(:text_are_you_sure)) if @project.repository.scm.respond_to?('scm_extensions_delete')
    end
    if User.current.allowed_to?(:synapse_access, @project)
      output << "&nbsp;<span style='float: right;'>"
      options={}
      options[:target]='_blank'
      begin
        if @project.repository.is_a?(Repository::Filesystem)
          rootdir = @project.repository.url
          mountdir = rootdir.sub(/\/files$/, '')
          repo_size = `df -h | grep #{mountdir} | awk '{print "used: " $2 " - free: " $3}'`
          output << repo_size + "&nbsp;&nbsp;"
        end
        if !Setting.plugin_redmine_synapse['url_help_files'].empty?
          url = Setting.plugin_redmine_synapse['url_help_files']
          link = "<a href='" + url + "' target='_blank' class='icon icon-help'>"+ l(:label_help) + "</a>"
          output << "&nbsp;&nbsp;#{link}"
        end
        if !Setting.plugin_redmine_synapse['url_video_files'].empty?
          url = Setting.plugin_redmine_synapse['url_video_files']
          link = "<a href='" + url + "' target='_blank' class='icon icon-help'>"+ l(:label_synapse_video) + "</a>"
          output << "&nbsp;&nbsp;#{link}"
        end
      rescue
        output << ""
      end
      output << "</span>"
    end
    output << "<br/>"
    return output
  end
end
