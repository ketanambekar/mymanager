import { Cell, Pie, PieChart, ResponsiveContainer } from "recharts";
import "./task_completion_chart.css";

export default function TaskCompletionChart({ completedCount, openCount, skippedCount, missedCount, completionRate, totalCount }) {
  const chartData = totalCount
    ? [
      { name: "Completed", value: completedCount, color: "var(--green)" },
      { name: "Open", value: openCount, color: "var(--progress-track)" },
      { name: "Skipped", value: skippedCount, color: "var(--project-blue)" },
      { name: "Missed", value: missedCount, color: "var(--orange)" },
    ]
    : [{ name: "No tasks", value: 1, color: "var(--progress-track)" }];

  return (
    <div aria-hidden="true" className="completion-chart">
      <ResponsiveContainer height="100%" width="100%">
        <PieChart>
          <Pie data={chartData} dataKey="value" innerRadius="72%" outerRadius="94%" paddingAngle={totalCount ? 3 : 0} startAngle={90} endAngle={-270}>
            {chartData.map((segment) => <Cell fill={segment.color} key={segment.name} stroke="none" />)}
          </Pie>
        </PieChart>
      </ResponsiveContainer>
      <span className="completion-rate">{completionRate}%</span>
    </div>
  );
}