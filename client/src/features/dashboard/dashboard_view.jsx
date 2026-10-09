import { useEffect, useState } from "react";
import { ArrowLeft, Plus, Search } from "lucide-react";
import AppFooter from "@/shared/widgets/app_footer/app_footer.jsx";
import AppButton from "@/shared/widgets/app_button/app_button.jsx";
import AppIconButton from "@/shared/widgets/app_icon_button/app_icon_button.jsx";
import AppInput from "@/shared/widgets/app_input/app_input.jsx";
import ActionToast from "./widgets/action_toast/action_toast.jsx";
import AccountDrawer from "./widgets/account_drawer/account_drawer.jsx";
import CreateProjectDialog from "./widgets/create_project_dialog/create_project_dialog.jsx";
import CreateTaskDialog from "./widgets/create_task_dialog/create_task_dialog.jsx";
import DeleteProjectDialog from "./widgets/delete_project_dialog/delete_project_dialog.jsx";
import DeleteTaskDialog from "./widgets/delete_task_dialog/delete_task_dialog.jsx";
import ProjectList from "./widgets/project_list/project_list.jsx";
import MobileWorkspaceNavigation from "./widgets/mobile_workspace_navigation/mobile_workspace_navigation.jsx";
import { useMobileWorkspaceController } from "./widgets/mobile_workspace_navigation/use_mobile_workspace_controller.js";
import { WORKSPACE_VIEWS } from "./widgets/mobile_workspace_navigation/constants/workspace_views.js";
import SkipTaskDialog from "./widgets/skip_task_dialog/skip_task_dialog.jsx";
import SummaryStrip from "./widgets/summary_strip/summary_strip.jsx";
import TaskList from "./widgets/task_list/task_list.jsx";
import UpcomingTaskList from "./widgets/upcoming_task_list/upcoming_task_list.jsx";
import { useDashboardController } from "./use_dashboard_controller.js";
import "./dashboard_layout.css";

