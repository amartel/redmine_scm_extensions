#map.connect ':controller/:action/:id'
ActionController::Routing::Routes.draw do |map|
  map.connect 'projects/:id/scm_extensions/:action', :controller => 'scm_extensions'
end
