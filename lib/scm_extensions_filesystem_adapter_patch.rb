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

  def scm_extensions_upload(project, folder_path, attachments, comments, identifier)
    return -1 if attachments.nil? || !attachments.is_a?(Hash)
    return -1 if scm_extensions_invalid_path(folder_path)
    metapath = (self.url =~ /\/files\/$/ && File.exist?(self.url.sub(/\/files\//, "/attributes")))

    rev = identifier ? "@{identifier}" : ""
    container =  entries(folder_path, identifier)
    if container
      error = false

      attachments.each_value do |attachment|
        file = attachment['file']
        next unless file && file.size > 0 && !error
        filename = File.basename(file.original_filename)
        next if scm_extensions_invalid_path(filename)
        begin
          File.open(File.join(project.repository.url, folder_path, filename), "wb") do |f|
            buffer = ""
            while (buffer = file.read(8192))
              f.write(buffer)
            end
          end
          if metapath
            metapathtarget = File.join(project.repository.url, folder_path, filename).sub(/\/files\//, "/attributes/")
            FileUtils.mkdir_p File.dirname(metapathtarget)
            File.open(metapathtarget, "w") do |f|
              f.write(User.current)
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

  def scm_extensions_delete(project, path, comments, identifier)
    return -1 if path.nil? || path.empty?
    return -1 if scm_extensions_invalid_path(path)
    metapath = (self.url =~ /\/files\/$/ && File.exist?(self.url.sub(/\/files\//, "/attributes")))
    container =  entries(path, identifier)
    if container && path != "/"
      error = false

      begin
      FileUtils.remove_entry_secure File.join(project.repository.url, path)
      if metapath
        metapathtarget = File.join(project.repository.url, path).sub(/\/files\//, "/attributes/")
        FileUtils.remove_entry_secure metapathtarget if File.exist?(metapathtarget)
      end
      rescue
        error = true
      end

      return error ? 1 : 0
    end
  end

  def scm_extensions_mkdir(project, path, comments, identifier)
    return -1 if path.nil? || path.empty?
    return -1 if scm_extensions_invalid_path(path)

    error = false
    begin
      Dir.mkdir(File.join(project.repository.url, path))
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
