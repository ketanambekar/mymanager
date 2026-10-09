import { AlertTriangle, CalendarDays, Check, Circle, Clock3, Minus, Pause, SkipForward, X } from "lucide-react";
import { HABIT_STATES } from "@/features/habits/constants/habit_states.js";
import "./habit_state.css";

const STATE_ICONS = { check: Check, skip: SkipForward, miss: X, pending: Clock3, overdue: AlertTriangle, scheduled: CalendarDays, empty: Minus, other: Pause };

export default function HabitState({ state, iconOnly = false }) {
  const definition = HABIT_STATES.find((item) => item.id === state);
  const Icon = definition ? STATE_ICONS[definition.symbol] : Circle;
  return (
    <span className={`habit-state habit-state--${state.toLowerCase()}`} title={definition?.label ?? state}>
      <Icon aria-hidden="true" size={14} />
      {!iconOnly && <span>{definition?.label ?? state}</span>}
    </span>
  );
}
