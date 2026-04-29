require "sinatra"
require "sinatra/multi_route"
require "linzer"

configure do
  # https://www.rfc-editor.org/rfc/rfc9421.html#name-example-ed25519-test-key
  set :test_key_ed25519_rfc9421,
    Linzer.new_ed25519_key(IO.read('./example_ed25519_pubkey.pem'))
  set :app_private_key, # ...
    Linzer.new_ed25519_key(Base64.strict_decode64(ENV.fetch("APP_KEY")))
end

helpers do
  def app_private_key
    settings.app_private_key
  end
  def app_public_key
    app_private_key.material.public_to_pem
  end
  def signed?(request)
    pubkey = settings.test_key_ed25519_rfc9421
    # This method will accept any signed request with the example ed25519 key
    # from RFC9421. A real world endpoint would also check whether the signature
    # is acceptable (e.g. it has the expected covered component, it's not
    # expired, etc.
    Linzer.verify!(request, key: pubkey) rescue false
  end
end

after do
  content_type :text
  response.headers["date"] = Time.now.httpdate
  Linzer.sign!(response, key: app_private_key, components: %w[@status date])
end

get "/" do
  "Hello world!"
end

route :get, :post, "/verify" do
  halt 401, "Signature is required!" unless signed? request
  "Got a valid signed request!"
end

get "/pubkey" do
  app_public_key
end
