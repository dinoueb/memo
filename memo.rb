# frozen_string_literal: true

require 'sinatra'
require 'json'

MEMOS_JSON_PATH = './data/memos.json'
DEFAULT_TITLE = '新規メモ'

helpers do
  def h(text)
    Rack::Utils.escape_html(text)
  end
end

def fill_default_name(memo)
  {
    id: memo[:id],
    title: DEFAULT_TITLE,
    text: memo[:text]
  }
end

def load_memos
  File.open(MEMOS_JSON_PATH, 'r') do |file|
    file.flock(File::LOCK_SH)
    JSON.parse(file.read, symbolize_names: true)
  end
end

def find_memo(id)
  memos = load_memos
  memos.find { |memo| memo[:id] == id }
end

def insert_memo(**target_memo)
  File.open(MEMOS_JSON_PATH, 'r+') do |file|
    file.flock(File::LOCK_EX)

    memos = JSON.parse(file.read, symbolize_names: true)
    max_id = memos.map { |memo| memo[:id] }.max || 0
    target_memo[:id] = max_id + 1
    memos << target_memo

    file.rewind
    file.truncate(0)
    file.puts(JSON.pretty_generate(memos))
  end

  target_memo
end

def delete_memo(id)
  File.open(MEMOS_JSON_PATH, 'r+') do |file|
    file.flock(File::LOCK_EX)

    memos = JSON.parse(file.read, symbolize_names: true)
    filtered_memos = memos.reject { |memo| memo[:id] == id }

    break unless filtered_memos.length == memos.length - 1

    file.rewind
    file.truncate(0)
    file.puts(JSON.pretty_generate(filtered_memos))
  end
end

def update_memo(**target_memo)
  File.open(MEMOS_JSON_PATH, 'r+') do |file|
    file.flock(File::LOCK_EX)

    memos = JSON.parse(file.read, symbolize_names: true)
    filtered_memos = memos.reject { |memo| memo[:id] == target_memo[:id] }

    return false unless filtered_memos.length == memos.length - 1

    filtered_memos << target_memo

    file.rewind
    file.truncate(0)
    file.puts(JSON.pretty_generate(filtered_memos))
  end

  true
end

get '/' do
  redirect '/memos'
end

get '/memos' do
  @memos = load_memos
           .map { |memo| memo[:title].strip.empty? ? fill_default_name(memo) : memo }
           .sort_by { |memo| memo[:id] }

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
