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

    respond_to do |format|
      format.html { redirect_to root_path, notice: "Embedding saved" }
      format.turbo_stream { redirect_to root_path, notice: "Embedding saved" }
      format.json { render json: { id: e.id } }
    end
  rescue => ex
    respond_to do |format|
      format.html { redirect_to root_path, alert: ex.message }
      format.turbo_stream { redirect_to root_path, alert: ex.message }
      format.json { render json: { error: ex.message }, status: 422 }
    end
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

    limit    = params.fetch(:limit, 5).to_i
    distance = params.fetch(:distance, "cosine").to_sym

    @rows = Embedding.nearest_neighbors(:embedding, vector, distance: distance)
                     .limit(limit)
                     .select(:id, :user_id, :kind, :ref_id, :chunk)

    respond_to do |format|
      # Nice in-page update with Turbo Streams
      format.turbo_stream do
        render turbo_stream: turbo_stream.update(
          "nearest_results",
          partial: "ui/embeddings/nearest_results",
          locals: { rows: @rows }
        )
      end
      # Keep JSON API behavior unchanged
      format.json do
        render json: {
          results: @rows.map { |r| { id: r.id, user_id: r.user_id, kind: r.kind, ref_id: r.ref_id } }
        }
      end
      # Optional HTML fallback
      format.html { redirect_to root_path, notice: "Search complete" }
    end
  rescue => ex
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update(
          "nearest_results",
          %(<div class="text-red-600">#{ERB::Util.html_escape(ex.message)}</div>).html_safe
        )
      end
      format.json { render json: { error: ex.message }, status: 422 }
      format.html { redirect_to root_path, alert: ex.message }
    end
  end

  private

  def embedding_params
    params.require(:embedding).permit(:user_id, :kind, :ref_id, :chunk, embedding: [])
  end
end
