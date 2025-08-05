import Component from "@ember/component";
import { action, computed } from "@ember/object";
import { tracked } from "@glimmer/tracking";
import { inject as service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import I18n from "I18n";

export default class ProjectCountdown extends Component {
  @service currentUser;
  @service dialog;

  // 响应式状态
  @tracked projects = [];
  @tracked editMode = false;
  @tracked newProject = { name: '', deadline: this.formatDate(new Date()), isImportant: false };
  @tracked editIndex = -1;
  @tracked loading = true;
  @tracked sortType = 'daysLeft';
  @tracked filterText = '';
  @tracked showImportantOnly = true;
  @tracked showSortMenu = false;

  // 排序选项
  sortOptions = [
    { key: 'daysLeft', label: 'project_countdown.sort.by_days_left' },
    { key: 'nameAsc', label: 'project_countdown.sort.by_name_asc' },
    { key: 'nameDesc', label: 'project_countdown.sort.by_name_desc' },
    { key: 'dateAsc', label: 'project_countdown.sort.by_date_asc' },
    { key: 'dateDesc', label: 'project_countdown.sort.by_date_desc' }
  ];

  didInsertElement() {
    super.didInsertElement(...arguments);
    this.loadProjects();
    this.setupClickOutsideHandler();
  }

  willDestroyElement() {
    super.willDestroyElement(...arguments);
    this.removeClickOutsideHandler();
  }

  setupClickOutsideHandler() {
    this.clickOutsideHandler = (event) => {
      if (this.showSortMenu) {
        const sortMenuElement = document.querySelector('[data-sort-menu="true"]');
        const titleElement = document.querySelector('[data-sort-title="true"]');

        if (sortMenuElement && titleElement &&
            !sortMenuElement.contains(event.target) &&
            !titleElement.contains(event.target)) {
          this.showSortMenu = false;
        }
      }
    };
    document.addEventListener('mousedown', this.clickOutsideHandler);
  }

  removeClickOutsideHandler() {
    if (this.clickOutsideHandler) {
      document.removeEventListener('mousedown', this.clickOutsideHandler);
    }
  }

  // 工具函数
  formatDate(date) {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  calculateDaysLeft(deadline) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const deadlineDate = new Date(deadline);
    deadlineDate.setHours(0, 0, 0, 0);

    const diffTime = deadlineDate - today;
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

    return diffDays;
  }

  getStatusColor(daysLeft) {
    if (daysLeft < 0) return '#ff4d4f'; // 已过期
    if (daysLeft <= 3) return '#ff7a45'; // 紧急
    if (daysLeft <= 7) return '#ffa940'; // 警告
    if (daysLeft <= 14) return '#ffec3d'; // 注意
    return '#52c41a'; // 正常
  }

  getStatusLabel(daysLeft) {
    if (daysLeft < 0) return I18n.t('project_countdown.status.expired');
    if (daysLeft <= 3) return I18n.t('project_countdown.status.urgent');
    if (daysLeft <= 7) return I18n.t('project_countdown.status.warning');
    if (daysLeft <= 14) return I18n.t('project_countdown.status.attention');
    return I18n.t('project_countdown.status.normal');
  }

  // 计算属性
  @computed('projects.[]', 'filterText', 'showImportantOnly', 'sortType')
  get displayProjects() {
    let filtered = this.filterProjects(this.projects, this.filterText, this.showImportantOnly);
    return this.sortProjects(filtered, this.sortType);
  }

  @computed('displayProjects.[]')
  get activeProjects() {
    return this.displayProjects.filter(project => this.calculateDaysLeft(project.deadline) >= 0);
  }

  @computed('displayProjects.[]')
  get expiredProjects() {
    return this.displayProjects.filter(project => this.calculateDaysLeft(project.deadline) < 0);
  }

  @computed('filterText', 'showImportantOnly', 'activeProjects.length')
  get noProjectsMessage() {
    if (this.filterText) {
      const keywords = this.filterText.trim().split(/\s+/).join('", "');
      return I18n.t('project_countdown.no_filtered_projects', { keywords });
    }

    if (this.showImportantOnly) {
      return I18n.t('project_countdown.no_important_projects');
    }

    return I18n.t('project_countdown.no_projects');
  }

  // 数据处理方法
  filterProjects(projectList, filterText, showImportantOnly) {
    let filtered = projectList;

    // 关注项目筛选
    if (showImportantOnly) {
      filtered = filtered.filter(project => project.isImportant === true);
    }

    // 文本筛选
    if (!filterText.trim()) return filtered;

    const keywords = filterText.trim().split(/\s+/).filter(keyword => keyword.length > 0);

    return filtered.filter(project => {
      const projectName = project.name.toLowerCase();
      return keywords.every(keyword =>
        projectName.includes(keyword.toLowerCase())
      );
    });
  }

  sortProjects(projectList, sortType) {
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
          const daysLeftA = this.calculateDaysLeft(a.deadline);
          const daysLeftB = this.calculateDaysLeft(b.deadline);
          return daysLeftA - daysLeftB;
      }
    });
  }

  // API操作
  async loadProjects() {
    try {
      this.loading = true;
      const response = await ajax('/project-countdown/data');
      this.projects = response.projects || [];
    } catch (error) {
      console.error('Failed to load projects:', error);
      popupAjaxError(error);
    } finally {
      this.loading = false;
    }
  }

  async saveProjects(projectsData = null) {
    try {
      const dataToSave = projectsData || this.projects;
      await ajax('/project-countdown/data', {
        type: 'POST',
        data: { projects: dataToSave }
      });
      return true;
    } catch (error) {
      console.error('Failed to save projects:', error);
      popupAjaxError(error);
      return false;
    }
  }

  // 用户操作
  @action
  async addProject() {
    if (!this.newProject.name.trim() || !this.newProject.deadline) {
      this.dialog.alert(I18n.t('project_countdown.validation.name_required'));
      return;
    }

    // 检查项目数量限制
    const maxProjects = this.siteSettings.project_countdown_max_projects_per_user || 50;
    if (this.projects.length >= maxProjects) {
      this.dialog.alert(I18n.t('project_countdown.validation.max_projects_reached'));
      return;
    }

    const updatedProjects = [...this.projects, { ...this.newProject, id: Date.now() }];
    this.projects = updatedProjects;
    this.newProject = { name: '', deadline: this.formatDate(new Date()), isImportant: false };

    const success = await this.saveProjects(updatedProjects);
    if (success) {
      this.dialog.alert(I18n.t('project_countdown.save_success'));
    }
  }

  @action
  async deleteProject(index) {
    const confirmed = await this.dialog.confirm(I18n.t('project_countdown.delete_confirm'));
    if (!confirmed) return;

    const updatedProjects = [...this.projects];
    updatedProjects.splice(index, 1);
    this.projects = updatedProjects;

    await this.saveProjects(updatedProjects);
  }

  @action
  startEdit(index) {
    this.editIndex = index;
    this.editMode = true;
    this.newProject = { ...this.projects[index] };
  }

  @action
  async saveEdit() {
    if (this.editIndex >= 0 && this.editIndex < this.projects.length) {
      const updatedProjects = [...this.projects];
      updatedProjects[this.editIndex] = { ...this.newProject };
      this.projects = updatedProjects;

      const success = await this.saveProjects(updatedProjects);
      if (success) {
        this.dialog.alert(I18n.t('project_countdown.save_success'));
      }

      this.cancelEdit();
    }
  }

  @action
  cancelEdit() {
    this.editMode = false;
    this.editIndex = -1;
    this.newProject = { name: '', deadline: this.formatDate(new Date()), isImportant: false };
  }

  @action
  toggleSortMenu() {
    this.showSortMenu = !this.showSortMenu;
  }

  @action
  setSortType(sortType) {
    this.sortType = sortType;
    this.showSortMenu = false;
  }

  @action
  updateNewProjectName(event) {
    this.newProject = { ...this.newProject, name: event.target.value };
  }

  @action
  updateNewProjectDeadline(event) {
    this.newProject = { ...this.newProject, deadline: event.target.value };
  }

  @action
  updateNewProjectImportant(event) {
    this.newProject = { ...this.newProject, isImportant: event.target.checked };
  }

  @action
  updateFilterText(event) {
    this.filterText = event.target.value;
  }

  @action
  updateShowImportantOnly(event) {
    this.showImportantOnly = event.target.checked;
  }
}