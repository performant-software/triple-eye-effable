TripleEyeEffable::Engine.routes.draw do
  post '/direct_uploads', to: 'direct_uploads#create'
end
