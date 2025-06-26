class MembersController < ApplicationController
  before_action :auth_member!
  before_action :auth_no_initial!

  def edit
    @member = current_user
  end

  def update
    @member = current_user

    if @member.update_attributes(member_params)
      redirect_to forum_path
    else
      render :edit
    end
  end

  private
  def member_params
    params.required(:member).permit(:first_name, :last_name)
  end
end
