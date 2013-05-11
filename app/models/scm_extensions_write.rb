class ScmExtensionsWrite

  #acts_as_watchable

  attr_accessor :comments
  attr_accessor :new_folder
  attr_accessor :path
  attr_accessor :project
  attr_accessor :recipients
  attr_accessor :repository

  def initialize(options = { })
    self.comments = options[:comments]
    self.new_folder = options[:new_folder]
    self.path = options[:path]
    self.project = options[:project]
    self.repository = options[:repository]
    self.recipients = {}
  end

  def deliver(attachments)
    recipientsWithLang = {}
    if !self.recipients.nil?
      self.recipients.each do |mail|
        user = User.find_by_mail(mail);
        if !user.nil?
          lang = user.language
          if recipientsWithLang[lang].nil?
            recipientsWithLang[lang] = [ mail ]
          else
            recipientsWithLang[lang] << mail
          end
        end
      end
      recipientsWithLang.each do |language,rec|
        ScmExtensionsMailer.send_upload(self, attachments, language, rec).deliver
      end
    end
    return true

  end

  def notify(selectedfiles)
    recipientsWithLang = {}
    if !self.recipients.nil?
      self.recipients.each do |mail|
        user = User.find_by_mail(mail);
        if !user.nil?
          lang = user.language
          if recipientsWithLang[lang].nil?
            recipientsWithLang[lang] = [ mail ]
          else
            recipientsWithLang[lang] << mail
          end
        end
      end
      recipientsWithLang.each do |language,rec|
        ScmExtensionsMailer.notify(self, selectedfiles, language, rec).deliver
      end
    end
    return true
  end
end
