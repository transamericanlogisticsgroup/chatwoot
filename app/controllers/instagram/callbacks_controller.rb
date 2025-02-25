class Instagram::CallbacksController < ApplicationController
  include InstagramConcern

  def show
    Rails.logger.info("Instagram OAuth Code: #{oauth_code}")

    @response = oauth_client.auth_code.get_token(
      oauth_code,
      redirect_uri: "#{base_url}/#{provider_name}/callback",
      grant_type: 'authorization_code'
    )
    Rails.logger.info("Initial token response: #{@response.inspect}")

    # Exchange for long-lived token
    @long_lived_token_response = exchange_for_long_lived_token(@response.token)
    Rails.logger.info("Long-lived token response: #{@long_lived_token_response}")

    create_channel_with_inbox
    redirect_to '/'
  rescue StandardError => e
    Rails.logger.error("Instagram Channel creation Error: #{e.message}")
    ChatwootExceptionTracker.new(e).capture_exception
    redirect_to '/'
  end

  private

  def create_channel_with_inbox
    ActiveRecord::Base.transaction do
      Rails.logger.info("Creating channel with inbox")

      expires_at = Time.current + @long_lived_token_response['expires_in'].seconds
      Rails.logger.info("Expires at: #{expires_at}")

      channel_instagram = Channel::Instagram.create!(
        access_token: @long_lived_token_response['access_token'],
        instagram_id: @response.params['user_id'].to_s,
        account: account,
        expires_at: expires_at
      )

      account.inboxes.create!(
        account: account,
        channel: channel_instagram,
        name: "Instagram"
      )
    end
  end

  def oauth_client
    instagram_client
  end

  def long_lived_token_response
    @long_lived_token_response ||= exchange_for_long_lived_token(oauth_code)
  end

  def account_id
    1
  end

  def provider_name
    raise NotImplementedError
  end

  def oauth_code
    params[:code]
  end

  def account
    @account ||= Account.find(account_id)
  end

  def provider_name
    'instagram'
  end
end
