"use client";

import { FormEvent, useMemo, useState } from "react";
import { Sparkles } from "lucide-react";
import { Button } from "@/components/ui/button";
import { MasterCollections } from "@/types/dashboard";

type MasterTab = "projectTypes" | "priorities" | "colors";

type MastersTabsProps = {
  masters: MasterCollections;
  isLoading: boolean;
  onCreateProjectType: (name: string, emoji?: string) => Promise<void>;
  onUpdateProjectType: (id: number, name: string, emoji?: string) => Promise<void>;
  onCreatePriority: (code: string, title: string) => Promise<void>;
  onUpdatePriority: (id: number, code: string, title: string) => Promise<void>;
  onCreateColor: (name: string, hexCode: string) => Promise<void>;
  onUpdateColor: (id: number, name: string, hexCode: string) => Promise<void>;
  onDeleteColor: (id: number) => Promise<void>;
};

const tabs: Array<{ key: MasterTab; label: string }> = [
  { key: "projectTypes", label: "Project Types" },
  { key: "priorities", label: "Priorities" },
  { key: "colors", label: "Colors" },
];

function createRandomColorName(existingLabels: string[]): string {
  const existing = new Set(existingLabels.map((label) => label.toLowerCase()));

  for (let i = 0; i < 20; i += 1) {
    const candidate = `color_${Math.random().toString(36).slice(2, 8)}`;
    if (!existing.has(candidate)) {
      return candidate;
    }
  }

  return `color_${Date.now()}`;
}

