import { useEffect, useLayoutEffect, useRef, useState } from "react";
import { getApiErrorMessage } from "@/services/api_client.js";
import * as repository from "./habit_repository.js";
import { adjacentHabitMonths, adjacentHabitYears, isHabitHistoryDate, nearestHabitMonth } from "./habit_calendar_utils.js";

export function useHabitController() {
  const [search, setSearch] = useState("");
  const [projectId, setProjectId] = useState("");
  const [projects, setProjects] = useState([]);
  const [projectError, setProjectError] = useState("");
  const [list, setList] = useState(null);
  const [listError, setListError] = useState("");
  const [listPending, setListPending] = useState(true);
  const [pagePending, setPagePending] = useState(false);
  const [pageError, setPageError] = useState("");
  const [selectedId, setSelectedId] = useState("");
  const [requestedMonth, setRequestedMonth] = useState(null);
  const [requestedYear, setRequestedYear] = useState(null);
  const [preferNearestHistory, setPreferNearestHistory] = useState(true);
  const [calendarResult, setCalendarResult] = useState(null);
  const [calendarError, setCalendarError] = useState("");
  const [calendarPending, setCalendarPending] = useState(false);
  const [selectedDate, setSelectedDate] = useState("");
  const [selectionNotice, setSelectionNotice] = useState("");
  const [listRevision, setListRevision] = useState(0);
  const [calendarRevision, setCalendarRevision] = useState(0);
  const [projectRevision, setProjectRevision] = useState(0);
  const [showMobileList, setShowMobileList] = useState(true);
  const pageRequest = useRef(null);
  const scopeGeneration = useRef(0);
  const autoSelect = useRef(true);
  const calendarPanelRef = useRef(null);
  const listPanelRef = useRef(null);
  const previousMobileList = useRef(true);
  const scope = JSON.stringify([search.trim(), projectId, listRevision]);
  const calendarKey = JSON.stringify([selectedId, requestedMonth, requestedYear, preferNearestHistory, calendarRevision]);
  const calendar = calendarResult?.key === calendarKey ? calendarResult.data : null;
  const currentList = list?.scope === scope ? list.data : null;
  const listReady = Boolean(currentList);
  const selectedHabit = currentList?.items.find((habit) => habit.id === selectedId);
  const periodUnit = selectedHabit?.periodUnit;
  const isPeriodHistory = periodUnit && periodUnit !== "day";

  useLayoutEffect(() => {
    if (previousMobileList.current !== showMobileList && window.matchMedia("(max-width: 760px)").matches) {
      const panel = showMobileList ? listPanelRef.current : calendarPanelRef.current;
      panel?.focus({ preventScroll: true });
      window.scrollTo({ top: 0, behavior: "instant" });
    }
    previousMobileList.current = showMobileList;
  }, [showMobileList]);

  useEffect(() => {
    const request = new AbortController();
    repository.getHabitProjects(request.signal)
      .then((data) => { if (!request.signal.aborted) { setProjects(data); setProjectError(""); } })
      .catch((error) => { if (!request.signal.aborted) setProjectError(getApiErrorMessage(error)); });
    return () => request.abort();
  }, [projectRevision]);

  useEffect(() => {
    const request = new AbortController();
    ++scopeGeneration.current;
    pageRequest.current?.abort();
    pageRequest.current = null;
    setPagePending(false);
    setPageError("");
    setListPending(true);
    setListError("");
    const timer = window.setTimeout(() => {
      repository.getHabits({ search: search.trim(), projectId, signal: request.signal })
        .then((data) => {
          if (request.signal.aborted) return;
          setList({ scope, data });
          setSelectedId((current) => {
            if (data.items.some((item) => item.id === current)) return current;
            return autoSelect.current ? data.items[0]?.id ?? "" : "";
          });
        })
        .catch((error) => { if (!request.signal.aborted) setListError(getApiErrorMessage(error)); })
        .finally(() => { if (!request.signal.aborted) setListPending(false); });
    }, search ? 250 : 0);
    return () => { request.abort(); pageRequest.current?.abort(); window.clearTimeout(timer); };
  }, [scope, search, projectId]);

  useEffect(() => {
    if (!selectedId || !currentList) return undefined;
    const request = new AbortController();
    setCalendarPending(true);
    setCalendarError("");
    const fetchHistory = requestedYear !== null && isPeriodHistory
      ? repository.getHabitHistory(selectedId, requestedYear, request.signal)
      : repository.getHabitCalendar(selectedId, requestedMonth, request.signal);
    fetchHistory
      .then(async (initialData) => {
        let data = initialData;
        if (!request.signal.aborted && !data.periods) {
          const targetMonth = requestedMonth === null && preferNearestHistory
            && data.availableMonths.length > 0 && !data.availableMonths.includes(data.month)
            ? nearestHabitMonth(data.availableMonths, data.asOfDate.slice(0, 7)) : data.month;
          if (data.habit.periodUnit !== "day") {
            data = await repository.getHabitHistory(selectedId, Number(targetMonth.slice(0, 4)), request.signal);
          } else if (targetMonth !== data.month) {
            data = await repository.getHabitCalendar(selectedId, targetMonth, request.signal);
          }
        }
        if (request.signal.aborted) return;
        setCalendarResult({ key: calendarKey, data });
        const visibleDays = data.periods ? data.periods.flatMap((period) => period.occurrences)
          : data.days.filter((day) => isHabitHistoryDate(day.date, data));
        setSelectedDate(visibleDays.find((day) => day.isToday)?.date ?? visibleDays.find((day) => day.occurrence)?.date ?? visibleDays[0]?.date ?? "");
      })
      .catch((error) => {
        if (request.signal.aborted) return;
        if (error.response?.data?.error?.code === "HABIT_NOT_FOUND") {
          autoSelect.current = false;
          setSelectedId("");
          setRequestedMonth(null);
          setSelectionNotice("This habit is no longer available. The list has been refreshed; choose another habit.");
          setShowMobileList(true);
          setListRevision((value) => value + 1);
        } else {
          setCalendarError(getApiErrorMessage(error));
        }
      })
      .finally(() => { if (!request.signal.aborted) setCalendarPending(false); });
    return () => request.abort();
  }, [calendarKey, selectedId, requestedMonth, requestedYear, preferNearestHistory, isPeriodHistory, listReady, scope]);

  async function loadMore() {
    if (!currentList?.nextCursor || pageRequest.current) return;
    const request = new AbortController();
    const generation = scopeGeneration.current;
    pageRequest.current = request;
    setPagePending(true);
    setPageError("");
    try {
      const data = await repository.getHabits({ search: search.trim(), projectId, cursor: currentList.nextCursor, signal: request.signal });
      if (request.signal.aborted || generation !== scopeGeneration.current) return;
      setList((current) => ({
        scope,
        data: { ...data, items: [...new Map([...current.data.items, ...data.items].map((item) => [item.id, item])).values()] },
      }));
    } catch (error) {
      if (!request.signal.aborted) setPageError(getApiErrorMessage(error));
    } finally {
      if (pageRequest.current === request) {
        pageRequest.current = null;
        setPagePending(false);
      }
    }
  }

  function changeScope(setter, value) {
    autoSelect.current = true;
    setSelectedId("");
    setRequestedMonth(null);
    setRequestedYear(null);
    setPreferNearestHistory(true);
    setCalendarError("");
    setSelectionNotice("");
    setter(value);
  }

  function selectHabit(id) {
    setSelectedId(id);
    setRequestedMonth(null);
    setRequestedYear(null);
    setPreferNearestHistory(true);
    setCalendarError("");
    setSelectionNotice("");
    setShowMobileList(false);
  }

  return {
    search, projectId, projects, projectError, selectedId, calendar, calendarError,
    selectionNotice, pageError, pagePending, showMobileList, selectedDate, calendarPanelRef, listPanelRef,
    items: currentList?.items ?? [],
    nextCursor: currentList?.nextCursor,
    listPending: listPending || !currentList && !listError,
    listError,
    calendarPending: Boolean(selectedId) && (calendarPending || !calendar && !calendarError),
    selectedDay: (calendar?.periods ? calendar.periods.flatMap((period) => period.occurrences) : calendar?.days)?.find((day) => day.date === selectedDate),
    setSearch: (value) => { changeScope(setSearch, value); setShowMobileList(true); },
    setProjectId: (value) => changeScope(setProjectId, value),
    selectHabit, loadMore, setSelectedDate, setShowMobileList,
    changeMonth: (offset) => {
      if (!calendar) return;
      const adjacent = adjacentHabitMonths(calendar.availableMonths, calendar.month);
      const month = offset < 0 ? adjacent.previous : adjacent.next;
      if (!month) return;
      setCalendarError("");
      setPreferNearestHistory(false);
      setRequestedMonth(month);
    },
    thisMonth: () => {
      setPreferNearestHistory(false);
      setRequestedMonth(null);
      setRequestedYear(null);
      setCalendarRevision((value) => value + 1);
    },
    changeYear: (offset) => {
      if (!calendar?.periods) return;
      const adjacent = adjacentHabitYears(calendar.availableMonths, calendar.year);
      const year = offset < 0 ? adjacent.previous : adjacent.next;
      if (year === null) return;
      setCalendarError("");
      setPreferNearestHistory(false);
      setRequestedYear(year);
    },
    retryCalendar: () => setCalendarRevision((value) => value + 1),
    retryList: () => { setRequestedMonth(null); setRequestedYear(null); setPreferNearestHistory(true); setListRevision((value) => value + 1); },
    retryProjects: () => setProjectRevision((value) => value + 1),
  };
}
