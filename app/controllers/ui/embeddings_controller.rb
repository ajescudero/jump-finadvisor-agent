class Ui::EmbeddingsController < ApplicationController
  def index
    @users = User.order(:id).limit(50)
    @recent = Embedding.order(id: :desc).limit(10)
  end
end
