require 'sinatra'
require 'sinatra/reloader'

set :bind, '0.0.0.0'
set :port, 8888

get '/' do
  "Hello World."
end
