class ScmExtensionsWrite

  attr_accessor :comments
  attr_accessor :new_folder
  attr_accessor :path
  attr_accessor :project

  def initialize(options = { })
    self.comments = options[:comments]
    self.new_folder = options[:new_folder]
    self.path = options[:path]
    self.project = options[:project]
  end

end