export function MastersTabs({
  masters,
  isLoading,
  onCreateProjectType,
  onUpdateProjectType,
  onCreatePriority,
  onUpdatePriority,
  onCreateColor,
  onUpdateColor,
  onDeleteColor,
}: MastersTabsProps) {
  function toEmojiValue(rawValue: string): string {
    const trimmed = rawValue.trim();
    if (!trimmed || /^https?:\/\//i.test(trimmed)) {
      return "";
    }

    return trimmed;
  }

  function getTypeGlyph(iconUrl: string | null | undefined, label: string): string {
    const candidate = iconUrl?.trim() ?? "";
    if (!candidate || /^https?:\/\//i.test(candidate)) {
      return label.slice(0, 1).toUpperCase();
    }

    return candidate;
  }

  const compactInputClassName =
    "h-9 rounded-md border border-[var(--border)] bg-[var(--surface-muted)] px-2.5 text-sm outline-none focus:border-[var(--brand-orange)]";
  const compactButtonClassName =
    "h-9 rounded-md border border-[var(--border)] bg-[var(--surface)] px-3 text-xs font-semibold text-[var(--ink)] transition-colors hover:border-[var(--brand-orange)] disabled:cursor-not-allowed disabled:opacity-50";

  const [activeTab, setActiveTab] = useState<MasterTab>("projectTypes");

  const [newTypeName, setNewTypeName] = useState("");
  const [newTypeEmoji, setNewTypeEmoji] = useState("");
  const [editingTypeId, setEditingTypeId] = useState<number | null>(null);
  const [editingTypeName, setEditingTypeName] = useState("");
  const [editingTypeEmoji, setEditingTypeEmoji] = useState("");

  const [newPriorityCode, setNewPriorityCode] = useState("");
  const [newPriorityTitle, setNewPriorityTitle] = useState("");
  const [editingPriorityId, setEditingPriorityId] = useState<number | null>(null);
  const [editingPriorityCode, setEditingPriorityCode] = useState("");
  const [editingPriorityTitle, setEditingPriorityTitle] = useState("");

  const [newColorHex, setNewColorHex] = useState("#F97316");
  const [editingColorId, setEditingColorId] = useState<number | null>(null);
  const [editingColorHex, setEditingColorHex] = useState("#F97316");

  const tabCounts = useMemo(
    () => ({
      projectTypes: masters.projectTypes.length,
      priorities: masters.priorities.length,
      colors: masters.colors.length,
    }),
    [masters],
  );

  async function submitProjectType(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!newTypeName.trim()) {
      return;
    }

    await onCreateProjectType(newTypeName, toEmojiValue(newTypeEmoji) || undefined);
    setNewTypeName("");
    setNewTypeEmoji("");
  }

  async function submitPriority(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!newPriorityCode.trim() || !newPriorityTitle.trim()) {
      return;
    }

    await onCreatePriority(newPriorityCode, newPriorityTitle);
    setNewPriorityCode("");
    setNewPriorityTitle("");
  }

  async function submitColor(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();

    const normalizedHex = newColorHex.trim().toUpperCase();
    if (!/^#([A-Fa-f0-9]{6})$/.test(normalizedHex)) {
      return;
    }

    if (masters.colors.some((color) => color.hexCode.toUpperCase() === normalizedHex)) {
      return;
    }

    const generatedName = createRandomColorName(masters.colors.map((color) => color.label));
    await onCreateColor(generatedName, normalizedHex);
  }

  return (
    <section className="rounded-xl border border-[var(--border)] bg-[var(--paper-elevated)] p-3">
      <div className="mb-3 flex items-center gap-2">
        <Sparkles className="h-4 w-4 text-[var(--brand-orange)]" />
        <h3 className="text-base font-extrabold">Master Data</h3>
      </div>

      <div className="mb-3 flex flex-wrap gap-2">
        {tabs.map((tab) => (
          <button
            key={tab.key}
            type="button"
            onClick={() => setActiveTab(tab.key)}
            className={
              activeTab === tab.key
                ? "rounded-md border border-[var(--border-strong)] bg-[var(--surface)] px-2.5 py-1.5 text-xs font-semibold text-[var(--ink)]"
                : "rounded-md border border-[var(--border)] bg-[var(--surface-muted)] px-2.5 py-1.5 text-xs font-semibold text-[var(--muted)]"
            }
          >
            {tab.label} ({tabCounts[tab.key]})
          </button>
        ))}
      </div>

      {activeTab === "projectTypes" ? (
        <div className="space-y-3">
          <form className="flex flex-wrap items-center gap-2" onSubmit={submitProjectType}>
            <input
              className={`${compactInputClassName} min-w-[220px] flex-1`}
              value={newTypeName}
              onChange={(event) => setNewTypeName(event.target.value)}
              placeholder="Project type"
            />
            <input
              className={`${compactInputClassName} min-w-[260px] flex-1`}
              value={newTypeEmoji}
              onChange={(event) => setNewTypeEmoji(event.target.value)}
              placeholder="Emoji (optional) e.g. 🚀"
            />
            <button type="submit" className={compactButtonClassName} disabled={isLoading || !newTypeName.trim()}>
              Add
            </button>
          </form>

          <div className="space-y-2">
            {masters.projectTypes.map((typeItem) => (
              <div key={typeItem.id} className="rounded-md border border-[var(--border)] bg-[var(--surface-muted)] p-2.5">
                {editingTypeId === typeItem.id ? (
                  <div className="grid gap-2 sm:grid-cols-[minmax(0,1fr),minmax(0,1fr),auto,auto]">
                    <input
                      className="h-9 rounded-md border border-[var(--border)] bg-[var(--paper-elevated)] px-2.5 outline-none focus:border-[var(--brand-orange)]"
                      value={editingTypeName}
                      onChange={(event) => setEditingTypeName(event.target.value)}
                    />
                    <input
                      className="h-9 rounded-md border border-[var(--border)] bg-[var(--paper-elevated)] px-2.5 outline-none focus:border-[var(--brand-orange)]"
                      value={editingTypeEmoji}
                      onChange={(event) => setEditingTypeEmoji(event.target.value)}
                      placeholder="Emoji (optional) e.g. 🎯"
                    />
                    <Button
                      type="button"
                      disabled={isLoading || !editingTypeName.trim()}
                      onClick={async () => {
                        await onUpdateProjectType(typeItem.id, editingTypeName, toEmojiValue(editingTypeEmoji) || undefined);
                        setEditingTypeId(null);
                        setEditingTypeName("");
                        setEditingTypeEmoji("");
                      }}
                    >
                      Save
                    </Button>
                    <Button
                      type="button"
                      variant="secondary"
                      onClick={() => {
                        setEditingTypeId(null);
                        setEditingTypeName("");
                        setEditingTypeEmoji("");
                      }}
                    >
                      Cancel
                    </Button>
                  </div>
                ) : (
                  <div className="flex items-center justify-between gap-2">
                    <div className="flex items-center gap-2">
                      <div className="grid h-8 w-8 place-items-center rounded-md border border-[var(--border)] bg-[var(--paper)] text-lg leading-none">
                        {getTypeGlyph(typeItem.iconUrl, typeItem.label)}
                      </div>
                      <p className="text-sm font-semibold text-[var(--ink)]">{typeItem.label}</p>
                    </div>
                    <Button
                      type="button"
                      variant="secondary"
                      onClick={() => {
                        setEditingTypeId(typeItem.id);
                        setEditingTypeName(typeItem.label);
                        setEditingTypeEmoji(typeItem.iconUrl ?? "");
                      }}
                    >
                      Edit
                    </Button>
                  </div>
                )}
              </div>
            ))}
          </div>
        </div>
      ) : null}

      {activeTab === "priorities" ? (
        <div className="space-y-3">
          <form className="flex flex-wrap items-center gap-2" onSubmit={submitPriority}>
            <input
              className={`${compactInputClassName} w-[88px]`}
              value={newPriorityCode}
              onChange={(event) => setNewPriorityCode(event.target.value.toUpperCase())}
              placeholder="Code"
            />
            <input
              className={`${compactInputClassName} min-w-[220px] flex-1`}
              value={newPriorityTitle}
              onChange={(event) => setNewPriorityTitle(event.target.value)}
              placeholder="Title"
            />
            <button
              type="submit"
              className={compactButtonClassName}
              disabled={isLoading || !newPriorityCode.trim() || !newPriorityTitle.trim()}
            >
              Add
            </button>
          </form>

          <div className="space-y-2">
            {masters.priorities.map((priority) => (
              <div key={priority.id} className="rounded-md border border-[var(--border)] bg-[var(--surface-muted)] p-2.5">
                {editingPriorityId === priority.id ? (
                  <div className="grid gap-2 sm:grid-cols-[120px,minmax(0,1fr),auto,auto]">
                    <input
                      className="h-9 rounded-md border border-[var(--border)] bg-[var(--paper-elevated)] px-2.5 outline-none focus:border-[var(--brand-orange)]"
                      value={editingPriorityCode}
                      onChange={(event) => setEditingPriorityCode(event.target.value.toUpperCase())}
                    />
                    <input
                      className="h-9 rounded-md border border-[var(--border)] bg-[var(--paper-elevated)] px-2.5 outline-none focus:border-[var(--brand-orange)]"
                      value={editingPriorityTitle}
                      onChange={(event) => setEditingPriorityTitle(event.target.value)}
                    />
                    <Button
                      type="button"
                      disabled={isLoading || !editingPriorityCode.trim() || !editingPriorityTitle.trim()}
                      onClick={async () => {
                        await onUpdatePriority(priority.id, editingPriorityCode, editingPriorityTitle);
                        setEditingPriorityId(null);
                        setEditingPriorityCode("");
                        setEditingPriorityTitle("");
                      }}
                    >
                      Save
                    </Button>
                    <Button
                      type="button"
                      variant="secondary"
                      onClick={() => {
                        setEditingPriorityId(null);
                        setEditingPriorityCode("");
                        setEditingPriorityTitle("");
                      }}
                    >
                      Cancel
                    </Button>
                  </div>
                ) : (
                  <div className="flex items-center justify-between gap-2">
                    <p className="text-sm font-semibold text-[var(--ink)]">
                      {priority.code} - {priority.title}
                    </p>
                    <Button
                      type="button"
                      variant="secondary"
                      onClick={() => {
                        setEditingPriorityId(priority.id);
                        setEditingPriorityCode(priority.code);
                        setEditingPriorityTitle(priority.title);
                      }}
                    >
                      Edit
                    </Button>
                  </div>
                )}
              </div>
            ))}
          </div>
        </div>
      ) : null}

      {activeTab === "colors" ? (
        <div className="space-y-3">
          <form className="flex flex-wrap items-center gap-2" onSubmit={submitColor}>
            <input
              type="color"
              className="h-9 w-12 cursor-pointer rounded-md border border-[var(--border)] bg-[var(--surface-muted)] p-1"
              value={newColorHex}
              onChange={(event) => setNewColorHex(event.target.value.toUpperCase())}
              aria-label="Select color"
            />
            <button
              type="submit"
              className={compactButtonClassName}
              disabled={isLoading || !/^#([A-Fa-f0-9]{6})$/.test(newColorHex)}
            >
              Add
            </button>
          </form>

          <div className="space-y-2">
            {masters.colors.map((color) => (
              <div key={color.id} className="rounded-md border border-[var(--border)] bg-[var(--surface-muted)] p-2.5">
                {editingColorId === color.id ? (
                  <div className="grid gap-2 sm:grid-cols-[auto,auto,auto] sm:justify-start">
                    <input
                      type="color"
                      className="h-9 w-12 cursor-pointer rounded-md border border-[var(--border)] bg-[var(--paper-elevated)] p-1"
                      value={editingColorHex}
                      onChange={(event) => setEditingColorHex(event.target.value.toUpperCase())}
                      aria-label="Edit color"
                    />
                    <Button
                      type="button"
                      disabled={isLoading || !/^#([A-Fa-f0-9]{6})$/.test(editingColorHex)}
                      onClick={async () => {
                        await onUpdateColor(color.id, color.label, editingColorHex);
                        setEditingColorId(null);
                        setEditingColorHex("#F97316");
                      }}
                    >
                      Save
                    </Button>
                    <Button
                      type="button"
                      variant="secondary"
                      onClick={() => {
                        setEditingColorId(null);
                        setEditingColorHex("#F97316");
                      }}
                    >
                      Cancel
                    </Button>
                  </div>
                ) : (
                  <div className="flex items-center justify-between gap-2">
                    <div className="flex items-center gap-2">
                      <span className="inline-block h-4 w-4 rounded-full border border-[var(--border)]" style={{ backgroundColor: color.hexCode }} />
                      <p className="text-sm font-semibold text-[var(--ink)]">{color.hexCode}</p>
                    </div>

                    <div className="flex items-center gap-2">
                      <Button
                        type="button"
                        variant="secondary"
                        onClick={() => {
                          setEditingColorId(color.id);
                          setEditingColorHex(color.hexCode.toUpperCase());
                        }}
                      >
                        Edit
                      </Button>
                      <Button
                        type="button"
                        variant="secondary"
                        disabled={isLoading}
                        onClick={async () => {
                          await onDeleteColor(color.id);
                        }}
                      >
                        Delete
                      </Button>
                    </div>
                  </div>
                )}
              </div>
            ))}
          </div>
        </div>
      ) : null}
    </section>
  );
}
