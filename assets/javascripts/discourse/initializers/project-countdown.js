import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "project-countdown",
  initialize() {
    withPluginApi("0.8.7", (api) => {
      // 检查插件是否启用
      if (!window.ProjectCountdownEnabled || !api.getCurrentUser()) {
        return;
      }

      // 注册组件到用户菜单
      api.decorateWidget("user-menu:after", (helper) => {
        if (helper.getModel().can_use_project_countdown) {
          return helper.h("div.project-countdown-menu-item", [
            helper.h(
              "a",
              {
                href: "/project-countdown",
                className: "project-countdown-link",
              },
              I18n.t("project_countdown.title")
            ),
          ]);
        }
      });

      // 添加路由
      api.addRoute("project-countdown", {
        path: "/project-countdown",
        component: "project-countdown",
      });

      // 添加导航菜单项
      api.addNavigationBarItem({
        name: "project-countdown",
        displayName: I18n.t("project_countdown.title"),
        href: "/project-countdown",
        customFilter: (category, args, router) => {
          return api.getCurrentUser() && window.ProjectCountdownEnabled;
        },
      });
    });
  },
};