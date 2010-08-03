class ScmExtensionsMailer < Mailer
  def send_upload(obj, attachments )
    @obj = obj
    rec = @obj.recipients
    recipients rec
    subject l(:label_scm_extensions_upload_subject, obj.project.name)
    body :obj => obj, :attachments => attachments, :folder_path => @obj.path.sub(/^root/,'').sub(/^\//,'')
    #from User.current.mail
    render_multipart("upload", body)
  end
end