export default function DashboardView({ theme, onToggleTheme, themeController, user, onLogout, onOpenDevices, onOpenHabits, isLoggingOut }) {
  const dashboard = useDashboardController();
  const mobileWorkspace = useMobileWorkspaceController({ selectProject: dashboard.selectProject, upcomingCount: dashboard.upcomingTasks.length });
  const [currentTime, setCurrentTime] = useState(() => new Date());

  useEffect(() => {
    const intervalId = window.setInterval(() => setCurrentTime(new Date()), 1000);
    return () => window.clearInterval(intervalId);
  }, []);

  const dateLabel = new Intl.DateTimeFormat("en-GB", { day: "numeric", month: "short" }).format(currentTime);
  const weekdayLabel = new Intl.DateTimeFormat("en-GB", { weekday: "long" }).format(currentTime);
  const timeLabel = new Intl.DateTimeFormat("en-GB", { hour: "2-digit", minute: "2-digit", second: "2-digit", hourCycle: "h23" }).format(currentTime);

  return (
    <div className="app-layout">
      <aside className="sidebar">
        <div className="sidebar-heading">
          <a aria-label="MyManger home" className="brand" href="#overview">
            <span aria-hidden="true" className="brand-mark"><i /><i /><i /></span>
            <span className="brand-copy">My<span>Manger</span></span>
          </a>
        </div>
        <div className="sidebar-overview-header">
          <div aria-label="Current date and local time" className="dashboard-clock dashboard-clock--topbar">
            <div className="header-date-row">
              <time className="header-date" dateTime={currentTime.toISOString()}>{dateLabel}</time>
              <span className="header-weekday">{weekdayLabel}</span>
            </div>
            <div className="header-time-row">
              <span className="header-year">{currentTime.getFullYear()}</span>
              <time className="header-time" dateTime={currentTime.toISOString()}>{timeLabel}</time>
            </div>
          </div>
          <label className="search-box">
            <Search aria-hidden="true" size={17} strokeWidth={2} />
            <span className="visually-hidden">Search tasks</span>
            <AppInput className="app-input--search" onChange={(event) => dashboard.setSearchTerm(event.target.value)} placeholder="Search tasks" type="search" value={dashboard.searchTerm} />
            <kbd>/</kbd>
          </label>
          <SummaryStrip className="summary-strip--topbar" completedCount={dashboard.completedCount} completedTodayCount={dashboard.completedTodayCount} completionRate={dashboard.completionRate} dueTodayCount={dashboard.dueTodayCount} missedCount={dashboard.missedCount} openCount={dashboard.openCount} overdueCount={dashboard.overdueCount} pendingTodayCount={dashboard.pendingTodayCount} skippedCount={dashboard.skippedCount} totalCount={dashboard.totalCount} />
        </div>
        <AccountDrawer isLoggingOut={isLoggingOut} onLogout={onLogout} onOpenDevices={onOpenDevices} onOpenHabits={onOpenHabits} onToggleTheme={onToggleTheme} theme={theme} themeController={themeController} user={user} />
      </aside>

      <main className="workspace">
        <div className="dashboard-content">
          {dashboard.isLoading ? <div className="dashboard-fetch-state" role="status">Loading your workspace...</div> : dashboard.loadError ? (
            <div className="dashboard-fetch-state" role="alert">
              <p>{dashboard.loadError}</p>
              <AppButton onClick={dashboard.retryLoad} variant="secondary">Retry</AppButton>
            </div>
          ) : <>
          {themeController.error && <p className="dashboard-preference-error" role="alert">{themeController.error}</p>}
          {themeController.timezoneMismatch && <div className="dashboard-timezone-notice"><span>Use {themeController.browserTimezone} for task dates?</span><AppButton disabled={themeController.isSaving} onClick={() => { void themeController.saveTimezone().then((saved) => { if (saved) return dashboard.retryLoad(); return undefined; }); }} variant="secondary">Use timezone</AppButton><AppButton onClick={themeController.dismissTimezone} variant="secondary">Not now</AppButton></div>}

          <MobileWorkspaceNavigation activeView={mobileWorkspace.activeView} onChangeView={mobileWorkspace.changeView} projectCount={dashboard.projectStats.length} upcomingCount={dashboard.upcomingTasks.length} />
          <div className={`dashboard-grid${dashboard.upcomingTasks.length ? " has-upcoming" : ""}`}>
            <div className="dashboard-project-column" hidden={mobileWorkspace.isPanelHidden(WORKSPACE_VIEWS.PROJECTS)} id="workspace-projects">
              <ProjectList onCreateProject={dashboard.openProjectDialog} onSelectProject={mobileWorkspace.openProject} projects={dashboard.projectStats} selectedProjectId={dashboard.selectedProjectId} />
            </div>
            <aside aria-label={dashboard.selectedProject ? `${dashboard.selectedProject.name} tasks and details` : "Task List"} className="dashboard-task-column" hidden={mobileWorkspace.isPanelHidden(WORKSPACE_VIEWS.TASKS)} id="workspace-tasks" ref={mobileWorkspace.taskPanelRef} tabIndex={-1}>
              {dashboard.selectedProject && <div className="mobile-project-navigation">
                <AppButton leadingIcon={<ArrowLeft aria-hidden="true" size={15} />} onClick={() => mobileWorkspace.changeView(WORKSPACE_VIEWS.PROJECTS)} variant="secondary">Projects</AppButton>
                <span>Project details & tasks</span>
              </div>}
              {dashboard.filterError && <div className="dashboard-filter-error" role="alert">{dashboard.filterError}<AppButton onClick={dashboard.retryFilter} variant="secondary">Retry</AppButton></div>}
              {dashboard.isFiltering && <span className="dashboard-filter-loading" role="status">Updating tasks...</span>}
              <TaskList
                activeFilter={dashboard.activeFilter}
                asOfDate={dashboard.asOfDate}
                filterCounts={dashboard.filterCounts}
                isPending={dashboard.isMutating}
                onAddTask={() => dashboard.openTaskDialog(dashboard.selectedProjectId)}
                onAddSubtask={dashboard.addSubtask}
                onClearProject={() => dashboard.selectProject(null)}
                onDeleteProject={dashboard.requestDeleteProject}
                onDeleteTask={dashboard.requestDeleteTask}
                onEditProject={dashboard.openEditProjectDialog}
                onEditTask={dashboard.openEditTaskDialog}
                onEditSubtask={dashboard.editSubtask}
                onFilterChange={dashboard.setActiveFilter}
                onMissTask={dashboard.openMissTaskDialog}
                onSkipTask={dashboard.openTaskClosureDialogSkip}
                onToggleTask={dashboard.toggleTask}
                onToggleSubtask={dashboard.toggleSubtask}
                projectColor={dashboard.projectColor}
                projectName={dashboard.projectName}
                selectedProject={dashboard.selectedProject}
                tasks={dashboard.tasks}
              />
            </aside>
            {dashboard.upcomingTasks.length > 0 && (
              <aside className="dashboard-upcoming-column" hidden={mobileWorkspace.isPanelHidden(WORKSPACE_VIEWS.UPCOMING)} id="workspace-upcoming">
                <UpcomingTaskList onEditTask={dashboard.openEditTaskDialog} projectColor={dashboard.projectColor} projectName={dashboard.projectName} tasks={dashboard.upcomingTasks} />
              </aside>
            )}
          </div>
          </>}
          <AppFooter />
        </div>
      </main>
      <AppIconButton aria-label="Add task" className="add-task-fab" onClick={dashboard.openTaskDialog} title="Add task" variant="floating-add">
        <Plus aria-hidden="true" size={24} strokeWidth={2.5} />
      </AppIconButton>
      <CreateTaskDialog
        defaultProjectId={dashboard.taskDialogProjectId}
        isOpen={dashboard.isCreateDialogOpen}
        isPending={dashboard.isMutating}
        onAddSubtask={dashboard.addSubtask}
        onClose={dashboard.closeTaskDialog}
        onCreate={dashboard.createTask}
        onDeleteSubtask={dashboard.requestDeleteTask}
        onEditSubtask={dashboard.editSubtask}
        onToggleSubtask={dashboard.toggleSubtask}
        projects={dashboard.projects}
        task={dashboard.editingTask}
        today={dashboard.asOfDate}
      />
      <CreateProjectDialog isOpen={dashboard.isCreateProjectDialogOpen} isPending={dashboard.isMutating} onClose={dashboard.closeProjectDialog} onCreate={dashboard.createProject} project={dashboard.editingProject} projects={dashboard.projects} />
      <DeleteProjectDialog isOpen={Boolean(dashboard.projectPendingDeletion)} isPending={dashboard.isMutating} onCancel={dashboard.cancelDeleteProject} onConfirm={dashboard.confirmDeleteProject} project={dashboard.projectPendingDeletion} />
      <DeleteTaskDialog isPending={dashboard.isMutating} item={dashboard.taskPendingDeletion} onCancel={dashboard.cancelDeleteTask} onConfirm={dashboard.confirmDeleteTask} />
      <SkipTaskDialog action={dashboard.taskClosureDialog?.action} error={dashboard.taskClosureDialogError} isPending={dashboard.isMutating} onCancel={dashboard.cancelTaskClosureDialog} onConfirm={dashboard.confirmTaskClosure} onReasonChange={dashboard.clearTaskClosureDialogError} task={dashboard.taskClosureDialog?.task} />
      <ActionToast notification={dashboard.notification} onDismiss={dashboard.dismissNotification} />
    </div>
  );
}
