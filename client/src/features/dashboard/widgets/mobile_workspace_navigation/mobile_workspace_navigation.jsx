import { CalendarDays, FolderKanban, ListTodo } from "lucide-react";
import AppButton from "@/shared/widgets/app_button/app_button.jsx";
import { WORKSPACE_NAVIGATION, WORKSPACE_VIEWS } from "./constants/workspace_views.js";
import "./mobile_workspace_navigation.css";

const VIEW_ICONS = {
  [WORKSPACE_VIEWS.TASKS]: ListTodo,
  [WORKSPACE_VIEWS.PROJECTS]: FolderKanban,
  [WORKSPACE_VIEWS.UPCOMING]: CalendarDays,
};

export default function MobileWorkspaceNavigation({ activeView, onChangeView, projectCount, upcomingCount }) {
  return (
    <nav aria-label="Workspace views" className="mobile-workspace-navigation">
      {WORKSPACE_NAVIGATION.filter(({ id }) => id !== WORKSPACE_VIEWS.UPCOMING || upcomingCount > 0).map(({ id, label }) => {
        const Icon = VIEW_ICONS[id];
        const count = id === WORKSPACE_VIEWS.PROJECTS ? projectCount : id === WORKSPACE_VIEWS.UPCOMING ? upcomingCount : null;
        return (
          <AppButton aria-controls={`workspace-${id}`} aria-pressed={activeView === id} className="mobile-workspace-tab" key={id} onClick={() => onChangeView(id)} variant="secondary">
            <Icon aria-hidden="true" size={16} />
            <span>{label}</span>
            {count !== null && <span className="mobile-workspace-count">{count}</span>}
          </AppButton>
        );
      })}
    </nav>
  );
}
