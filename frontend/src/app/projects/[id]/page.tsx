import { notFound } from "next/navigation";
import { ProjectDetailsPage } from "@/components/projects/project-details-page";

type ProjectDetailsRouteProps = {
  params: {
    id: string;
  };
};

export default function ProjectDetailsRoute({ params }: ProjectDetailsRouteProps) {
  const projectId = Number(params.id);

  if (!Number.isFinite(projectId) || projectId <= 0) {
    notFound();
  }

  return <ProjectDetailsPage projectId={projectId} />;
}
