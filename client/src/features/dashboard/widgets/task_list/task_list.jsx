import { CalendarDays, CircleCheck, FolderTree, ListFilter, ListTodo, Pencil, Plus, Trash2 } from "lucide-react";
import AppIconButton from "@/shared/widgets/app_icon_button/app_icon_button.jsx";
import AppButton from "@/shared/widgets/app_button/app_button.jsx";
import TaskRow from "@/features/dashboard/widgets/task_row/task_row.jsx";
import { TASK_FILTERS } from "./constants/task_filters.js";
import "./task_list.css";

function formatCreatedDate(createdAt) {
  if (!createdAt) return "Not recorded";
  const createdDate = new Date(createdAt);
  if (Number.isNaN(createdDate.getTime())) return "Not recorded";
  return new Intl.DateTimeFormat("en-GB", { day: "numeric", month: "short", year: "numeric" }).format(createdDate);
}

export default function TaskList({ activeFilter, asOfDate, filterCounts, onAddTask, onAddSubtask, onDeleteProject, onDeleteTask, onEditProject, onEditTask, onEditSubtask, onFilterChange, onMissTask, onSkipTask, onToggleTask, onToggleSubtask, projectName, projectColor, selectedProject, tasks, isPending }) {
  return (
    <section aria-labelledby="tasks-heading" className="tasks-section">
      <div className="task-section-header">
        <div className="task-title-toolbar">
          <div className="task-section-heading">
            <h2 id="tasks-heading"><ListTodo aria-hidden="true" className="section-icon" size={18} />{selectedProject?.name ?? "Task List"}</h2>
          </div>
          <div aria-label="Filter tasks" className="task-filters" role="group">
            <ListFilter aria-hidden="true" className="task-filter-icon" size={15} />
            {TASK_FILTERS.map((filter) => (
              <AppButton aria-pressed={activeFilter === filter.id} className={activeFilter === filter.id ? "selected" : ""} key={filter.id} onClick={() => onFilterChange(filter.id)} variant="filter">{filter.label}{Number.isInteger(filterCounts?.[filter.id]) && <span className="task-filter-count">({filterCounts[filter.id]})</span>}</AppButton>
            ))}
          </div>
          <div className="task-list-toolbar">
            <AppButton className="task-add-button" leadingIcon={<Plus aria-hidden="true" size={15} />} onClick={onAddTask}>Add task</AppButton>
          </div>
        </div>
        {selectedProject && (
          <div aria-label={`${selectedProject.name} details`} className="project-details-row">
            <div className="project-detail-metric"><CalendarDays aria-hidden="true" size={15} /><span>Created</span><strong>{formatCreatedDate(selectedProject.createdAt)}</strong></div>
            <div className="project-detail-metric"><ListTodo aria-hidden="true" size={15} /><span>Tasks</span><strong>{selectedProject.taskCount}</strong></div>
            <div className="project-detail-metric"><FolderTree aria-hidden="true" size={15} /><span>Subprojects</span><strong>{selectedProject.subprojectCount}</strong></div>
            <div className="project-detail-metric"><CircleCheck aria-hidden="true" size={15} /><span>Completed</span><strong>{selectedProject.completedCount}/{selectedProject.taskCount}</strong></div>
            <div className="project-detail-actions">
              <AppIconButton aria-label={`Edit ${selectedProject.name}`} className="project-edit-button" onClick={() => onEditProject(selectedProject.id)} title="Edit project" variant="project-action"><Pencil aria-hidden="true" size={15} /></AppIconButton>
              <AppIconButton aria-label={`Delete ${selectedProject.name}`} className="project-delete-button" onClick={() => onDeleteProject(selectedProject.id)} title="Delete project" variant="project-action"><Trash2 aria-hidden="true" size={15} /></AppIconButton>
            </div>
          </div>
        )}
      </div>
      {tasks.length ? (
        <ul className="task-list">
          {tasks.map((task) => <TaskRow asOfDate={asOfDate} isPending={isPending} key={task.id} onAddSubtask={onAddSubtask} onDeleteTask={onDeleteTask} onEditSubtask={onEditSubtask} onEditTask={onEditTask} onMissTask={onMissTask} onSkipTask={onSkipTask} onToggle={onToggleTask} onToggleSubtask={onToggleSubtask} projectColor={projectColor} projectName={projectName} task={task} />)}
        </ul>
      ) : (
        <div className="empty-state"><CircleCheck aria-hidden="true" className="empty-state-icon" size={26} /><h3>No tasks here</h3><p>Create a task to start filling this list.</p></div>
      )}
    </section>
  );
}
