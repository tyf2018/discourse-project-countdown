# frozen_string_literal: true

# name: discourse-project-countdown
# about: 项目倒计时管理工具 - 帮助用户跟踪项目截止日期
# version: 1.0.0
# authors: Your Name
# url: https://github.com/your-username/discourse-project-countdown
# required_version: 3.0.0

enabled_site_setting :project_countdown_enabled

after_initialize do
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

  # 定义模块
  module ::ProjectCountdown
  end

  # API端点来处理项目数据
  Discourse::Application.routes.append do
    namespace :project_countdown, path: '/project-countdown' do
      get '/data' => 'data#get'
      post '/data' => 'data#save'
    end

    # 添加页面路由
    get '/project-countdown' => 'project_countdown/index#index'
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

  # 页面控制器
  class ::ProjectCountdown::IndexController < ::ApplicationController
    requires_login

    def index
      render html: '
        <div style="font-family: var(--font-family); padding: 20px; max-width: 800px; margin: 0 auto;">
          <h2>项目倒计时</h2>
          <div id="project-countdown-app">
            <div style="text-align: center; padding: 40px;">
              <p>加载中...</p>
              <script>
                // 简单的项目管理应用
                let projects = [];

                function formatDate(date) {
                  const year = date.getFullYear();
                  const month = String(date.getMonth() + 1).padStart(2, "0");
                  const day = String(date.getDate()).padStart(2, "0");
                  return `${year}-${month}-${day}`;
                }

                function calculateDaysLeft(deadline) {
                  const today = new Date();
                  today.setHours(0, 0, 0, 0);
                  const deadlineDate = new Date(deadline);
                  deadlineDate.setHours(0, 0, 0, 0);
                  const diffTime = deadlineDate - today;
                  return Math.ceil(diffTime / (1000 * 60 * 60 * 24));
                }

                async function loadProjects() {
                  try {
                    const response = await fetch("/project-countdown/data");
                    const data = await response.json();
                    projects = data.projects || [];
                    renderProjects();
                  } catch (error) {
                    console.error("Failed to load projects:", error);
                  }
                }

                async function saveProjects() {
                  try {
                    await fetch("/project-countdown/data", {
                      method: "POST",
                      headers: { "Content-Type": "application/json" },
                      body: JSON.stringify({ projects: projects })
                    });
                  } catch (error) {
                    console.error("Failed to save projects:", error);
                  }
                }

                function addProject() {
                  const name = document.getElementById("project-name").value;
                  const deadline = document.getElementById("project-deadline").value;

                  if (!name.trim() || !deadline) {
                    alert("请输入项目名称和截止日期");
                    return;
                  }

                  projects.push({
                    id: Date.now(),
                    name: name.trim(),
                    deadline: deadline,
                    isImportant: false
                  });

                  document.getElementById("project-name").value = "";
                  document.getElementById("project-deadline").value = formatDate(new Date());

                  saveProjects();
                  renderProjects();
                }

                function deleteProject(index) {
                  if (!confirm("确定要删除这个项目吗？")) return;
                  projects.splice(index, 1);
                  saveProjects();
                  renderProjects();
                }

                function renderProjects() {
                  let html = `
                    <div style="margin-bottom: 20px; padding: 15px; background: #f5f5f5; border-radius: 5px;">
                      <input type="text" id="project-name" placeholder="项目名称" style="margin-right: 10px; padding: 8px; border: 1px solid #ddd; border-radius: 3px;">
                      <input type="date" id="project-deadline" value="${formatDate(new Date())}" style="margin-right: 10px; padding: 8px; border: 1px solid #ddd; border-radius: 3px;">
                      <button onclick="addProject()" style="padding: 8px 16px; background: #0088cc; color: white; border: none; border-radius: 3px; cursor: pointer;">添加项目</button>
                    </div>
                    <div style="display: grid; gap: 10px;">
                  `;

                  if (projects.length === 0) {
                    html += "<div style=\"text-align: center; padding: 20px; color: #666;\">暂无项目，请添加新项目</div>";
                  } else {
                    projects.forEach((project, index) => {
                      const daysLeft = calculateDaysLeft(project.deadline);
                      let statusColor = "#52c41a";
                      let statusText = "正常";

                      if (daysLeft < 0) { statusColor = "#ff4d4f"; statusText = "已过期"; }
                      else if (daysLeft <= 3) { statusColor = "#ff7a45"; statusText = "紧急"; }
                      else if (daysLeft <= 7) { statusColor = "#ffa940"; statusText = "警告"; }
                      else if (daysLeft <= 14) { statusColor = "#ffec3d"; statusText = "注意"; }

                      const daysText = daysLeft < 0 ? `已过期 ${Math.abs(daysLeft)} 天` :
                                      daysLeft === 0 ? "今天截止 ❗❗" : `剩 ${daysLeft} 天`;

                      html += `
                        <div style="border-left: 4px solid ${statusColor}; padding: 15px; background: white; border-radius: 5px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
                          <div style="display: flex; justify-content: space-between; align-items: center;">
                            <div>
                              <div style="font-weight: bold; margin-bottom: 5px;">
                                ${project.name}
                                <span style="background: ${statusColor}; color: white; padding: 2px 6px; border-radius: 10px; font-size: 12px; margin-left: 8px;">${statusText}</span>
                              </div>
                              <div style="color: #666; font-size: 14px;">截止: ${project.deadline}</div>
                            </div>
                            <div style="text-align: right;">
                              <div style="color: ${statusColor}; font-weight: bold; margin-bottom: 5px;">${daysText}</div>
                              <button onclick="deleteProject(${index})" style="background: transparent; border: none; color: #666; cursor: pointer; text-decoration: underline;">删除</button>
                            </div>
                          </div>
                        </div>
                      `;
                    });
                  }

                  html += `
                    </div>
                    <div style="margin-top: 20px; text-align: center; color: #666; font-size: 12px;">
                      项目倒计时 v1.0 - Discourse版
                    </div>
                  `;

                  document.getElementById("project-countdown-app").innerHTML = html;
                }

                // 页面加载完成后初始化
                document.addEventListener("DOMContentLoaded", function() {
                  loadProjects();
                });
              </script>
            </div>
          </div>
        </div>
      '.html_safe
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

# 资源文件会自动加载，无需手动注册