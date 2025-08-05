# frozen_string_literal: true

# name: discourse-project-countdown
# about: 项目倒计时管理工具 - 帮助用户跟踪项目截止日期
# version: 1.0.0
# authors: Your Name
# url: https://github.com/your-username/discourse-project-countdown
# required_version: 3.0.0

enabled_site_setting :project_countdown_enabled

after_initialize do
  # 注册项目倒计时组件
  register_html_builder('project-countdown') do |theme|
    "window.ProjectCountdownEnabled = true;"
  end

  # 添加用户自定义字段来存储项目数据
  add_to_class(:user, :project_countdown_data) do
    custom_fields['project_countdown_data']
  end

  add_to_class(:user, :project_countdown_data=) do |value|
    custom_fields['project_countdown_data'] = value
    save_custom_fields
  end

  # 注册用户序列化器扩展
  add_to_serializer(:current_user, :project_countdown_data) do
    object.project_countdown_data
  end

  # API端点来处理项目数据
  Discourse::Application.routes.append do
    namespace :project_countdown, path: '/project-countdown' do
      get '/data' => 'data#get'
      post '/data' => 'data#save'
    end
  end

  # 控制器
  class ::ProjectCountdown::DataController < ::ApplicationController
    requires_login

    def get
      data = current_user.project_countdown_data
      if data.blank?
        render json: { projects: [] }
      else
        begin
          parsed_data = JSON.parse(data)
          render json: { projects: parsed_data }
        rescue JSON::ParserError
          render json: { projects: [] }
        end
      end
    end

    def save
      projects_data = params.require(:projects)

      # 验证数据格式
      unless projects_data.is_a?(Array)
        render json: { error: 'Invalid data format' }, status: 400
        return
      end

      # 保存数据
      current_user.project_countdown_data = projects_data.to_json

      if current_user.save
        render json: { success: true }
      else
        render json: { error: 'Failed to save data' }, status: 500
      end
    end
  end

  # 添加站点设置
  add_admin_route 'project_countdown.title', 'project-countdown'

  # 权限检查
  Guardian.class_eval do
    def can_use_project_countdown?
      return false unless authenticated?
      SiteSetting.project_countdown_enabled
    end
  end
end

# CSS和JS资源
register_asset "stylesheets/project-countdown.scss"
register_asset "javascripts/discourse/initializers/project-countdown.js"