import { useId, useState } from "react";
import { ChevronDown, ChevronRight, CornerDownRight, Plus } from "lucide-react";
import AppButton from "@/shared/widgets/app_button/app_button.jsx";
import { resolveProjectColor } from "../../project_color_utils.js";
import "./project_list.css";

function ProjectBranch({ project, projects, onSelectProject, selectedProjectId, isSubproject = false }) {
  const [isExpanded, setIsExpanded] = useState(true);
  const childrenId = useId();
  const childProjects = projects.filter((candidate) => candidate.parentProjectId === project.id);
  const projectColor = resolveProjectColor(project.id, projects) ?? project.color;

  return (
    <div className={`project-branch${isSubproject ? " project-branch--child" : ""}`}>
      {isSubproject && <CornerDownRight aria-hidden="true" className="project-branch-arrow" size={16} strokeWidth={1.8} />}
      <div className={`project-row${childProjects.length ? " project-row--parent" : ""}`}>
      <button
        aria-label={`${isSubproject ? "Subproject: " : ""}${project.name}, ${project.completedCount} of ${project.taskCount} tasks complete`}
        aria-pressed={selectedProjectId === project.id}
        className={`project-item${selectedProjectId === project.id ? " selected" : ""}`}
        onClick={() => onSelectProject(project.id)}
        style={{ "--project-color": projectColor }}
        title={project.name}
        type="button"
      >
        <div className="project-info">
          <h3>{project.name}</h3>
          <span aria-label={`${project.completedCount} of ${project.taskCount} tasks complete`} className="project-task-count">
            <strong>{project.completedCount}<i>/</i>{project.taskCount}</strong> tasks
          </span>
        </div>
      </button>
      {childProjects.length > 0 && (
        <button
          aria-controls={childrenId}
          aria-expanded={isExpanded}
          aria-label={`${isExpanded ? "Hide" : "Show"} subprojects of ${project.name}`}
          className="project-expand-button"
          onClick={() => setIsExpanded((current) => !current)}
          title={`${isExpanded ? "Hide" : "Show"} subprojects`}
          type="button"
        >
          {isExpanded ? <ChevronDown aria-hidden="true" size={16} /> : <ChevronRight aria-hidden="true" size={16} />}
        </button>
      )}
      </div>
      {childProjects.length > 0 && (
        <div className="project-children" hidden={!isExpanded} id={childrenId}>
          {childProjects.map((childProject) => (
            <ProjectBranch isSubproject key={childProject.id} onSelectProject={onSelectProject} project={childProject} projects={projects} selectedProjectId={selectedProjectId} />
          ))}
        </div>
      )}
    </div>
  );
}

export default function ProjectList({ onSelectProject, onCreateProject, projects, selectedProjectId }) {
  const knownProjectIds = new Set(projects.map((project) => project.id));
  const rootProjects = projects.filter((project) => !project.parentProjectId || !knownProjectIds.has(project.parentProjectId));

  return (
    <section aria-labelledby="projects-heading" className="projects-section">
      <div className="section-heading">
        <h2 id="projects-heading">Projects</h2>
        <AppButton aria-label="New project" className="project-create-button" onClick={onCreateProject} title="New project" variant="secondary"><Plus aria-hidden="true" size={18} /></AppButton>
      </div>
      <div className="project-list">
        {rootProjects.length === 0 && <p className="project-empty">No projects yet. Use + to create one.</p>}
        {rootProjects.map((project) => (
          <ProjectBranch key={project.id} onSelectProject={onSelectProject} project={project} projects={projects} selectedProjectId={selectedProjectId} />
        ))}
      </div>
    </section>
  );
}
