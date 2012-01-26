class ScmExtensionsMailer < Mailer
  def send_upload(obj, attachments )
    @obj = obj
    rec = @obj.recipients
    recipients rec
    path_root = @obj.repository.identifier.blank? ? 'root' : @obj.repository.identifier
    subject l(:label_scm_extensions_upload_subject, obj.project.name)
    reg = Regexp.new("^#{path_root}")
    body :obj => obj, :attachments => attachments, :folder_path => @obj.path.sub(reg,'').sub(/^\//,'')
    #from User.current.mail
    render_multipart("upload", body)
  end
end
