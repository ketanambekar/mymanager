import { useEffect, useLayoutEffect, useRef, useState } from "react";
import { WORKSPACE_VIEWS } from "./constants/workspace_views.js";

const MOBILE_QUERY = "(max-width: 760px)";

export function useMobileWorkspaceController({ selectProject, upcomingCount }) {
  const [isMobile, setIsMobile] = useState(() => window.matchMedia(MOBILE_QUERY).matches);
  const [requestedView, setRequestedView] = useState(WORKSPACE_VIEWS.TASKS);
  const taskPanelRef = useRef(null);
  const shouldFocusProject = useRef(false);
  const activeView = requestedView === WORKSPACE_VIEWS.UPCOMING && !upcomingCount ? WORKSPACE_VIEWS.TASKS : requestedView;

  useEffect(() => {
    const media = window.matchMedia(MOBILE_QUERY);
    const update = () => setIsMobile(media.matches);
    update();
    media.addEventListener("change", update);
    return () => media.removeEventListener("change", update);
  }, []);

  useLayoutEffect(() => {
    if (!shouldFocusProject.current || !isMobile || activeView !== WORKSPACE_VIEWS.TASKS) return;
    taskPanelRef.current?.focus({ preventScroll: true });
    window.scrollTo({ top: 0, behavior: "instant" });
    shouldFocusProject.current = false;
  });

  function changeView(view) {
    if (view === WORKSPACE_VIEWS.TASKS) selectProject(null);
    setRequestedView(view);
  }

  function openProject(projectId) {
    selectProject(projectId, { toggle: !isMobile });
    if (isMobile) {
      shouldFocusProject.current = true;
      setRequestedView(WORKSPACE_VIEWS.TASKS);
    }
  }

  return {
    activeView,
    changeView,
    isMobile,
    openProject,
    taskPanelRef,
    isPanelHidden: (view) => isMobile && activeView !== view,
  };
}
