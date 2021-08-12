class CardsController < ApplicationController
  require "stripe"

  def new
    gon.stripe_public_key = ENV['STRIPE_PUBLISHABLE_KEY']
    card = Card.where(user_id: current_user.id)
    redirect_to new_post_gift_url(id: params[:id]) if card.exists?
  end

  def create
    # あらかじめ環境変数に入れておいたテスト用秘密鍵をセット
    Stripe.api_key = ENV['STRIPE_SECRET_KEY']
    # トークンが生成されていなかった場合は何もせずリダイレクト
    if params['stripeToken'].blank?
      redirect_to posts_url
    else
      # 送金元ユーザのStripeアカウントを生成
      sender = Stripe::Customer.create({
        # nameとemailは必須ではないが分かりやすくするために載せている
        name: current_user.name,
        email: current_user.email,
        source: params['stripeToken'],
      })
      # Cardテーブルに送金元ユーザのこのアプリでのIDと、StripeアカウントでのIDを保存
      @card = Card.new(
        user_id: current_user.id,
        customer_id: sender.id,
      )
      if @card.save
        redirect_to new_post_gift_url(id: params[:id])
      else
        redirect_to posts_url
      end
    end
  end
end
