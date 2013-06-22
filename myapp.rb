require 'sinatra'
require 'sinatra/reloader'

set :bind, '0.0.0.0'
set :port, 8888

get '/' do
  "Hello World. reload test"
end

get '/about' do
  "on ctrees."
end
