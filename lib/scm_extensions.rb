#Extend the ActionMailer to include plugin in its paths
ActionMailer::Base.append_view_path(File.expand_path(File.dirname(__FILE__) + '/../app/views'))
