class EmbeddingsController < ApplicationController
  protect_from_forgery with: :null_session

  # POST /embeddings
  # Accepts either:
  # { embedding: { user_id, kind, ref_id, chunk, embedding: [..] } }
  # or with content text to vectorize via provider:
  # { embedding: { user_id, kind, ref_id, chunk, content: "text to embed" } }
  def create
    attrs = embedding_params
    vector = attrs[:embedding]
    if vector.blank?
      content = params.dig(:embedding, :content)
      raise ActionController::ParameterMissing, "embedding[embedding] or embedding[content] is required" if content.blank?
      vector = EmbeddingProvider.embed_text(content)
    end

    e = Embedding.find_or_initialize_by(
      user_id: attrs[:user_id],
      kind: attrs[:kind],
      ref_id: attrs[:ref_id]
    )
    e.chunk = attrs[:chunk]
    e.embedding = vector
    e.save!
    render json: { id: e.id }
  rescue => ex
    render json: { error: ex.message }, status: 422
  end

  # POST /embeddings/nearest
  # Accepts either query_vector: [] or query_text: "..."
  def nearest
    vector = params[:query_vector]
    if vector.blank?
      qtext = params[:query_text]
      raise ActionController::ParameterMissing, "query_vector or query_text is required" if qtext.blank?
      vector = EmbeddingProvider.embed_text(qtext)
    end

    limit = params.fetch(:limit, 5).to_i
    distance = params.fetch(:distance, "cosine").to_sym
    rows = Embedding.nearest_neighbors(:embedding, vector, distance: distance)
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
