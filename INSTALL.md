# Discourse 项目倒计时插件安装指南

## 快速安装

### 方法一：通过GitHub仓库安装（推荐）

1. **准备GitHub仓库**
   ```bash
   # 1. 将插件文件上传到您的GitHub仓库
   git clone https://github.com/your-username/discourse-project-countdown.git
   cd discourse-project-countdown
   git add .
   git commit -m "Initial commit"
   git push origin main
   ```

2. **在Discourse后台安装**
   - 登录Discourse管理后台
   - 进入 **管理 → 插件 → 安装插件**
   - 输入仓库地址: `https://github.com/your-username/discourse-project-countdown.git`
   - 点击"安装"

3. **重启Discourse**
   ```bash
   cd /var/discourse
   ./launcher rebuild app
   ```

### 方法二：Docker环境安装

1. **编辑app.yml配置文件**
   ```bash
   cd /var/discourse
   nano containers/app.yml
   ```

2. **添加插件到hooks段**
   ```yaml
   hooks:
     after_code:
       - exec:
           cd: $home/plugins
           cmd:
             - git clone https://github.com/your-username/discourse-project-countdown.git
   ```

3. **重建容器**
   ```bash
   ./launcher rebuild app
   ```

### 方法三：手动安装

1. **下载插件文件**
   ```bash
   cd /var/discourse/shared/standalone/app/plugins
   git clone https://github.com/your-username/discourse-project-countdown.git
   ```

2. **设置权限**
   ```bash
   chown -R discourse:discourse discourse-project-countdown
   chmod -R 755 discourse-project-countdown
   ```

3. **重启Discourse**
   ```bash
   cd /var/discourse
   ./launcher restart app
   ```

## 验证安装

### 1. 检查插件状态
- 访问管理后台 → 插件
- 查看"discourse-project-countdown"是否在已安装列表中
- 状态应显示为"活跃"

### 2. 检查功能
- 以普通用户登录
- 访问 `/project-countdown` 页面
- 尝试添加一个测试项目

### 3. 检查设置
- 进入管理后台 → 设置
- 搜索"project_countdown"
- 应该看到相关配置选项

## 配置设置

安装成功后，配置以下设置：

```yaml
# 基础设置
project_countdown_enabled: true                    # 启用插件
project_countdown_show_in_header: false           # 在顶部导航显示
project_countdown_max_projects_per_user: 50       # 每用户最大项目数
```

## 故障排除

### 安装失败

**症状**: 插件安装时报错
```
Error: Failed to clone repository
```

**解决方案**:
1. 检查仓库地址是否正确
2. 确认仓库是公开的（或设置了正确的访问权限）
3. 检查服务器网络连接

### 插件未激活

**症状**: 插件已安装但未激活

**解决方案**:
```bash
# 检查插件目录
ls -la /var/discourse/shared/standalone/app/plugins/

# 检查权限
chown -R discourse:discourse /var/discourse/shared/standalone/app/plugins/discourse-project-countdown

# 重启服务
cd /var/discourse
./launcher restart app
```

### 页面404错误

**症状**: 访问 `/project-countdown` 显示404

**解决方案**:
1. 确认插件已正确安装
2. 检查用户是否已登录
3. 清除浏览器缓存
4. 重启Discourse服务

### JavaScript错误

**症状**: 浏览器控制台显示JS错误

**解决方案**:
```bash
# 清除资源缓存
cd /var/discourse
./launcher rebuild app

# 检查文件完整性
find /var/discourse/shared/standalone/app/plugins/discourse-project-countdown -name "*.js" -exec head -1 {} \;
```

### 样式不正确

**症状**: 界面样式显示异常

**解决方案**:
1. 切换到默认主题测试
2. 检查是否与其他插件冲突
3. 清除浏览器缓存
4. 检查CSS文件是否正确加载

## 升级插件

### 自动升级
```bash
cd /var/discourse/shared/standalone/app/plugins/discourse-project-countdown
git pull origin main
cd /var/discourse
./launcher rebuild app
```

### 手动升级
1. 备份当前版本
2. 下载新版本文件
3. 替换插件目录
4. 重启Discourse

## 卸载插件

### 完全卸载
```bash
# 删除插件文件
rm -rf /var/discourse/shared/standalone/app/plugins/discourse-project-countdown

# 重启Discourse
cd /var/discourse
./launcher rebuild app
```

### 数据清理
```sql
-- 清理用户自定义字段（可选）
DELETE FROM user_custom_fields
WHERE name = 'project_countdown_data';
```

## 性能优化

### 数据库优化
```sql
-- 为自定义字段添加索引
CREATE INDEX idx_user_custom_fields_project_countdown
ON user_custom_fields(name, user_id)
WHERE name = 'project_countdown_data';
```

### 缓存设置
在 `app.yml` 中增加缓存设置：
```yaml
env:
  DISCOURSE_ENABLE_PERFORMANCE_COUNTERS: true
```

## 监控和日志

### 查看安装日志
```bash
cd /var/discourse
./launcher logs app | grep -i project
```

### 检查错误日志
```bash
tail -f /var/discourse/shared/standalone/log/rails/production.log | grep -i error
```

### 性能监控
- 使用Discourse内置的性能计数器
- 监控数据库查询时间
- 检查内存使用情况

## 联系支持

如果遇到安装问题：

1. **检查系统要求**
   - Discourse 3.0.0+
   - Ruby 3.0+
   - 足够的内存和存储空间

2. **收集错误信息**
   - 错误日志
   - 系统环境信息
   - 重现步骤

3. **寻求帮助**
   - GitHub Issues
   - Discourse官方论坛
   - 插件文档

---

安装成功后，您的用户就可以开始使用项目倒计时功能了！🎉