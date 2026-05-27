import { notFound } from "next/navigation";
import { ProjectDetailsPage } from "@/components/projects/project-details-page";

type ProjectDetailsRouteProps = {
  params: Promise<{
    id: string;
  }>;
};

export default async function ProjectDetailsRoute({ params }: ProjectDetailsRouteProps) {
  const resolvedParams = await params;
  const projectId = Number(resolvedParams.id);

  if (!Number.isFinite(projectId) || projectId <= 0) {
    notFound();
  }

  return <ProjectDetailsPage projectId={projectId} />;
}
