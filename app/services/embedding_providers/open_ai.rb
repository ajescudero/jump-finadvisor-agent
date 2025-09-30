# frozen_string_literal: true

require "json"
require "net/http"

module EmbeddingProviders
  class OpenAI
    DEFAULT_MODEL = ENV.fetch("OPENAI_EMBEDDING_MODEL", "text-embedding-3-small")

    def embed_text(text, dimensions: 1536)
      api_key = ENV["OPENAI_API_KEY"]
      raise "OPENAI_API_KEY missing" if api_key.to_s.strip.empty?

      uri = URI("https://api.openai.com/v1/embeddings")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      req = Net::HTTP::Post.new(uri)
      req["Authorization"] = "Bearer #{api_key}"
      req["Content-Type"] = "application/json"
      req.body = { input: text.to_s, model: DEFAULT_MODEL, dimensions: dimensions }.to_json

      res = http.request(req)
      raise "OpenAI error #{res.code}: #{res.body}" unless res.is_a?(Net::HTTPSuccess)

      body = JSON.parse(res.body)
      body.fetch("data").first.fetch("embedding")
    end
  end
end
