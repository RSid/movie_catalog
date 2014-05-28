require 'sinatra'
require 'pg'
require 'shotgun'
require 'pry'

def db_connection
  begin
    connection = PG.connect(dbname: 'movies')

    yield(connection)

  ensure
    connection.close
  end
end

def display_movies(order=' movies.title',offset=" 0",query="")
  selector='SELECT movies.title, movies.year,movies.rating,genres.name,studios.name,movies.id FROM movies JOIN genres ON movies.genre_id=genres.id JOIN studios ON movies.studio_id=studios.id'+query+' ORDER BY'+order+' LIMIT 20 OFFSET'+offset+';'
  db_connection do |conn|
    movies=conn.exec(selector)
    movies.values
  end
end

def display_actors(offset=" 0")
  db_connection do |conn|
    actors=conn.exec('SELECT name,id FROM actors ORDER BY name LIMIT 20 OFFSET'+offset+';')
    actors.values
  end
end

def casting_details
  db_connection do |conn|
    casting_details=conn.exec('SELECT actors.name,actors.id,cast_members.character,movies.title, movies.id FROM actors JOIN cast_members ON actors.id=cast_members.actor_id JOIN movies ON cast_members.movie_id=movies.id ORDER BY actors.name;')
    casting_details.values
  end
end

get '/' do

  erb :index
end

get '/movies' do

  @order=params[:order]
  @page=params[:page].to_i
  @query=params[:query]

  if @order != nil && (@order=='year' || @order=='rating')
    @movies=display_movies(' movies.'+@order,' '+(@page*20).to_s)
  elsif @query != nil
    @movies=display_movies(' movies.title',' ' + (@page*20).to_s, ' WHERE movies.title ILIKE ' + "'%"+@query+"%'")
  else
    @movies=display_movies(' movies.title',' '+(@page*20).to_s)
  end

  erb :movies
end

get '/actors' do

  @page=params[:page].to_i
  @query=params[:query]

  @actors=display_actors(' '+@page.to_s)

  erb :actors
end

get '/actors/:id' do
  @id=params[:id]
  @casting_details=casting_details
  @actors=display_actors
  @movies=display_movies

  erb :actor
end

get '/movies/:id' do
  @id=params[:id]
  @casting_details=casting_details
  @movies=display_movies

  erb :movie
end
