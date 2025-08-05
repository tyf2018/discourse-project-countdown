import Route from "@ember/routing/route";
import { inject as service } from "@ember/service";

export default class ProjectCountdownRoute extends Route {
  @service currentUser;
  @service router;

  beforeModel() {
    // 检查用户是否登录
    if (!this.currentUser) {
      this.router.transitionTo("login");
      return;
    }

    // 检查插件是否启用
    if (!window.ProjectCountdownEnabled) {
      this.router.transitionTo("discovery.latest");
      return;
    }
  }

  model() {
    // 返回当前用户信息，组件会自己处理数据加载
    return {
      user: this.currentUser,
    };
  }

  setupController(controller, model) {
    super.setupController(controller, model);

    // 设置页面标题
    controller.set("title", I18n.t("project_countdown.title"));
  }
}