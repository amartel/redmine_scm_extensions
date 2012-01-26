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

require_dependency 'application_helper'

module ScmExtensionsApplicationHelperPatch
  def self.included(base) # :nodoc:
    base.send(:include, ApplicationHelperMethodsScmExtensions)

    base.class_eval do
      unloadable # Send unloadable so it will not be unloaded in development
    end

  end
end

module ApplicationHelperMethodsScmExtensions
  def scm_extensions_format_revision(txt)
    txt.to_s[0,8]
  end

  def scm_extensions_link_to_revision(revision, project, repository, options={})
    text = options.delete(:text) || scm_extensions_format_revision(revision)
    link_to(text, {:controller => 'repositories', :action => 'revision', :id => project, :repository_id => repository.identifier, :rev => revision}, :title => l(:label_revision_id, revision))
  end

end

ApplicationHelper.send(:include, ScmExtensionsApplicationHelperPatch)
