require 'juggernaut'
class ChatsController < ApplicationController

  def index
    @chats = Chat.all
  end

  def show
    @chat = Chat.find params[:id]
  end

  def message
    Juggernaut.publish(params["chat_id"],params["message"]);
    render :nothing => true
  end
end
