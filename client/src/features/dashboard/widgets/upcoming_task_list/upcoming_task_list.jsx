import { CalendarClock } from "lucide-react";
import "./upcoming_task_list.css";

function formatUpcomingDate(dueDate) {
  return new Intl.DateTimeFormat("en-GB", { day: "numeric", month: "short", year: "numeric" })
    .format(new Date(`${dueDate}T00:00:00`));
}

export default function UpcomingTaskList({ tasks, projectColor, projectName, onEditTask }) {
  const days = tasks.reduce((groups, task) => {
    let day = groups[groups.length - 1];
    if (day?.date !== task.dueDate) {
      day = { date: task.dueDate, tasks: [] };
      groups.push(day);
    }
    day.tasks.push(task);
    return groups;
  }, []);

  return (
    <section aria-labelledby="upcoming-heading" className="upcoming-section">
      <h2 id="upcoming-heading"><CalendarClock aria-hidden="true" size={18} />Upcoming tasks</h2>
      <ol className="upcoming-list">
        {days.map((day) => (
          <li className="upcoming-day" key={day.date}>
            <time dateTime={day.date}>{formatUpcomingDate(day.date)}</time>
            <ul className="upcoming-day-tasks">
              {day.tasks.map((task) => (
                <li key={task.id} style={{ "--upcoming-project-color": projectColor(task.projectId) }}>
                  <button
                    aria-label={`Edit task: ${task.title}`}
                    className="upcoming-task-button"
                    onClick={() => onEditTask(task.id)}
                    title={`Edit task: ${task.title}`}
                    type="button"
                  >
                    <span className="upcoming-task-title">{task.title}</span>
                    <span className="upcoming-project" title={projectName(task.projectId)}>{projectName(task.projectId)}</span>
                  </button>
                </li>
              ))}
            </ul>
          </li>
        ))}
      </ol>
    </section>
  );
}