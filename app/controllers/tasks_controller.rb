class TasksController < ApplicationController
  protect_from_forgery with: :null_session

  def create
    t = Task.create!(task_params)
    render json: { id: t.id, status: t.status }
  rescue => ex
    render json: { error: ex.message }, status: 422
  end

  def update
    t = Task.find(params[:id])
    t.update!(task_params)
    render json: { id: t.id, status: t.status }
  rescue => ex
    render json: { error: ex.message }, status: 422
  end

  def show
    t = Task.find(params[:id])
    render json: t.as_json
  end

  def index
    render json: Task.where(filter_params).order(id: :desc).as_json
  end

  private

  def task_params
    params.require(:task).permit(:user_id, :title, :payload, :status)
  end

  def filter_params
    params.permit(:user_id, :status)
  end
end
