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
    ScmExtensionsMailer.deliver_send_upload(self, attachments)
      return true
  end

end
