# app/controllers/activity_logs_controller.rb
class ActivityLogsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_super_admin!
  
  def index
    @activity_logs = ActivityLog.includes(:user)
                                .order(created_at: :desc)
    
    # Apply filters
    if params[:action_type].present?
      @activity_logs = @activity_logs.by_action(params[:action_type])
    end
    
    if params[:user_id].present?
      @activity_logs = @activity_logs.by_user(params[:user_id])
    end
    
    if params[:resource_type].present?
      @activity_logs = @activity_logs.where(resource_type: params[:resource_type])
    end
    
    if params[:start_date].present?
      @activity_logs = @activity_logs.where("created_at >= ?", params[:start_date])
    end
    
    if params[:end_date].present?
      @activity_logs = @activity_logs.where("created_at <= ?", params[:end_date])
    end
    
    if params[:search].present?
      @activity_logs = @activity_logs.search_by_details(params[:search])
    end
    
    @activity_logs = @activity_logs.paginate(page: params[:page], per_page: 50)
    
    # Stats for filters
    @action_types = ActivityLog::ACTION_TYPES
    @users = User.all.order(:name)
    @resource_types = ActivityLog.distinct.pluck(:resource_type).sort
  end
  
  def show
    @activity_log = ActivityLog.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to activity_logs_path, alert: 'Activity log not found.'
  end
  
  def export
    @activity_logs = ActivityLog.includes(:user)
                                .order(created_at: :desc)
    
    # Apply same filters as index
    if params[:action_type].present?
      @activity_logs = @activity_logs.by_action(params[:action_type])
    end
    
    if params[:user_id].present?
      @activity_logs = @activity_logs.by_user(params[:user_id])
    end
    
    if params[:resource_type].present?
      @activity_logs = @activity_logs.where(resource_type: params[:resource_type])
    end
    
    if params[:start_date].present?
      @activity_logs = @activity_logs.where("created_at >= ?", params[:start_date])
    end
    
    if params[:end_date].present?
      @activity_logs = @activity_logs.where("created_at <= ?", params[:end_date])
    end
    
    if params[:search].present?
      @activity_logs = @activity_logs.search_by_details(params[:search])
    end
    
    respond_to do |format|
      format.csv do
        send_data generate_csv, filename: "activity_logs_#{Date.current.strftime('%Y%m%d')}.csv"
      end
    end
  end
  
  private
  
  def generate_csv
    CSV.generate(headers: true) do |csv|
      csv << ["Date", "User", "Action", "Resource Type", "Resource ID", "Details", "IP Address", "User Agent"]
      
      @activity_logs.each do |log|
        csv << [
          log.display_time,
          log.user_name,
          log.action_name,
          log.resource_type,
          log.resource_id,
          log.details,
          log.ip_address,
          log.user_agent
        ]
      end
    end
  end
end