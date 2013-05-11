class ScmExtensionsMailer < Mailer
  def send_upload(obj, attachments, language, rec )
    @obj = obj
    @attachments = attachments
    set_language_if_valid language
    path_root = @obj.repository.identifier.blank? ? 'root' : @obj.repository.identifier
    sub = l(:label_scm_extensions_upload_subject, obj.project.name)
    reg = Regexp.new("^#{path_root}")
    @folder_path = @obj.path.sub(reg,'').sub(/^\//,'')
    mail :to => rec,
    :subject => sub
  end

  def notify(obj, selectedfiles, language, rec )
    @obj = obj
    @selectedfiles = selectedfiles
    set_language_if_valid language
    path_root = @obj.repository.identifier.blank? ? 'root' : @obj.repository.identifier
    sub = l(:label_scm_extensions_upload_subject, obj.project.name)
    reg = Regexp.new("^#{path_root}")
    @folder_path = @obj.path.sub(reg,'').sub(/^\//,'')
    mail :to => rec,
    :subject => sub
  end
end
