import { useEffect, useState } from "react";
import { getApiErrorMessage } from "@/services/api_client.js";
import { getReport } from "./report_repository.js";

export function useReportController() {
  const [requestedYear, setRequestedYear] = useState(null);
  const [revision, setRevision] = useState(0);
  const [result, setResult] = useState(null);
  const [errorResult, setErrorResult] = useState(null);
  const key = JSON.stringify([requestedYear, revision]);
  const report = result?.key === key ? result.data : null;
  const error = errorResult?.key === key ? errorResult.message : "";

  useEffect(() => {
    const request = new AbortController();
    getReport(requestedYear, request.signal)
      .then((data) => {
        if (!request.signal.aborted) setResult({ key, data });
      })
      .catch((cause) => {
        if (!request.signal.aborted) setErrorResult({ key, message: getApiErrorMessage(cause) });
      });
    return () => request.abort();
  }, [key, requestedYear]);

  return {
    report, error,
    isLoading: !report && !error,
    year: requestedYear ?? result?.data.year ?? "",
    selectYear: (year) => setRequestedYear(Number(year)),
    refresh: () => setRevision((value) => value + 1),
  };
}
