import { FolderKanban, FolderPlus } from "lucide-react";
import AppButton from "@/shared/widgets/app_button/app_button.jsx";
import { resolveProjectColor } from "../../project_color_utils.js";
import "./project_list.css";

function ProjectBranch({ project, projects, onSelectProject, selectedProjectId }) {
  const childProjects = projects.filter((candidate) => candidate.parentProjectId === project.id);
  const projectColor = resolveProjectColor(project.id, projects) ?? project.color;

  return (
    <div className="project-branch">
      <button
        aria-label={`${project.name}, ${project.completedCount} of ${project.taskCount} tasks complete`}
        aria-pressed={selectedProjectId === project.id}
        className={`project-item${selectedProjectId === project.id ? " selected" : ""}`}
        onClick={() => onSelectProject(project.id)}
        style={{ "--project-color": projectColor }}
        type="button"
      >
        <div aria-label={`${project.progress}% complete`} className="project-progress-ring" role="img" style={{ "--project-progress": `${project.progress}%` }}>
          <span>{project.progress}%</span>
        </div>
        <div className="project-info">
          <h3>{project.name}</h3>
          <span>{project.taskCount > 0 && project.completedCount === project.taskCount ? "Complete" : childProjects.length ? `${childProjects.length} subprojects` : "In progress"}</span>
        </div>
        <div aria-label={`${project.completedCount} of ${project.taskCount} tasks complete`} className="project-task-count">
          <strong>{project.completedCount}<i>/</i>{project.taskCount}</strong>
          <span>tasks</span>
        </div>
      </button>
      {childProjects.length > 0 && (
        <div className="project-children">
          {childProjects.map((childProject) => (
            <ProjectBranch key={childProject.id} onSelectProject={onSelectProject} project={childProject} projects={projects} selectedProjectId={selectedProjectId} />
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
        <h2 id="projects-heading"><FolderKanban aria-hidden="true" className="section-icon" size={18} />Your projects</h2>
        <AppButton className="project-create-button" leadingIcon={<FolderPlus size={16} />} onClick={onCreateProject} variant="secondary">New project</AppButton>
      </div>
      <div className="project-list">
        {rootProjects.length === 0 && <p className="project-empty">No projects yet. Create one to organize your tasks.</p>}
        {rootProjects.map((project) => (
          <ProjectBranch key={project.id} onSelectProject={onSelectProject} project={project} projects={projects} selectedProjectId={selectedProjectId} />
        ))}
      </div>
    </section>
  );
}
