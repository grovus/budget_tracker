# Be sure to restart your server when you modify this file.

# Your secret key is used for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!

# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
# You can use `rake secret` to generate a secure secret key.

# Make sure your secret_key_base is kept private
# if you're sharing your code publicly.
require 'securerandom'

def secure_token
  token_file = Rails.root.join('.secret')
  if File.exist?(token_file)
    # Use the existing token.
    File.read(token_file).chomp
  else
    # Generate a new token and store it in token_file.
    token = SecureRandom.hex(64)
    File.write(token_file, token)
    token
  end
end

BudgetTracker::Application.config.secret_key_base = secure_token
#FuelTracker::Application.config.secret_key_base = '88644e77ac8a274dd2cb66c38b5acb289a83b6a90e1ce33651a45ba890beec20a92487812bb11167dd37ca814ab184f41436a820515fdef6e90233fa28507dd2'
