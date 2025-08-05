# 项目结构说明

## 完整目录结构

```
discourse-project-countdown/
├── plugin.rb                                         # 插件主文件和后端逻辑
├── package.json                                      # 项目元数据
├── LICENSE                                           # MIT许可证
├── .gitignore                                        # Git忽略文件
├── README.md                                         # 项目说明文档
├── INSTALL.md                                        # 安装指南
├── deploy.md                                         # 部署指南
├── CHANGELOG.md                                      # 更新日志
├── PROJECT_STRUCTURE.md                              # 本文件
├── config/                                           # 配置文件
│   ├── settings.yml                                  # 插件设置定义
│   └── locales/                                      # 国际化文件
│       ├── client.en.yml                            # 英文语言包
│       └── client.zh_CN.yml                         # 中文语言包
└── assets/                                           # 前端资源
    ├── stylesheets/                                  # 样式文件
    │   └── project-countdown.scss                    # 主样式文件
    └── javascripts/discourse/                        # JavaScript文件
        ├── initializers/                             # 初始化器
        │   └── project-countdown.js                  # 插件初始化
        ├── routes/                                   # 路由
        │   └── project-countdown.js                  # 主路由
        ├── controllers/                              # 控制器
        │   └── project-countdown.js                  # 主控制器
        ├── components/                               # 组件
        │   └── project-countdown.js                  # 倒计时组件
        ├── helpers/                                  # 辅助函数
        │   └── project-countdown-helpers.js          # Handlebars辅助函数
        └── templates/                                # 模板文件
            ├── project-countdown.hbs                 # 页面模板
            └── components/
                └── project-countdown.hbs             # 组件模板
```

## 文件功能说明

### 核心文件

#### `plugin.rb`
- 插件定义和元数据
- 后端API路由定义
- 用户自定义字段管理
- 数据控制器实现
- 权限和安全设置

#### `config/settings.yml`
- 插件配置选项定义
- 管理员可调整的设置项
- 默认值配置

### 国际化文件

#### `config/locales/client.*.yml`
- 前端界面文本翻译
- 支持中英文双语
- 错误消息和提示文本

### 前端文件

#### JavaScript 组件

**初始化器 (`initializers/project-countdown.js`)**
- 插件初始化逻辑
- 注册组件和路由
- 用户权限检查

**路由 (`routes/project-countdown.js`)**
- 页面路由定义
- 用户权限验证
- 数据预加载

**控制器 (`controllers/project-countdown.js`)**
- 页面状态管理
- 页面标题设置

**组件 (`components/project-countdown.js`)**
- 核心业务逻辑
- 数据状态管理
- 用户交互处理
- API调用

**辅助函数 (`helpers/project-countdown-helpers.js`)**
- Handlebars模板辅助函数
- 数据计算和格式化
- 工具函数

#### 模板文件

**页面模板 (`templates/project-countdown.hbs`)**
- 主页面布局
- 容器组件引用

**组件模板 (`templates/components/project-countdown.hbs`)**
- 完整的UI模板
- 数据绑定和事件处理
- 响应式布局

#### 样式文件

**主样式 (`stylesheets/project-countdown.scss`)**
- 完整的组件样式
- 响应式设计
- Discourse主题适配
- 暗色主题支持

### 文档文件

#### `README.md`
- 项目概述和功能介绍
- 安装和使用说明
- 技术栈说明

#### `INSTALL.md`
- 详细安装步骤
- 故障排除指南
- 配置说明

#### `deploy.md`
- 快速部署指南
- GitHub仓库设置
- 一键安装脚本

#### `CHANGELOG.md`
- 版本更新记录
- 新功能说明
- 兼容性信息

## 技术架构

### 前端架构
```
Ember.js Framework
├── Routes (路由管理)
├── Controllers (状态管理)
├── Components (组件逻辑)
├── Templates (视图模板)
├── Helpers (辅助函数)
└── Styles (样式文件)
```

### 后端架构
```
Discourse Plugin API
├── Routes (API路由)
├── Controllers (业务逻辑)
├── Models (数据模型)
├── Serializers (数据序列化)
└── Permissions (权限控制)
```

### 数据流
```
用户操作 → Component → API Controller → Database
         ↑                           ↓
     Template ←   Component   ←  API Response
```

## 开发工作流

### 1. 修改前端
```bash
# 修改JavaScript/模板/样式文件
discourse-project-countdown/assets/
```

### 2. 修改后端
```bash
# 修改插件主文件
discourse-project-countdown/plugin.rb
```

### 3. 修改配置
```bash
# 修改设置或国际化
discourse-project-countdown/config/
```

### 4. 测试部署
```bash
cd /var/discourse
./launcher rebuild app
```

## 代码规范

### JavaScript
- ES6+ 语法
- Ember.js 约定
- JSDoc 注释
- 错误处理

### 样式
- SCSS 语法
- BEM 命名约定
- 响应式设计
- 主题变量

### 后端
- Ruby 代码规范
- Rails 约定
- 安全最佳实践
- 文档注释

---

此结构确保插件具有良好的可维护性、可扩展性和符合Discourse插件开发标准。