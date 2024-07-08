Gem::Specification.new do |spec|
  spec.name          = "FbRuby"
  spec.version       = "0.0.1"
  spec.authors       = ["Rahmat adha"]
  spec.email         = ["rahmadadha11@gmail.com"]
  spec.summary       = "Facebook Scraper"
  spec.description   = "Library ini di gunakan untuk scraping web facebook"
  spec.homepage      = "https://github.com/MR-X-Junior/fbruby"
  spec.license       = "MIT"
  spec.files         = Dir["lib/**/*.rb"] + ["Gemfile","README.md","LICENSE"]
  spec.require_paths = ["lib"]
  spec.required_ruby_version = ">= 3.0.0"
  spec.add_runtime_dependency "rest-client", "~> 2.1", ">= 2.1.0"
  spec.add_runtime_dependency "nokogiri", "~> 1.15", ">= 1.15.3"
  spec.add_development_dependency 'yard', '~> 0.9'
end
