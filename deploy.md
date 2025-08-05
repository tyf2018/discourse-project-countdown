# 快速部署指南

## 一键部署到GitHub

### 1. 创建GitHub仓库

```bash
# 在GitHub上创建新仓库: discourse-project-countdown
# 然后在本地执行以下命令：

git init
git add .
git commit -m "Initial commit: Discourse项目倒计时插件v1.0.0"
git branch -M main
git remote add origin https://github.com/your-username/discourse-project-countdown.git
git push -u origin main
```

### 2. 在Discourse中安装

#### 方法A: 通过管理界面（推荐）
1. 登录Discourse管理后台
2. 进入 **管理 → 插件**
3. 点击"安装插件"
4. 输入仓库地址：`https://github.com/your-username/discourse-project-countdown.git`
5. 点击"安装"
6. 等待安装完成后重启

#### 方法B: 通过app.yml配置
编辑 `/var/discourse/containers/app.yml`，在hooks部分添加：

```yaml
hooks:
  after_code:
    - exec:
        cd: $home/plugins
        cmd:
          - git clone https://github.com/your-username/discourse-project-countdown.git
```

然后重建容器：
```bash
cd /var/discourse
./launcher rebuild app
```

## 验证部署

### 检查插件状态
```bash
# 检查插件是否正确安装
docker exec -it app ls -la /var/www/discourse/plugins/ | grep countdown

# 检查日志
docker exec -it app tail -f /var/www/discourse/log/production.log
```

### 功能测试
1. 访问 `https://your-forum.com/project-countdown`
2. 尝试添加测试项目
3. 检查数据是否正确保存

## 更新插件

```bash
# 方法1: 通过Git更新
cd /var/discourse/shared/standalone/app/plugins/discourse-project-countdown
git pull origin main

# 方法2: 重新安装
cd /var/discourse
./launcher rebuild app
```

## 自定义配置

### 修改默认设置
在Discourse管理后台 → 设置中搜索 "project_countdown"：

- `project_countdown_enabled`: 启用插件 (默认: true)
- `project_countdown_show_in_header`: 在顶部显示 (默认: false)
- `project_countdown_max_projects_per_user`: 每用户最大项目数 (默认: 50)

### 自定义样式
如需自定义样式，可以在主题CSS中覆盖：

```css
.project-countdown-container {
  /* 自定义样式 */
}
```

## 监控和维护

### 性能监控
```bash
# 检查内存使用
docker exec -it app free -h

# 检查磁盘使用
docker exec -it app df -h

# 检查数据库
docker exec -it app rails c
User.joins(:user_custom_fields).where(user_custom_fields: {name: 'project_countdown_data'}).count
```

### 数据备份
用户数据存储在Discourse的用户自定义字段中，会随常规备份一起备份。

### 故障恢复
如果插件出现问题：

```bash
# 禁用插件
echo "project_countdown_enabled = false" >> /var/discourse/shared/standalone/discourse.conf

# 重启
cd /var/discourse
./launcher restart app

# 重新启用后重建
./launcher rebuild app
```

---

部署完成后，您的Discourse论坛就拥有了完整的项目倒计时功能！🚀