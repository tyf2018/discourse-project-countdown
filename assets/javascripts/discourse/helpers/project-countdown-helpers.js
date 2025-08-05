import { registerUnbound } from "discourse-common/lib/helpers";
import I18n from "I18n";

// 计算剩余天数
function calculateDaysLeft(deadline) {
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  const deadlineDate = new Date(deadline);
  deadlineDate.setHours(0, 0, 0, 0);

  const diffTime = deadlineDate - today;
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

  return diffDays;
}

// 获取状态颜色
function getStatusColor(daysLeft) {
  if (daysLeft < 0) return '#ff4d4f'; // 已过期
  if (daysLeft <= 3) return '#ff7a45'; // 紧急
  if (daysLeft <= 7) return '#ffa940'; // 警告
  if (daysLeft <= 14) return '#ffec3d'; // 注意
  return '#52c41a'; // 正常
}

// 获取状态标签
function getStatusLabel(daysLeft) {
  if (daysLeft < 0) return I18n.t('project_countdown.status.expired');
  if (daysLeft <= 3) return I18n.t('project_countdown.status.urgent');
  if (daysLeft <= 7) return I18n.t('project_countdown.status.warning');
  if (daysLeft <= 14) return I18n.t('project_countdown.status.attention');
  return I18n.t('project_countdown.status.normal');
}

// 查找项目在数组中的索引
function findProjectIndex(projects, project) {
  return projects.findIndex(p => p.id === project.id);
}

// 注册辅助函数
registerUnbound("calculate-days-left", calculateDaysLeft);
registerUnbound("get-status-color", getStatusColor);
registerUnbound("get-status-label", getStatusLabel);
registerUnbound("find-project-index", findProjectIndex);
registerUnbound("abs", Math.abs);
registerUnbound("now", () => new Date());