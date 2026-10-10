require 'sinatra'
require 'json'

MEMOS_JSON_PATH = './data/memos.json'
DEFAULT_TITLE = '新規メモ'

def fill_default_name(memo)
  {
    "id" => memo["id"],
    "title" => DEFAULT_TITLE,
    "text" => memo["text"]
  }
end

def load_memos
  File.open(MEMOS_JSON_PATH, 'r') do |file|
    file.flock(File::LOCK_SH)
    JSON.parse(file.read)
  end
end

def find_memo(id)
  memos = load_memos
  memos.find { |memo| memo["id"] == id }
end

get '/memos' do
  @memos = load_memos.map { |memo| memo["title"].strip.empty? ? fill_default_name(memo) : memo }
            .sort_by { |memo| memo["id"] }

  erb :index
end

get '/memos/new' do
  erb :new
end

post '/memos' do
  File.open(MEMOS_JSON_PATH, 'r+') do |file|
    file.flock(File::LOCK_EX)

    memos = JSON.parse(file.read)
    max_id = memos.map { |memo| memo["id"] }.max || 0
    memo = {
      "id" => max_id + 1,
      "title" => params["title"],
      "text" => params["text"]
    }
    memos << memo

    file.rewind
    file.truncate(0)
    file.puts(JSON.pretty_generate(memos))
  end

  redirect '/memos'
end

get '/memos/:id' do
  @memo = find_memo(params["id"].to_i)

  erb :detail
end

delete '/memos/:id' do
  File.open(MEMOS_JSON_PATH, 'r+') do |file|
    file.flock(File::LOCK_EX)

    memos = JSON.parse(file.read)
    filtered_memos = memos.reject { |memo| memo["id"] == params["id"].to_i }

    if filtered_memos.length == memos.length - 1
      file.rewind
      file.truncate(0)
      file.puts(JSON.pretty_generate(filtered_memos))
    end
  end

  redirect '/memos'
end

get '/memos/:id/edit' do
  @memo = find_memo(params["id"].to_i)

  erb :edit
end

patch '/memos/:id' do
  File.open(MEMOS_JSON_PATH, 'r+') do |file|
    file.flock(File::LOCK_EX)

    memos = JSON.parse(file.read)
    filtered_memos = memos.reject { |memo| memo["id"] == params["id"].to_i }

    if filtered_memos.length == memos.length - 1
      memo = {
        "id" => params["id"].to_i,
        "title" => params["title"],
        "text" => params["text"]
      }
      filtered_memos << memo

      file.rewind
      file.truncate(0)
      file.puts(JSON.pretty_generate(filtered_memos))
    end
  end

  redirect '/memos'
end
