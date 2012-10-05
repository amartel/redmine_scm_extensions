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

module ScmExtensionsFilesystemAdapterPatch
  def self.included(base) # :nodoc:
    base.send(:include, FilesystemAdapterMethodsScmExtensions)

    base.class_eval do
      unloadable # Send unloadable so it will not be unloaded in development
    end

  end
end

module FilesystemAdapterMethodsScmExtensions

  def scm_extensions_upload(repository, folder_path, attachments, comments, identifier)
    return -1 if attachments.nil? || !attachments.is_a?(Hash)
    return -1 if scm_extensions_invalid_path(folder_path)
    metapath = (self.url =~ /\/files\/$/ && File.exist?(self.url.sub(/\/files\//, "/attributes")))

    rev = identifier ? "@{identifier}" : ""
    fullpath = File.join(repository.url, folder_path)
    if File.exist?(fullpath) && File.directory?(fullpath)
      error = false

      if repository.supports_all_revisions?
        rev = -1
        rev = repository.latest_changeset.revision.to_i if repository.latest_changeset
        rev = rev + 1
        changeset = Changeset.create(:repository => repository,
                                                 :revision => rev, 
                                                 :committer => User.current.login, 
                                                 :committed_on => Time.now,
                                                 :comments => comments)
      
      end
      attachments.each_value do |attachment|
        file = attachment['file']
        next unless file && file.size > 0 && !error
        filename = File.basename(file.original_filename)
        next if scm_extensions_invalid_path(filename)
        begin
          if repository.supports_all_revisions?
            action = "A"
            action = "M" if File.exists?(File.join(repository.url, folder_path, filename)) 
            Change.create( :changeset => changeset, :action => action, :path => File.join("/", folder_path, filename))
          end
          File.open(File.join(repository.url, folder_path, filename), "wb") do |f|
            buffer = ""
            while (buffer = file.read(8192))
              f.write(buffer)
            end
          end
          if metapath
            metapathtarget = File.join(repository.url, folder_path, filename).sub(/\/files\//, "/attributes/")
            FileUtils.mkdir_p File.dirname(metapathtarget)
            File.open(metapathtarget, "w") do |f|
              f.write("#{User.current}\n")
              f.write("#{rev}\n")
            end
          end

        rescue
          error = true
        end
      end

      if error
        return 1
      else
        return 0
      end
    else
      return 2
    end
  end

  def scm_extensions_delete(repository, path, comments, identifier)
    return -1 if path.nil? || path.empty?
    return -1 if scm_extensions_invalid_path(path)
    metapath = (self.url =~ /\/files\/$/ && File.exist?(self.url.sub(/\/files\//, "/attributes")))
    if File.exist?(File.join(repository.url, path)) && path != "/"
      error = false

      begin
        if repository.supports_all_revisions?
          rev = -1
          rev = repository.latest_changeset.revision.to_i if repository.latest_changeset
          rev = rev + 1
          changeset = Changeset.create(:repository => repository,
                                                   :revision => rev, 
                                                   :committer => User.current.login, 
                                                   :committed_on => Time.now,
                                                   :comments => comments)
          Change.create( :changeset => changeset, :action => 'D', :path => File.join("/", path))
        end
          
      FileUtils.remove_entry_secure File.join(repository.url, path)
      if metapath
        metapathtarget = File.join(repository.url, path).sub(/\/files\//, "/attributes/")
        FileUtils.remove_entry_secure metapathtarget if File.exist?(metapathtarget)
      end
      rescue
        error = true
      end

      return error ? 1 : 0
    end
  end

  def scm_extensions_mkdir(repository, path, comments, identifier)
    return -1 if path.nil? || path.empty?
    return -1 if scm_extensions_invalid_path(path)

    error = false
    begin
      if repository.supports_all_revisions?
        rev = -1
        rev = repository.latest_changeset.revision.to_i if repository.latest_changeset
        rev = rev + 1
        changeset = Changeset.create(:repository => repository,
                                                 :revision => rev, 
                                                 :committer => User.current.login, 
                                                 :committed_on => Time.now,
                                                 :comments => "created folder: #{path}")
        Change.create( :changeset => changeset, :action => 'A', :path => File.join("/", path))
      end
      Dir.mkdir(File.join(repository.url, path))
    rescue
      error = true
    end

    return error ? 1 : 0
  end

  def scm_extensions_invalid_path(path)
    return path =~ /\/\.\.\//
  end

end

Redmine::Scm::Adapters::FilesystemAdapter.send(:include, ScmExtensionsFilesystemAdapterPatch)
