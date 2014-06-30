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

module ScmExtensionsSubversionAdapterPatch
  def self.included(base) # :nodoc:
    base.send(:include, SubversionAdapterMethodsScmExtensions)

    base.class_eval do
      unloadable # Send unloadable so it will not be unloaded in development
    end

  end
end

module SubversionAdapterMethodsScmExtensions
  def scm_extensions_gettmpdir(create = true)
    tmpdir = Dir.tmpdir
    t = Time.now.strftime("%Y%m%d")
    n = nil
    begin
      path = "#{tmpdir}/#{t}-#{$$}-#{rand(0x100000000).to_s(36)}"
      path << "-#{n}" if n
      Dir.mkdir(path, 0700)
      Dir.rmdir(path) unless create
    rescue Errno::EEXIST
      n ||= 0
      n += 1
      retry
    end

    if block_given?
      begin
        yield path
      ensure
        FileUtils.remove_entry_secure path if File.exist?(path)
        fname = "#{path}.txt"
        FileUtils.remove_entry_secure fname if File.exist?(fname)
      end
    else
      path
    end
  end

  def scm_extensions_target(repository, path = '')
    base = repository.url
    base = base.sub(/^.*:\/\/[^\/]*\//,"file:///svnroot/") if !base.match('^file:')
    uri = "#{base}/#{path}"
    uri = URI.escape(URI.escape(uri), '[]')
    shell_quote(uri.gsub(/[?<>\*]/, ''))
  end

  def scm_extensions_upload(repository, folder_path, attachments, comments, identifier)
    return -1 if attachments.nil? || !attachments.is_a?(Hash)
    rev = identifier ? "@#{identifier}" : ""
    container =  entries(folder_path, identifier)
    if container
      error = false
      #use co +update + ci
      scm_extensions_gettmpdir(false) do |dir|
        commentfile = "#{dir}.txt"
        File.open(commentfile, 'w') {|f|
          f.write(comments)
          f.flush
        }

        cmd = "#{Redmine::Scm::Adapters::SubversionAdapter::SVN_BIN} checkout #{scm_extensions_target(repository, folder_path)}#{rev} #{dir} --depth empty --username #{User.current.login}"
        shellout(cmd)
        error = true if ($? != 0)

        attachments.each_value do |attachment|
          ajaxuploaded = attachment.has_key?("token")
  
          if ajaxuploaded
            filename = attachment['filename']
            token = attachment['token']
            tmp_att = Attachment.find_by_token(token)
            file = tmp_att.diskfile
          else
            file = attachment['file']
            next unless file && file.size > 0 && !error
            filename = File.basename(file.original_filename)
            next if scm_extensions_invalid_path(filename)
          end      

          if filename.respond_to?(:force_encoding)
            filename.force_encoding("UTF-8-MAC")
            if !filename.valid_encoding?
              filename.force_encoding("UTF-8")
            else
              filename.encode!(Encoding::UTF_8)
            end
          end
          
          entry = entries(File.join(folder_path,filename), identifier)
          if entry && entry.size > 0
            cmd = "#{Redmine::Scm::Adapters::SubversionAdapter::SVN_BIN} update \"#{File.join(dir, filename)}\" --username #{User.current.login}"
            shellout(cmd)
            error = true if ($? != 0)
          end

          outfile = File.join(dir, filename)
          if ajaxuploaded
            if File.exist?(outfile)
              File.delete(outfile)
            end
            FileUtils.mv file, outfile
            tmp_att.destroy
          else
            File.open(outfile, "wb") do |f|
              buffer = ""
              while (buffer = file.read(8192))
                f.write(buffer)
              end
            end
          end

          if !entry || entry.size == 0
            cmd = "#{Redmine::Scm::Adapters::SubversionAdapter::SVN_BIN} add \"#{File.join(dir, filename)}\" --username #{User.current.login}"
            shellout(cmd)
            error = true if ($? != 0)
          end
        end
        if !error
          cmd = "#{Redmine::Scm::Adapters::SubversionAdapter::SVN_BIN} commit #{dir} -F #{commentfile} --username #{User.current.login}"
          shellout(cmd)
          error = true if ($? != 0 && $? != 256)
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
    rev = identifier ? "@#{identifier}" : ""
    container =  entries(path, identifier)
    if container && path != "/"
      error = false
      scm_extensions_gettmpdir(false) do |dir|
        commentfile = "#{dir}.txt"
        File.open(commentfile, 'w') {|f|
          f.write(comments)
          f.flush
        }
        cmd = "#{Redmine::Scm::Adapters::SubversionAdapter::SVN_BIN} delete #{scm_extensions_target(repository, path)}#{rev}  -F #{commentfile} --username #{User.current.login}"
        shellout(cmd)
        error = true if ($? != 0 && $? != 256)
      end
      return error ? 1 : 0
    end
  end

  def scm_extensions_mkdir(repository, path, comments, identifier)
    return -1 if path.nil? || path.empty?
    rev = identifier ? "@#{identifier}" : ""
    error = false
    scm_extensions_gettmpdir(false) do |dir|
      commentfile = "#{dir}.txt"
      File.open(commentfile, 'w') {|f|
        f.write(comments)
        f.flush
      }
      cmd = "#{Redmine::Scm::Adapters::SubversionAdapter::SVN_BIN} mkdir #{scm_extensions_target(repository, path)}#{rev} -F #{commentfile} --username #{User.current.login}"
      shellout(cmd)
      error = true if ($? != 0 && $? != 256)
    end
    return error ? 1 : 0
  end

  def scm_extensions_invalid_path(path)
    return path =~ /\/\.\.\//
  end

end

Redmine::Scm::Adapters::SubversionAdapter.send(:include, ScmExtensionsSubversionAdapterPatch)
