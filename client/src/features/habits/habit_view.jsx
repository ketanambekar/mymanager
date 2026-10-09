import { ArrowLeft, CalendarDays, Search } from "lucide-react";
import AppButton from "@/shared/widgets/app_button/app_button.jsx";
import AppInput from "@/shared/widgets/app_input/app_input.jsx";
import AppFooter from "@/shared/widgets/app_footer/app_footer.jsx";
import HabitList from "./widgets/habit_list/habit_list.jsx";
import HabitCalendar from "./widgets/habit_calendar/habit_calendar.jsx";
import HabitDayDetails from "./widgets/habit_day_details/habit_day_details.jsx";
import HabitHistory from "./widgets/habit_history/habit_history.jsx";
import { useHabitController } from "./use_habit_controller.js";
import "./habit_view.css";

export default function HabitView({ onBack }) {
  const controller = useHabitController();
  return (
    <main className="habits-page">
      <header className="habits-page-header">
        <AppButton leadingIcon={<ArrowLeft aria-hidden="true" size={16} />} onClick={onBack} variant="secondary">Workspace</AppButton>
        <div className="habits-page-intro"><p>YOUR RHYTHM</p><h1><CalendarDays aria-hidden="true" size={22} />Habits</h1><span>Your recurring tasks and saved history.</span></div>
        <label className="habit-search"><Search aria-hidden="true" size={16} /><span className="visually-hidden">Search habits</span><AppInput maxLength={120} onChange={(event) => controller.setSearch(event.target.value)} placeholder="Search habits" type="search" value={controller.search} /></label>
        <span className="habits-brand">MyManger</span>
      </header>
      <div className={`habits-layout${controller.showMobileList ? " habits-layout--list" : " habits-layout--calendar"}`}>
        <div aria-label="Habit selection" className="habits-list-column" ref={controller.listPanelRef} tabIndex={-1}><HabitList controller={controller} /></div>
        <div aria-label="Selected habit history and details" className="habits-calendar-column" ref={controller.calendarPanelRef} tabIndex={-1}>
          <AppButton className="habits-mobile-back" leadingIcon={<ArrowLeft aria-hidden="true" size={15} />} onClick={() => controller.setShowMobileList(true)} variant="secondary">All habits</AppButton>
          {controller.calendarPending ? <div className="habit-placeholder habit-calendar-placeholder" role="status">Loading habit history...</div> : controller.calendarError ? <div className="habit-error habit-calendar-placeholder" role="alert"><p>{controller.calendarError}</p><AppButton onClick={controller.retryCalendar} variant="secondary">Retry history</AppButton></div> : controller.calendar ? <>
            <div className="habits-detail-layout">
              {controller.calendar.periods
                ? <HabitHistory history={controller.calendar} onChangeYear={controller.changeYear} onSelectOccurrence={controller.setSelectedDate} onThisYear={controller.thisMonth} selectedDate={controller.selectedDate} />
                : <HabitCalendar calendar={controller.calendar} onChangeMonth={controller.changeMonth} onSelectDay={controller.setSelectedDate} onThisMonth={controller.thisMonth} selectedDate={controller.selectedDate} />}
              <HabitDayDetails day={controller.selectedDay} timezone={controller.calendar.timezone} />
            </div>
          </> : <div className="habit-placeholder habit-calendar-placeholder"><CalendarDays aria-hidden="true" size={32} /><h2>Choose a habit</h2><p>Select a recurring task to explore its saved history.</p></div>}
        </div>
      </div>
      <AppFooter />
    </main>
  );
}
