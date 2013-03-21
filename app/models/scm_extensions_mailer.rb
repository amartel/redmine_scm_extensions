class ScmExtensionsMailer < Mailer
  def send_upload(obj, attachments )
    @obj = obj
    @attachments = attachments
    rec = @obj.recipients
    path_root = @obj.repository.identifier.blank? ? 'root' : @obj.repository.identifier
    sub = l(:label_scm_extensions_upload_subject, obj.project.name)
    reg = Regexp.new("^#{path_root}")
    @folder_path = @obj.path.sub(reg,'').sub(/^\//,'')
    mail :to => rec,
    :subject => sub
  end

  def notify(obj, selectedfiles )
    @obj = obj
    @selectedfiles = selectedfiles
    rec = @obj.recipients
    path_root = @obj.repository.identifier.blank? ? 'root' : @obj.repository.identifier
    sub = l(:label_scm_extensions_upload_subject, obj.project.name)
    reg = Regexp.new("^#{path_root}")
    @folder_path = @obj.path.sub(reg,'').sub(/^\//,'')
    mail :to => rec,
    :subject => sub
  end
end
