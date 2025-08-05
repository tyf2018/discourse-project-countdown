# frozen_string_literal: true

# name: discourse-project-countdown
# about: 项目倒计时管理工具 - 帮助用户跟踪项目截止日期
# version: 1.0.0
# authors: Your Name
# url: https://github.com/your-username/discourse-project-countdown
# required_version: 3.0.0

enabled_site_setting :project_countdown_enabled

after_initialize do
  # 定义模块
  module ::ProjectCountdown
  end

  # 添加用户自定义字段来存储项目数据
  add_to_class(:user, :project_countdown_data) do
    custom_fields['project_countdown_data']
  end

  add_to_class(:user, :project_countdown_data=) do |value|
    custom_fields['project_countdown_data'] = value
    save_custom_fields
  end

  # API端点来处理项目数据
  Discourse::Application.routes.append do
    get '/project-countdown' => 'project_countdown#index'
    get '/project-countdown/data' => 'project_countdown#get_data'
    post '/project-countdown/data' => 'project_countdown#save_data'
  end

  # 主控制器
  class ::ProjectCountdownController < ::ApplicationController
    requires_login

    def index
      render html: build_html_page.html_safe
    end

    def get_data
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

    def save_data
      projects_data = params.require(:projects)

      unless projects_data.is_a?(Array)
        render json: { error: 'Invalid data format' }, status: 400
        return
      end

      current_user.project_countdown_data = projects_data.to_json

      if current_user.save
        render json: { success: true }
      else
        render json: { error: 'Failed to save data' }, status: 500
      end
    end

    private

    def build_html_page
      <<~HTML
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>项目倒计时</title>
          <style>
            body { font-family: var(--font-family), Arial, sans-serif; margin: 0; padding: 20px; background: var(--secondary, #f8f9fa); }
            .container { max-width: 800px; margin: 0 auto; background: var(--primary-very-low, white); padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
            h2 { color: var(--primary, #333); margin-bottom: 20px; }
            .form-group { margin-bottom: 15px; padding: 15px; background: #f5f5f5; border-radius: 5px; }
            input, button { padding: 8px; margin: 5px; border: 1px solid #ddd; border-radius: 4px; }
            input[type="text"] { width: 200px; }
            input[type="date"] { width: 150px; }
            button { background: #0088cc; color: white; border: none; cursor: pointer; padding: 8px 16px; }
            button:hover { background: #0066aa; }
            .project-card { margin: 10px 0; padding: 15px; background: white; border-radius: 5px; border-left: 4px solid; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
            .project-header { font-weight: bold; margin-bottom: 5px; }
            .project-footer { display: flex; justify-content: space-between; align-items: center; }
            .status-badge { padding: 2px 6px; border-radius: 10px; color: white; font-size: 12px; margin-left: 8px; }
            .delete-btn { background: transparent; border: none; color: #666; cursor: pointer; text-decoration: underline; }
            .loading { text-align: center; padding: 20px; }
            .no-projects { text-align: center; padding: 20px; color: #666; }
          </style>
        </head>
        <body>
          <div class="container">
            <h2>项目倒计时</h2>

            <div class="form-group">
              <input type="text" id="projectName" placeholder="项目名称" />
              <input type="date" id="projectDeadline" />
              <button onclick="addProject()">添加项目</button>
            </div>

            <div id="projectsList" class="loading">加载中...</div>

            <div style="margin-top: 20px; text-align: center; color: #666; font-size: 12px;">
              项目倒计时 v1.0 - Discourse版
            </div>
          </div>

          <script>
            let projects = [];

            function formatDate(date) {
              const year = date.getFullYear();
              const month = String(date.getMonth() + 1).padStart(2, '0');
              const day = String(date.getDate()).padStart(2, '0');
              return year + '-' + month + '-' + day;
            }

            function calculateDaysLeft(deadline) {
              const today = new Date();
              today.setHours(0, 0, 0, 0);
              const deadlineDate = new Date(deadline);
              deadlineDate.setHours(0, 0, 0, 0);
              const diffTime = deadlineDate - today;
              return Math.ceil(diffTime / (1000 * 60 * 60 * 24));
            }

            function getStatusColor(daysLeft) {
              if (daysLeft < 0) return '#ff4d4f';
              if (daysLeft <= 3) return '#ff7a45';
              if (daysLeft <= 7) return '#ffa940';
              if (daysLeft <= 14) return '#ffec3d';
              return '#52c41a';
            }

            function getStatusText(daysLeft) {
              if (daysLeft < 0) return '已过期';
              if (daysLeft <= 3) return '紧急';
              if (daysLeft <= 7) return '警告';
              if (daysLeft <= 14) return '注意';
              return '正常';
            }

            async function loadProjects() {
              try {
                const response = await fetch('/project-countdown/data');
                const data = await response.json();
                projects = data.projects || [];
                renderProjects();
              } catch (error) {
                console.error('Failed to load projects:', error);
                document.getElementById('projectsList').innerHTML = '<div class="no-projects">加载失败</div>';
              }
            }

            async function saveProjects() {
              try {
                const response = await fetch('/project-countdown/data', {
                  method: 'POST',
                  headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.getAttribute('content') || ''
                  },
                  body: JSON.stringify({ projects: projects })
                });

                if (!response.ok) {
                  throw new Error('Failed to save');
                }
              } catch (error) {
                console.error('Failed to save projects:', error);
                alert('保存失败，请重试');
              }
            }

            function addProject() {
              const name = document.getElementById('projectName').value.trim();
              const deadline = document.getElementById('projectDeadline').value;

              if (!name || !deadline) {
                alert('请输入项目名称和截止日期');
                return;
              }

              projects.push({
                id: Date.now(),
                name: name,
                deadline: deadline,
                isImportant: false
              });

              document.getElementById('projectName').value = '';
              document.getElementById('projectDeadline').value = '';

              saveProjects();
              renderProjects();
            }

            function deleteProject(index) {
              if (!confirm('确定要删除这个项目吗？')) return;
              projects.splice(index, 1);
              saveProjects();
              renderProjects();
            }

            function renderProjects() {
              const container = document.getElementById('projectsList');

              if (projects.length === 0) {
                container.innerHTML = '<div class="no-projects">暂无项目，请添加新项目</div>';
                return;
              }

              let html = '';

              projects.forEach((project, index) => {
                const daysLeft = calculateDaysLeft(project.deadline);
                const statusColor = getStatusColor(daysLeft);
                const statusText = getStatusText(daysLeft);

                const daysText = daysLeft < 0 ?
                  '已过期 ' + Math.abs(daysLeft) + ' 天' :
                  (daysLeft === 0 ? '今天截止 ❗❗' : '剩 ' + daysLeft + ' 天');

                html += '<div class="project-card" style="border-left-color: ' + statusColor + '">';
                html += '  <div class="project-header">';
                html += '    ' + project.name;
                html += '    <span class="status-badge" style="background: ' + statusColor + '">' + statusText + '</span>';
                html += '  </div>';
                html += '  <div class="project-footer">';
                html += '    <span>截止: ' + project.deadline + '</span>';
                html += '    <div>';
                html += '      <span style="color: ' + statusColor + '; font-weight: bold; margin-right: 10px;">' + daysText + '</span>';
                html += '      <button class="delete-btn" onclick="deleteProject(' + index + ')">删除</button>';
                html += '    </div>';
                html += '  </div>';
                html += '</div>';
              });

              container.innerHTML = html;
            }

            // 设置默认日期
            document.getElementById('projectDeadline').value = formatDate(new Date());

            // 加载项目
            loadProjects();
          </script>
        </body>
        </html>
      HTML
    end
  end

  # 权限检查
  Guardian.class_eval do
    def can_use_project_countdown?
      return false unless authenticated?
      SiteSetting.project_countdown_enabled
    end
  end
end