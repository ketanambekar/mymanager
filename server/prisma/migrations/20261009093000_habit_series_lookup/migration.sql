CREATE INDEX `Task_workspaceId_series_occurrence_idx`
ON `task` (`workspaceId`, `recurrenceSeriesId`, `occurrenceNumber`, `id`);
