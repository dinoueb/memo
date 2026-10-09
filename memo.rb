require 'sinatra'

enable :method_override

get '/memos' do
  erb :index
end

get '/memos/new' do
  erb :new
end

post '/memos' do
  redirect '/memos'
end

get '/memos/:id' do
  erb :detail
end

delete '/memos/:id' do
  redirect '/memos'
end

get '/memos/:id/edit' do
  erb :edit
end

patch '/memos/:id' do
  redirect '/memos'
end
