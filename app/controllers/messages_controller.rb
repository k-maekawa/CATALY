class MessagesController < ApplicationController
  before_action :authenticate_user!, only: [:create]

  def create
    if Entry.where(user_id: current_user.id, room_id: params[:message][:room_id]).present?
      @message = Message.create(params.require(:message).permit(:user_id, :content,
                                                                :room_id).merge(user_id: current_user.id))
      redirect_to "/rooms/#{@message.room_id}#final"
      @message.create_notification_message!(current_user, @message.id)

      @room = @message.room
      # ここまでを追加
      if @message.save
        # ここから
        @roommembernotme = Entry.where(room_id: @room.id).where.not(user_id: current_user.id)
        @theid = @roommembernotme.find_by(room_id: @room.id)
        notification = current_user.active_notifications.new(
          room_id: @room.id,
          message_id: @message.id,
          visited_id: @theid.user_id,
          visitor_id: current_user.id,
          action: 'dm'
        )

        @user = notification.visited

        if @user.send_mail
        # メッセージを送った際にメールで伝える。
         NotificationMailer.send_mail(notification.visited).deliver_now
       end

        # 自分の投稿に対するコメントの場合は、通知済みとする
        notification.checked = true if notification.visitor_id == notification.visited_id
        notification.save if notification.valid?
        # ここまでを追加

        # redirect_to "/rooms/#{@message.room_id}"
      end

    else
      redirect_back(fallback_location: root_path)
    end
  end

  private

  def message_params
    params.require(:message).permit(:user_id, :body, :room_id).merge(user_id: current_user.id)
  end
end
