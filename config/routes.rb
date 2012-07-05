#map.connect ':controller/:action/:id'
match 'projects/:id/scm_extensions/:action', :controller => 'scm_extensions'
