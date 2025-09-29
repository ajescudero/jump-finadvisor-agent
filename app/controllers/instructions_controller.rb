class InstructionsController < ApplicationController
  protect_from_forgery with: :null_session

  def create
    user_id = instr_params[:user_id]
    Instruction.where(user_id: user_id, is_active: true).update_all(is_active: false)
    i = Instruction.create!(instr_params.merge(is_active: true))
    render json: { id: i.id, is_active: i.is_active }
  rescue => ex
    render json: { error: ex.message }, status: 422
  end

  def update
    i = Instruction.find(params[:id])
    if params.key?(:is_active) && ActiveModel::Type::Boolean.new.cast(params[:is_active])
      Instruction.where(user_id: i.user_id, is_active: true).where.not(id: i.id).update_all(is_active: false)
      i.is_active = true
    end
    i.content = params[:content] if params.key?(:content)
    i.save!
    render json: { id: i.id, is_active: i.is_active }
  rescue => ex
    render json: { error: ex.message }, status: 422
  end

  private

  def instr_params
    params.require(:instruction).permit(:user_id, :content)
  end
end
