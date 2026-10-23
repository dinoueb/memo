# frozen_string_literal: true

at_exit do
  $cp.shutdown { |c| c.close }
end

require 'sinatra'
require 'pg'
require 'connection_pool'

configure do
  $cp = ConnectionPool.new(size: 5, timeout: 5) do
    conn = PG.connect(dbname: 'memo')
    conn.field_name_type = :symbol

    conn
  end
end

helpers do
  def h(text)
    Rack::Utils.escape_html(text)
  end
end

def exec_sql(sql, *params)
  $cp.with do |conn|
    begin
      result = if params.empty?
                conn.exec(sql)
              else
                conn.exec_params(sql, params)
              end
    rescue PG::Error
      result = nil
    end

    result
  end
end

def load_memos
  exec_sql('SELECT * FROM memos ORDER BY id')
end

def find_memo(id)
  exec_sql('SELECT * FROM memos WHERE id = $1', id)&.first
end

def insert_memo(**memo)
  exec_sql('INSERT INTO memos (title, text) VALUES ($1, $2) RETURNING id', memo[:title], memo[:text])[0]
end

def delete_memo(id)
  exec_sql('DELETE FROM memos WHERE id = $1', id)
end

def update_memo(**memo)
  exec_sql('UPDATE memos SET (title, text) = ($1, $2) WHERE id = $3', memo[:title], memo[:text], memo[:id])
end

get '/' do
  redirect '/memos'
end

get '/memos' do
  @memos = load_memos

  erb :index
end

get '/memos/new' do
  erb :new
end

post '/memos' do
  @memo = insert_memo(title: params['title'], text: params['text'])
  redirect "/memos/#{@memo[:id]}"
end

get '/memos/:id' do
  @memo = find_memo(params['id'].to_i)
  halt 404 unless @memo

  erb :detail
end

delete '/memos/:id' do
  delete_memo(params['id'].to_i)
  redirect '/memos'
end

get '/memos/:id/edit' do
  @memo = find_memo(params['id'].to_i)
  halt 404 unless @memo

  erb :edit
end

patch '/memos/:id' do
  is_success = update_memo(id: params['id'].to_i, title: params['title'], text: params['text'])
  halt 404 unless is_success

  redirect "/memos/#{params['id']}"
end

not_found do
  erb :error
end
