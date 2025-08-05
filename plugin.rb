# frozen_string_literal: true

# name: discourse-project-countdown
# about: 项目倒计时管理工具，帮助用户跟踪项目截止日期
# version: 1.1.0
# authors: Your Name
# url: https://github.com/tyf2018/discourse-project-countdown
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

  # 主控制器
  class ::ProjectCountdownController < ::ApplicationController
    requires_login

    def index
      Rails.logger.info "[ProjectCountdown] 用户 #{current_user&.username} 正在访问项目倒计时页面"

      unless SiteSetting.project_countdown_enabled
        render html: error_page("插件未启用", "请联系管理员在后台启用项目倒计时插件").html_safe
        return
      end

      render html: build_html_page.html_safe
    rescue => e
      Rails.logger.error "[ProjectCountdown] 渲染页面时出错: #{e.message}"
      render html: error_page("加载失败", "请刷新页面重试，或联系管理员").html_safe
    end

    def test
      render html: test_page.html_safe
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

    def test_page
      <<~HTML
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <title>项目倒计时 - 插件测试</title>
          <style>
            body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
            .container { max-width: 800px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; }
            .status { padding: 10px; margin: 10px 0; border-radius: 4px; }
            .success { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
            .info { background: #d1ecf1; color: #0c5460; border: 1px solid #bee5eb; }
            .warning { background: #fff3cd; color: #856404; border: 1px solid #ffeaa7; }
            .error { background: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; }
            pre { background: #f8f9fa; padding: 10px; border-radius: 4px; overflow-x: auto; }
            .btn { display: inline-block; padding: 10px 20px; background: #007bff; color: white; text-decoration: none; border-radius: 4px; margin: 5px; }
            .btn:hover { background: #0056b3; }
          </style>
        </head>
        <body>
          <div class="container">
            <h1>🔧 项目倒计时插件 - 安装测试</h1>

            <div class="status success">
              ✅ <strong>路由测试通过</strong> - 插件已成功加载并响应请求
            </div>

            <div class="status info">
              <strong>插件信息:</strong><br>
              • 版本: 1.0.0 完整版<br>
              • 安装时间: #{Time.current}<br>
              • 当前用户: #{current_user&.username || '未登录'}<br>
              • 用户ID: #{current_user&.id || 'N/A'}
            </div>

            <div class="status #{SiteSetting.project_countdown_enabled ? 'success' : 'error'}">
              #{SiteSetting.project_countdown_enabled ? '✅' : '❌'}
              <strong>插件设置:</strong> #{SiteSetting.project_countdown_enabled ? '已启用' : '未启用'}
              #{unless SiteSetting.project_countdown_enabled
                '<br><em>请在管理后台启用插件: 设置 → 搜索 "project_countdown_enabled" → 设置为true</em>'
              end}
            </div>

            <div class="status info">
              <strong>✅ 完整功能列表:</strong><br>
              • 📝 项目增删改功能<br>
              • 🔄 倒计时实时计算<br>
              • 🏷️ 重要项目标记<br>
              • 🔧 编辑模式<br>
              • 📊 5种排序方式<br>
              • 🔍 文本筛选<br>
              • ⭐ 重要项目筛选<br>
              • 📋 分类显示（活跃/已过期）<br>
              • 💾 永久数据存储
            </div>

            <div style="text-align: center; margin-top: 30px;">
              <a href="/project-countdown" class="btn">🚀 进入项目倒计时</a>
              <a href="/admin" class="btn">⚙️ 管理后台</a>
              <a href="/" class="btn">🏠 返回首页</a>
            </div>
          </div>
        </body>
        </html>
      HTML
    end

    def error_page(title, message)
      <<~HTML
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>#{title} - 项目倒计时</title>
          <style>
            body { font-family: var(--font-family), Arial, sans-serif; margin: 0; padding: 20px; background: var(--secondary, #f8f9fa); }
            .container { max-width: 600px; margin: 50px auto; background: var(--primary-very-low, white); padding: 40px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); text-align: center; }
            .error-icon { font-size: 48px; margin-bottom: 20px; }
            h2 { color: #ff4d4f; margin-bottom: 15px; }
            p { color: #666; line-height: 1.6; margin-bottom: 30px; }
            .btn { display: inline-block; padding: 12px 24px; background: #0088cc; color: white; text-decoration: none; border-radius: 4px; margin: 5px; }
            .btn:hover { background: #0066aa; }
            .debug-info { margin-top: 30px; padding: 15px; background: #f5f5f5; border-radius: 4px; font-size: 12px; color: #666; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="error-icon">❌</div>
            <h2>#{title}</h2>
            <p>#{message}</p>
            <a href="/" class="btn">返回首页</a>
            <a href="/admin" class="btn">管理后台</a>
            <div class="debug-info">
              <strong>调试信息:</strong><br>
              访问路径: /project-countdown<br>
              时间: #{Time.current}<br>
              用户: #{current_user&.username || '未登录'}
            </div>
          </div>
        </body>
        </html>
      HTML
    end

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
            .container { max-width: 1000px; margin: 0 auto; background: var(--primary-very-low, white); padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
            h2 { color: var(--primary, #333); margin-bottom: 20px; }

            /* 头部控制区 */
            .header-controls { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; padding-bottom: 15px; border-bottom: 1px solid #ddd; }
            .sort-controls { position: relative; }
            .sort-button { background: #f5f5f5; border: 1px solid #ddd; padding: 8px 12px; border-radius: 4px; cursor: pointer; font-size: 14px; }
            .sort-menu { position: absolute; top: 100%; left: 0; background: white; border: 1px solid #ddd; border-radius: 4px; box-shadow: 0 4px 12px rgba(0,0,0,0.15); min-width: 160px; z-index: 1000; display: none; }
            .sort-menu.show { display: block; }
            .sort-option { padding: 8px 12px; cursor: pointer; font-size: 14px; }
            .sort-option:hover { background: #f5f5f5; }
            .sort-option.active { background: #e6f7ff; color: #1890ff; }

            .filter-controls { display: flex; align-items: center; gap: 10px; }
            .filter-input { padding: 8px; border: 1px solid #ddd; border-radius: 4px; width: 200px; }
            .important-filter { display: flex; align-items: center; gap: 5px; }

            /* 表单区域 */
            .form-group { margin-bottom: 20px; padding: 15px; background: #f5f5f5; border-radius: 5px; }
            .form-row { display: flex; gap: 10px; align-items: center; flex-wrap: wrap; }
            input, button { padding: 8px; margin: 5px; border: 1px solid #ddd; border-radius: 4px; }
            input[type="text"] { flex: 1; min-width: 200px; }
            input[type="date"] { width: 150px; }
            button { background: #0088cc; color: white; border: none; cursor: pointer; padding: 8px 16px; }
            button:hover { background: #0066aa; }
            button.secondary { background: #6c757d; }
            button.secondary:hover { background: #545b62; }

            .important-checkbox { display: flex; align-items: center; gap: 5px; }

            /* 项目卡片 */
            .projects-section { margin-bottom: 30px; }
            .section-title { font-size: 18px; font-weight: bold; margin-bottom: 15px; padding-bottom: 8px; border-bottom: 2px solid #ddd; }
            .expired-title { color: #ff4d4f; border-bottom-color: #ff4d4f; }

            .projects-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(400px, 1fr)); gap: 15px; }
            .project-card { padding: 15px; background: white; border-radius: 5px; border-left: 4px solid; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
            .project-header { font-weight: bold; margin-bottom: 8px; display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }
            .project-footer { display: flex; justify-content: space-between; align-items: center; }
            .status-badge { padding: 2px 8px; border-radius: 12px; color: white; font-size: 12px; font-weight: bold; }
            .important-badge { background: #ff6b35; }
            .project-actions { display: flex; gap: 8px; }
            .action-btn { background: transparent; border: none; color: #666; cursor: pointer; text-decoration: underline; padding: 4px 8px; font-size: 13px; }
            .action-btn:hover { color: #333; }

            .loading { text-align: center; padding: 20px; }
            .no-projects { text-align: center; padding: 40px; color: #666; }
            .expired-container { background: rgba(255, 77, 79, 0.05); border-radius: 8px; padding: 15px; }

            @media (max-width: 768px) {
              .projects-grid { grid-template-columns: 1fr; }
              .header-controls { flex-direction: column; gap: 15px; align-items: stretch; }
              .filter-controls { flex-direction: column; gap: 10px; }
              .form-row { flex-direction: column; align-items: stretch; }
            }
          </style>
        </head>
        <body>
          <div class="container">
            <h2>项目倒计时 - 完整版</h2>

            <!-- 头部控制区 -->
            <div class="header-controls">
              <div class="sort-controls">
                <button class="sort-button" onclick="toggleSortMenu()">
                  <span id="sortLabel">按剩余天数排序</span> ▼
                </button>
                <div class="sort-menu" id="sortMenu">
                  <div class="sort-option active" onclick="setSortType('daysLeft', '按剩余天数排序')">按剩余天数</div>
                  <div class="sort-option" onclick="setSortType('nameAsc', '项目名称(A-Z)')">项目名称(A-Z)</div>
                  <div class="sort-option" onclick="setSortType('nameDesc', '项目名称(Z-A)')">项目名称(Z-A)</div>
                  <div class="sort-option" onclick="setSortType('dateAsc', '截止日期(近-远)')">截止日期(近-远)</div>
                  <div class="sort-option" onclick="setSortType('dateDesc', '截止日期(远-近)')">截止日期(远-近)</div>
                </div>
              </div>

              <div class="filter-controls">
                <input type="text" class="filter-input" id="filterText" placeholder="筛选项目（多关键词用空格分隔）" onkeyup="applyFilters()" />
                <label class="important-filter">
                  <input type="checkbox" id="showImportantOnly" onchange="applyFilters()" />
                  仅显示重要项目
                </label>
              </div>
            </div>

            <!-- 项目表单 -->
            <div class="form-group">
              <div class="form-row">
                <input type="text" id="projectName" placeholder="项目名称" />
                <input type="date" id="projectDeadline" />
                <label class="important-checkbox">
                  <input type="checkbox" id="projectImportant" />
                  重要项目
                </label>
                <button onclick="addProject()" id="submitBtn">添加项目</button>
                <button onclick="cancelEdit()" id="cancelBtn" class="secondary" style="display: none;">取消</button>
              </div>
            </div>

            <!-- 项目列表 -->
            <div id="projectsList" class="loading">加载中...</div>

            <div style="margin-top: 20px; text-align: center; color: #666; font-size: 12px;">
              项目倒计时 v1.0 完整版 - Discourse版 | 数据永久存储
            </div>
          </div>

          <script>
            let projects = [];
            let editMode = false;
            let editIndex = -1;
            let sortType = 'daysLeft';
            let filterText = '';
            let showImportantOnly = false;

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

            // 排序功能
            function sortProjects(projectList) {
              return [...projectList].sort((a, b) => {
                switch (sortType) {
                  case 'nameAsc':
                    return a.name.localeCompare(b.name);
                  case 'nameDesc':
                    return b.name.localeCompare(a.name);
                  case 'dateAsc':
                    return new Date(a.deadline) - new Date(b.deadline);
                  case 'dateDesc':
                    return new Date(b.deadline) - new Date(a.deadline);
                  case 'daysLeft':
                  default:
                    const daysLeftA = calculateDaysLeft(a.deadline);
                    const daysLeftB = calculateDaysLeft(b.deadline);
                    return daysLeftA - daysLeftB;
                }
              });
            }

            // 筛选功能
            function filterProjects(projectList) {
              let filtered = projectList;

              // 重要项目筛选
              if (showImportantOnly) {
                filtered = filtered.filter(project => project.isImportant === true);
              }

              // 文本筛选
              if (filterText.trim()) {
                const keywords = filterText.trim().split(/\s+/);
                filtered = filtered.filter(project => {
                  const projectName = project.name.toLowerCase();
                  return keywords.every(keyword =>
                    projectName.includes(keyword.toLowerCase())
                  );
                });
              }

              return filtered;
            }

            function toggleSortMenu() {
              document.getElementById('sortMenu').classList.toggle('show');
            }

            function setSortType(type, label) {
              sortType = type;
              document.getElementById('sortLabel').textContent = label;
              document.getElementById('sortMenu').classList.remove('show');

              // 更新选中状态
              document.querySelectorAll('.sort-option').forEach(option => {
                option.classList.remove('active');
              });
              event.target.classList.add('active');

              renderProjects();
            }

            function applyFilters() {
              filterText = document.getElementById('filterText').value;
              showImportantOnly = document.getElementById('showImportantOnly').checked;
              renderProjects();
            }

            // 点击外部关闭排序菜单
            document.addEventListener('click', function(event) {
              if (!event.target.closest('.sort-controls')) {
                document.getElementById('sortMenu').classList.remove('show');
              }
            });

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
              const isImportant = document.getElementById('projectImportant').checked;

              if (!name || !deadline) {
                alert('请输入项目名称和截止日期');
                return;
              }

              if (editMode) {
                // 编辑模式
                projects[editIndex] = {
                  ...projects[editIndex],
                  name: name,
                  deadline: deadline,
                  isImportant: isImportant
                };
                exitEditMode();
              } else {
                // 添加模式
                projects.push({
                  id: Date.now(),
                  name: name,
                  deadline: deadline,
                  isImportant: isImportant
                });
              }

              document.getElementById('projectName').value = '';
              document.getElementById('projectDeadline').value = formatDate(new Date());
              document.getElementById('projectImportant').checked = false;

              saveProjects();
              renderProjects();
            }

            function editProject(index) {
              const project = projects[index];
              editMode = true;
              editIndex = index;

              document.getElementById('projectName').value = project.name;
              document.getElementById('projectDeadline').value = project.deadline;
              document.getElementById('projectImportant').checked = project.isImportant || false;

              document.getElementById('submitBtn').textContent = '保存修改';
              document.getElementById('cancelBtn').style.display = 'inline-block';
            }

            function cancelEdit() {
              exitEditMode();
              document.getElementById('projectName').value = '';
              document.getElementById('projectDeadline').value = formatDate(new Date());
              document.getElementById('projectImportant').checked = false;
            }

            function exitEditMode() {
              editMode = false;
              editIndex = -1;
              document.getElementById('submitBtn').textContent = '添加项目';
              document.getElementById('cancelBtn').style.display = 'none';
            }

            function deleteProject(index) {
              if (!confirm('确定要删除这个项目吗？')) return;
              projects.splice(index, 1);
              if (editMode && editIndex === index) {
                cancelEdit();
              }
              saveProjects();
              renderProjects();
            }

            function renderProjects() {
              const container = document.getElementById('projectsList');

              // 先筛选，再排序
              const filteredProjects = filterProjects(projects);
              const sortedProjects = sortProjects(filteredProjects);

              // 分离活跃和已过期项目
              const activeProjects = sortedProjects.filter(project => calculateDaysLeft(project.deadline) >= 0);
              const expiredProjects = sortedProjects.filter(project => calculateDaysLeft(project.deadline) < 0);

              if (sortedProjects.length === 0) {
                container.innerHTML = '<div class="no-projects">暂无项目，请添加新项目或调整筛选条件</div>';
                return;
              }

              let html = '';

              // 活跃项目
              if (activeProjects.length > 0) {
                html += '<div class="projects-section">';
                html += '<div class="section-title">进行中的项目</div>';
                html += '<div class="projects-grid">';

                activeProjects.forEach((project, index) => {
                  const originalIndex = projects.indexOf(project);
                  const daysLeft = calculateDaysLeft(project.deadline);
                  const statusColor = getStatusColor(daysLeft);
                  const statusText = getStatusText(daysLeft);

                  const daysDisplay = daysLeft === 0 ? '今天截止 ❗❗' : `剩 ${daysLeft} 天`;

                  html += `<div class="project-card" style="border-left-color: ${statusColor}">`;
                  html += '  <div class="project-header">';
                  html += `    <span>${project.name}</span>`;
                  if (project.isImportant) {
                    html += '<span class="status-badge important-badge">重要</span>';
                  }
                  html += `    <span class="status-badge" style="background: ${statusColor}">${statusText}</span>`;
                  html += '  </div>';
                  html += '  <div class="project-footer">';
                  html += `    <span>截止: ${project.deadline}</span>`;
                  html += '    <div>';
                  html += `      <span style="color: ${statusColor}; font-weight: bold; margin-right: 15px;">${daysDisplay}</span>`;
                  html += '      <div class="project-actions">';
                  html += `        <button class="action-btn" onclick="editProject(${originalIndex})">编辑</button>`;
                  html += `        <button class="action-btn" onclick="deleteProject(${originalIndex})">删除</button>`;
                  html += '      </div>';
                  html += '    </div>';
                  html += '  </div>';
                  html += '</div>';
                });

                html += '</div></div>';
              }

              // 已过期项目
              if (expiredProjects.length > 0) {
                html += '<div class="projects-section">';
                html += '<div class="section-title expired-title">已过期项目</div>';
                html += '<div class="expired-container">';
                html += '<div class="projects-grid">';

                expiredProjects.forEach((project, index) => {
                  const originalIndex = projects.indexOf(project);
                  const daysLeft = calculateDaysLeft(project.deadline);
                  const daysOverdue = Math.abs(daysLeft);

                  html += '<div class="project-card" style="border-left-color: #ff4d4f">';
                  html += '  <div class="project-header">';
                  html += `    <span>${project.name}</span>`;
                  if (project.isImportant) {
                    html += '<span class="status-badge important-badge">重要</span>';
                  }
                  html += '    <span class="status-badge" style="background: #ff4d4f">已过期</span>';
                  html += '  </div>';
                  html += '  <div class="project-footer">';
                  html += `    <span>截止: ${project.deadline}</span>`;
                  html += '    <div>';
                  html += `      <span style="color: #ff4d4f; font-weight: bold; margin-right: 15px;">已过期 ${daysOverdue} 天</span>`;
                  html += '      <div class="project-actions">';
                  html += `        <button class="action-btn" onclick="editProject(${originalIndex})">编辑</button>`;
                  html += `        <button class="action-btn" onclick="deleteProject(${originalIndex})">删除</button>`;
                  html += '      </div>';
                  html += '    </div>';
                  html += '  </div>';
                  html += '</div>';
                });

                html += '</div></div></div>';
              }

              container.innerHTML = html;
            }

            // 初始化
            document.getElementById('projectDeadline').value = formatDate(new Date());
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

  # 路由配置
  Discourse::Application.routes.append do
    get "/project-countdown" => "project_countdown#index"
    get "/project-countdown/" => "project_countdown#index"
    get "/project-countdown/test" => "project_countdown#test"
    get "/project-countdown/data" => "project_countdown#get_data"
    post "/project-countdown/data" => "project_countdown#save_data"
  end

end