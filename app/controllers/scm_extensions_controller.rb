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
require 'tmpdir'
require 'fileutils'

class ScmExtensionsController < ApplicationController
  unloadable

  layout 'base'
  before_filter :find_project, :except => [:show, :download]
  before_filter :find_repository, :only => [:show, :download]
  before_filter :authorize, :except => [:show, :download]

  helper :attachments
  include AttachmentsHelper

  def upload
    path_root = @repository.identifier.blank? ? "root" : @repository.identifier
    path = ""
    path << path_root
    path << "/#{params[:path]}" if (params[:path] && !params[:path].empty?)
    @scm_extensions = ScmExtensionsWrite.new(:path => path, :project => @project, :repository => @repository)

    if !request.get? && !request.xhr?
      @scm_extensions.path = params[:scm_extensions][:path]
      @scm_extensions.comments = params[:scm_extensions][:comments]
      @scm_extensions.recipients = params[:watchers]
      reg = Regexp.new("^#{path_root}")
      path = params[:scm_extensions][:path].sub(reg,'').sub(/^\//,'')
      attached = []
      if params[:attachments] && params[:attachments].is_a?(Hash)
        svnpath = path.empty? ? "/" : path

        if @repository.scm.respond_to?('scm_extensions_upload')
          ret = @repository.scm.scm_extensions_upload(@repository, svnpath, params[:attachments], params[:scm_extensions][:comments], nil)
          case ret
          when 0
            flash[:notice] = l(:notice_scm_extensions_upload_success) if @scm_extensions.recipients
            @scm_extensions.deliver(params[:attachments]) 
          when 1
            flash[:error] = l(:error_scm_extensions_upload_failed)
          when 2
            flash[:error] = l(:error_scm_extensions_no_path_head)
          end
        end

      end
      if @repository.identifier.blank?
        redirect_to :controller => 'repositories', :action => 'show', :id => @project, :path => path.to_s.split(%r{[/\\]}).select {|p| !p.blank?}
      else
        redirect_to :controller => 'repositories', :action => 'show', :id => @project, :repository_id => @repository.identifier, :path => path.to_s.split(%r{[/\\]}).select {|p| !p.blank?}
      end
      return
    end
  end

  def delete
    path = params[:path]
    parent = path
    svnpath = path.empty? ? "/" : path

    if @repository.scm.respond_to?('scm_extensions_delete')
      ret = @repository.scm.scm_extensions_delete(@repository, svnpath, "deleted #{path}", nil)
      case ret
      when 0
        parent = File.dirname(svnpath).sub(/^\//,'')
        flash[:notice] = l(:notice_scm_extensions_delete_success)
      when 1
        flash[:error] = l(:error_scm_extensions_delete_failed)
      end
    end

    if @repository.identifier.blank?
      redirect_to :controller => 'repositories', :action => 'show', :id => @project, :path => parent.to_s.split(%r{[/\\]}).select {|p| !p.blank?}
    else
      redirect_to :controller => 'repositories', :action => 'show', :id => @project, :repository_id => @repository.identifier, :path => parent.to_s.split(%r{[/\\]}).select {|p| !p.blank?}
    end
    return
  end

  def mkdir
    path_root = @repository.identifier.blank? ? "root" : @repository.identifier
    path = ""
    path << path_root
    path << "/#{params[:path]}" if (params[:path] && !params[:path].empty?)
    @scm_extensions = ScmExtensionsWrite.new(:path => path, :project => @project)

    if !request.get? && !request.xhr?
      path = params[:scm_extensions][:path].sub(/^#{path_root}/,'').sub(/^\//,'')
      foldername = params[:scm_extensions][:new_folder]
      svnpath = path.empty? ? "/" : path
      
      if @repository.scm.respond_to?('scm_extensions_mkdir')
        ret = @repository.scm.scm_extensions_mkdir(@repository, File.join(svnpath, foldername), params[:scm_extensions][:comments], nil)
        case ret
        when 0
          flash[:notice] = l(:notice_scm_extensions_mkdir_success)
        when 1
          flash[:error] = l(:error_scm_extensions_mkdir_failed)
        end
      end
      if @repository.identifier.blank?
        redirect_to :controller => 'repositories', :action => 'show', :id => @project, :path => path.to_s.split(%r{[/\\]}).select {|p| !p.blank?}
      else
        redirect_to :controller => 'repositories', :action => 'show', :id => @project, :repository_id => @repository.identifier, :path => path.to_s.split(%r{[/\\]}).select {|p| !p.blank?}
      end
      return
    end
  end

  def show
    return if !User.current.allowed_to?(:browse_repository, @project)
    @show_cb = params[:show_cb] if params[:show_cb] && !(params[:show_cb] =~ (/(false|f|no|n|0)$/i))
    @show_rev = params[:show_rev] if params[:show_rev] && !(params[:show_rev] =~ (/(false|f|no|n|0)$/i))
    @link_details = params[:link_details] if params[:link_details] && !(params[:link_details] =~ (/(false|f|no|n|0)$/i))
    @entries = @repository.entries(@path, @rev)
    if request.xhr?
      @entries ? render(:partial => 'scm_extensions/dir_list_content') : render(:nothing => true)
    end
  end

  def download
    return if !User.current.allowed_to?(:browse_repository, @project)
    @entry = @repository.entry(@path, @rev)
    (show_error_not_found; return) unless @entry

    # If the entry is a dir, show the browser
    (show; return) if @entry.is_dir?

    @content = @repository.cat(@path, @rev)
    (show_error_not_found; return) unless @content
    # Force the download
    send_data @content, :filename => @path.split('/').last, :disposition => "inline", :type => Redmine::MimeType.of(@path.split('/').last)
  end

  def notify
    path_root = @repository.identifier.blank? ? "root" : @repository.identifier
    path = ""
    path << path_root
    path << "/#{params[:path]}" if (params[:path] && !params[:path].empty?)
    @scm_extensions = ScmExtensionsWrite.new(:path => path, :project => @project, :repository => @repository)
    @show_cb = true

    @rev = nil
    @show_rev = nil
    @link_details = nil
    #need @entries, @rev, @project
    spath = ""
    spath = params[:path] if (params[:path] && !params[:path].empty?)
    @entries = @repository.entries(spath, @rev)

    if !request.get? && !request.xhr?
      @scm_extensions.path = params[:scm_extensions][:path]
      @scm_extensions.comments = params[:scm_extensions][:comments]
      @scm_extensions.recipients = params[:watchers]
      reg = Regexp.new("^#{path_root}")
      path = params[:scm_extensions][:path].sub(reg,'').sub(/^\//,'')
      attached = []
      svnpath = path.empty? ? "/" : path
      selectedfiles = []
      if params[:selectedfiles]
        reg2 = Regexp.new("^#{path}")
        params[:selectedfiles].each do |entrypath|
          selectedfiles << entrypath.sub(reg2,'').sub(/^\//,'')
        end
      end

      @scm_extensions.notify(selectedfiles) 
      flash[:notice] = l(:notice_scm_extensions_email_success) if @scm_extensions.recipients

      if @repository.identifier.blank?
        redirect_to :controller => 'repositories', :action => 'show', :id => @project, :path => path.to_s.split(%r{[/\\]}).select {|p| !p.blank?}
      else
        redirect_to :controller => 'repositories', :action => 'show', :id => @project, :repository_id => @repository.identifier, :path => path.to_s.split(%r{[/\\]}).select {|p| !p.blank?}
      end
      return
    end
  end

  private

  def find_project
    @project = Project.find(params[:id])
    if params[:repository_id].present?
      @repository = @project.repositories.find_by_identifier_param(params[:repository_id])
    else
      @repository = @project.repository
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_repository
    @project = Project.find(params[:id])
    if params[:repository_id].present?
      @repository = @project.repositories.find_by_identifier_param(params[:repository_id])
    else
      @repository = @project.repository
    end
    (render_404; return false) unless @repository
    @path = (params[:path].kind_of?(Array) ? params[:path].join('/') : params[:path]) unless params[:path].nil?
    @path ||= ''
    @rev = params[:rev].blank? ? @repository.default_branch : params[:rev].strip
    @rev_to = params[:rev_to]
  rescue ActiveRecord::RecordNotFound
    render_404
  rescue InvalidRevisionParam
    show_error_not_found
  end

  def svn_target(repository, path = '')
    base = repository.url
    base = base.sub(/^.*:\/\/[^\/]*\//,"file:///svnroot/")
    uri = "#{base}/#{path}"
    uri = URI.escape(URI.escape(uri), '[]')
    shell_quote(uri.gsub(/[?<>\*]/, ''))
  end

  def gettmpdir(create = true)
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

  def shell_quote(str)
    if Redmine::Platform.mswin?
      '"' + str.gsub(/"/, '\\"') + '"'
    else
      "'" + str.gsub(/'/, "'\"'\"'") + "'"
    end
  end

end
