import Controller from "@ember/controller";
import { tracked } from "@glimmer/tracking";

export default class ProjectCountdownController extends Controller {
  @tracked title = "";

  // 页面元数据
  get pageTitle() {
    return this.title || I18n.t("project_countdown.title");
  }
}