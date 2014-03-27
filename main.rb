require 'rubygems'
require 'sinatra'
require 'pry'

set :sessions, true

helpers do
  def total(user)
   total = 0
    arry = user.map{|x| x[1]}
    arry.each do |card|
      if card == "ace"
        total += 11
      elsif card.to_i == 0 && card != "ace"
        total += 10
      else
        total += card.to_i
      end
    end
      arry.each do |card|
        if total > 21
          if card == "ace"
            total -= 10
          end
        end
      end
    total
  end

  def cards(value)
    suit = value[0]
    number = value[1]
    "<img src='/images/cards/#{suit}_#{number}.jpg' class='cards' height=200px width=80px>"
  end

  def loser!(msg)
    @play_again = true
    @show_btn = false
    @error = "Dealer wins. #{msg} #{session[:player_name]} now has $#{session[:chips]}"
  end

  def winner!(msg)
    @play_again = true
    @show_btn = false
    @success = "#{session[:player_name]} wins! #{msg} #{session[:player_name]} now has $#{session[:chips]}"
  end

  def push!(msg)
    @play_again = true
    @show_btn = false
    @info = "#{msg}"
  end
end

before do
  @show_btn = true
  @show_dealer = false
  @play_again = false
end

get '/' do
  if session[:player_name]
    redirect '/game'
  else
    redirect '/set_name'
  end 
end

get '/set_name' do
  erb :set_name
end

post '/set_name' do
  if params[:player_name].empty?
    @error = "Name is required!"
    halt erb :set_name
  end
  session[:player_name] = params[:player_name]
  session[:chips] = 500
  redirect '/game/bet'
end

get '/game/bet' do
  session[:bet] = 0
  if session[:chips] == 0
    @error = "You don't have anymore money! Play a new game!"
    halt erb :game_done
  end
  erb :blind_bet
end

post '/game/bet' do
  if params[:chip_count].empty? || params[:chip_count].to_i == 0
    @error = "Amount is required!"
    halt erb :blind_bet
  elsif params[:chip_count].to_i > session[:chips]
    @error = "Please enter an amount equal to or lower than your chip count"
    halt erb :blind_bet
  end
  session[:bet] = params[:chip_count].to_i
  redirect '/game'
end

get '/game' do
  suits = ["clubs", "diamonds", "hearts", "spades"]
  numbers = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "jack", "queen", "king", "ace"]
  session[:deck] = suits.product(numbers).shuffle!
  session[:player_cards] = []
  session[:dealer_cards] = []
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop

  if total(session[:player_cards]) == 21
    session[:chips] += session[:bet]
    winner!("#{session[:player_name]} hit BLACKJACK!")
  end

  erb :game
end

post '/game/player/hit' do
  session[:player_cards] << session[:deck].pop
  if total(session[:player_cards]) > 21 
    redirect '/game/compare'
  elsif total(session[:player_cards]) == 21
    redirect '/game/dealer'
  end
    erb :game, layout:false
end

post '/game/player/stay' do
  redirect '/game/dealer'
end

get '/game/dealer' do
  @show_btn = false
  @show_dealer = true
  if total(session[:dealer_cards]) > 16
    @show_dealer = false
    redirect '/game/compare'
  end
  erb :game, layout:false
end

post '/game/dealer' do
  session[:dealer_cards] << session[:deck].pop
  redirect '/game/dealer'
  erb :game, layout:false
end

get '/game/compare' do
  if total(session[:player_cards]) > 21
    session[:chips] -= session[:bet]
    loser!(" #{session[:player_name]} has busted!")
  elsif total(session[:dealer_cards]) == total(session[:player_cards])
    push!("Push")
  elsif total(session[:dealer_cards]) == 21 && total(session[:player_cards]) != 21
    session[:chips] -= session[:bet]
    loser!(" Dealer hit Blackjack.")
  elsif total(session[:dealer_cards]) > 21
    session[:chips] += session[:bet]
    winner!(" Dealer busted!")
  else
    if total(session[:dealer_cards]) > total(session[:player_cards])
      session[:chips] -= session[:bet]
      loser!("")
    else
      session[:chips] += session[:bet]
      winner!("")
    end
  end
  erb :game

get '/game/done' do
  erb :game_done
end