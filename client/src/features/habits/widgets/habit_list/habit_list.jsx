import { RefreshCw } from "lucide-react";
import AppButton from "@/shared/widgets/app_button/app_button.jsx";
import AppIconButton from "@/shared/widgets/app_icon_button/app_icon_button.jsx";
import AppSelect from "@/shared/widgets/app_select/app_select.jsx";
import { getRecurrenceLabel } from "@/features/dashboard/task_recurrence.js";
import "./habit_list.css";

export default function HabitList({ controller }) {
  return (
    <section aria-labelledby="habit-list-heading" className="habit-list-panel">
      <div className="habit-list-heading">
        <div><h2 id="habit-list-heading">Your habits</h2><p>Recurring tasks, one habit per series.</p></div>
        <AppIconButton aria-label="Refresh habits" disabled={controller.listPending} onClick={controller.retryList} title="Refresh habits"><RefreshCw aria-hidden="true" size={16} /></AppIconButton>
      </div>
      <label className="habit-project-filter">Project<AppSelect onChange={(event) => controller.setProjectId(event.target.value)} value={controller.projectId}><option value="">All projects</option>{controller.projects.map((project) => <option key={project.id} value={project.id}>{project.name}</option>)}</AppSelect></label>
      {controller.projectError && <div className="habit-error" role="alert"><p>Could not load project filters: {controller.projectError}</p><AppButton onClick={controller.retryProjects} variant="secondary">Retry filters</AppButton></div>}
      {controller.selectionNotice && <p className="habit-notice" role="status">{controller.selectionNotice}</p>}
      {controller.listPending ? <p className="habit-placeholder" role="status">Loading habits...</p> : controller.listError ? <div className="habit-error" role="alert"><p>{controller.listError}</p><AppButton onClick={controller.retryList} variant="secondary">Retry habits</AppButton></div> : controller.items.length ? (
        <ul className="habit-list">
          {controller.items.map((habit) => <li key={habit.id}><button aria-pressed={controller.selectedId === habit.id} className="habit-list-item" onClick={() => controller.selectHabit(habit.id)} type="button">
            <span className="habit-project-dot" style={{ "--habit-project-color": habit.project?.color ?? "var(--project-neutral)" }} />
            <span><strong>{habit.title}</strong><small>{habit.project?.name ?? "General"}</small><span className="habit-cadence">{getRecurrenceLabel(habit.recurrence)}</span></span>
          </button></li>)}
        </ul>
      ) : <div className="habit-placeholder"><h3>{controller.search.trim() || controller.projectId ? "No matching habits" : "No habits yet"}</h3><p>{controller.search.trim() || controller.projectId ? "Try another search or project." : "Create a recurring task in your workspace to see it here."}</p></div>}
      {controller.pageError && <p className="habit-error" role="alert">{controller.pageError}</p>}
      {!controller.listPending && controller.nextCursor && <AppButton className="habit-load-more" disabled={controller.pagePending} onClick={() => void controller.loadMore()} variant="secondary">{controller.pagePending ? "Loading more..." : controller.pageError ? "Retry load more" : "Load more habits"}</AppButton>}
      {!controller.listPending && controller.items.length > 0 && <p className="habit-list-coverage">{controller.items.length} {controller.nextCursor ? "loaded" : "habits"}</p>}
    </section>
  );
}
