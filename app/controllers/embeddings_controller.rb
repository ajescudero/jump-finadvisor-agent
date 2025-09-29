class EmbeddingsController < ApplicationController
  protect_from_forgery with: :null_session

  def create
    e = Embedding.find_or_initialize_by(
      user_id: embedding_params[:user_id],
      kind: embedding_params[:kind],
      ref_id: embedding_params[:ref_id]
    )
    e.chunk = embedding_params[:chunk]
    e.embedding = embedding_params[:embedding]
    e.save!
    render json: { id: e.id }
  rescue => ex
    render json: { error: ex.message }, status: 422
  end

  def nearest
    q = params.require(:query_vector)
    limit = params.fetch(:limit, 5).to_i
    distance = params.fetch(:distance, "cosine").to_sym
    rows = Embedding.nearest_neighbors(:embedding, q, distance: distance)
                    .limit(limit)
                    .pluck(:id, :user_id, :kind, :ref_id)
    render json: { results: rows.map { |id, uid, kind, ref| { id: id, user_id: uid, kind: kind, ref_id: ref } } }
  rescue => ex
    render json: { error: ex.message }, status: 422
  end

  private

  def embedding_params
    params.require(:embedding).permit(:user_id, :kind, :ref_id, :chunk, embedding: [])
  end
end
