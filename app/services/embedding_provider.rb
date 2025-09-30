# frozen_string_literal: true

# Pluggable embedding provider. Choose with ENV EMBEDDING_PROVIDER: "openai" or "dummy" (default)
class EmbeddingProvider
  def self.provider
    @provider ||= begin
      case (ENV["EMBEDDING_PROVIDER"] || "dummy").downcase
      when "openai"
        EmbeddingProviders::OpenAI.new
      else
        EmbeddingProviders::Dummy.new
      end
    end
  end

  # Convenience wrapper for text -> vector
  def self.embed_text(text, dimensions: 1536)
    provider.embed_text(text, dimensions: dimensions)
  end
end
