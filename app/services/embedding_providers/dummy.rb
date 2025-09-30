# frozen_string_literal: true

module EmbeddingProviders
  class Dummy
    # Deterministic pseudo-random vector based on text hash for repeatability
    def embed_text(text, dimensions: 1536)
      seed = text.to_s.hash
      rng = Random.new(seed)
      Array.new(dimensions) { rng.rand }
    end
  end
end
