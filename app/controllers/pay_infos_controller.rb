require 'stripe'
class PayInfosController < ApplicationController


  def create
    post = Post.find(params[:id])

    begin

      ActiveRecord::Base.transaction  do
        #二重決済を防ぐためにすでにpaymentテーブルがユニークか調べる
        raise "Already paid" if post.payment.present?
        #後でPaymentをnewする際に、万が一エラーが起こらないように、transactionの中でpayment_paramsの値を確認しておく
        raise "prameter error" unless params[:amount].present? && params[:stripeEmail].present? && params[:stripeToken].present?
      end

      ##############Stripe（決済）#########################################
        customer = Stripe::Customer.create(
          email: params[:stripeEmail],
          source: params[:stripeToken]
        )

        charge = Stripe::Charge.create(
          customer:       customer.id,
          amount:         params[:amount],
          description:    "「#{@room.name}」の決済",
          currency:       'jpy',
          receipt_email:  params[:stripeEmail],
          metadata: {'仮払い' => "1回目"},
          capture: false #capture:falseにすると仮払いで処理してくれる。
        )
      #####################################################################

      ###############決済記録を作成###################################################
        # stripeのcheckoutフォームから送られてきたパラメーターでpaymentのインスタンスを作成
        pay_info = PayInfo.new(pay_info_params)

        pay_info.email = customer.email # 支払った人がstripeのcheckoutフォームに入力したemail(支払い完了後、stripeからこのメールアドレスに支払い完了メールが送られる)
        pay_info.description = charge.description #決済の概要
        pay_info.currency = charge.currency  #通貨
        pay_info.customer_id = customer.id   # stripeのcustomerインスタンスのID
        pay_info.payment_date = Time.current # payment_date(支払いを行った時間)は現在時間を入れる
        pay_info.payment_status = "仮払い" # payment_status(この支払い)は仮払い状態(stripeのcaptureをfalseにしている)
        pay_info.uuid = SecureRandom.uuid  # 請求書の番号としてuuidを用意する
        pay_info.charge_id = charge.id  # 返金(refund)の時に使うchargeのIDをpay_infoに保存しておく
        pay_info.stripe_commission = (charge.amount * 0.036).round  # stripeの手数料(3.6%)分の金額
        pay_info.amount_after_subtract_commission = charge.amount - pay_info.stripe_commission  # stripeの手数料(3.6%)分を引いた金額(依頼者が払った96.4%の金額)
        pay_info.receipt_url = charge.receipt_url  # この決済に対するstripeが用意してくれる領収書のURL
        pay_info.save!
      #############################################################################

      redirect_to temporary_complete_path #仮払い完了画面へ

    # stripe関連でエラーが起こった場合
    rescue Stripe::CardError => e
    flash[:error] = "#決済(stripe)でエラーが発生しました。{e.message}"
    render :new

    # Invalid parameters were supplied to Stripe's API
    rescue Stripe::InvalidRequestError => e
      flash.now[:error] = "決済(stripe)でエラーが発生しました（InvalidRequestError）#{e.message}"
      render :new

    # Authentication with Stripe's API failed(maybe you changed API keys recently)
    rescue Stripe::AuthenticationError => e
      flash.now[:error] = "決済(stripe)でエラーが発生しました（AuthenticationError）#{e.message}"
      render :new

    # Network communication with Stripe failed
    rescue Stripe::APIConnectionError => e
      flash.now[:error] = "決済(stripe)でエラーが発生しました（APIConnectionError）#{e.message}"
      render :new

    # Display a very generic error to the user, and maybe send yourself an email
    rescue Stripe::StripeError => e
      flash.now[:error] = "決済(stripe)でエラーが発生しました（StripeError）#{e.message}"
      render :new

    # stripe関連以外でエラーが起こった場合
    rescue => e
      @posts = Post.all
      flash.now[:error] = "エラーが発生しました#{e.message}"
      render("posts/index")
    end
  end

  private
  def pay_info_params
    params.fetch(:pay_info, {}).permit(:email, :description, :currency, :customer_id, :payment_date, :payment_status, :uuid, :charge_id, :stripe_commission, :amount_after_subtract_commission, :receipt_url)
  end
  end
