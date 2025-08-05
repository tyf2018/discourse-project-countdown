// 项目倒计时辅助函数
// 这些函数将直接在组件中使用，不需要注册为Handlebars辅助函数

export function calculateDaysLeft(deadline) {
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  const deadlineDate = new Date(deadline);
  deadlineDate.setHours(0, 0, 0, 0);

  const diffTime = deadlineDate - today;
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

  return diffDays;
}

export function getStatusColor(daysLeft) {
  if (daysLeft < 0) return '#ff4d4f'; // 已过期
  if (daysLeft <= 3) return '#ff7a45'; // 紧急
  if (daysLeft <= 7) return '#ffa940'; // 警告
  if (daysLeft <= 14) return '#ffec3d'; // 注意
  return '#52c41a'; // 正常
}