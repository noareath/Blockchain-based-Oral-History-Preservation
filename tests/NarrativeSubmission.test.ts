import { describe, it, expect, beforeEach } from "vitest";

const ERR_NOT_AUTHORIZED = 100;
const ERR_INVALID_HASH = 101;
const ERR_INVALID_TITLE = 102;
const ERR_INVALID_DESCRIPTION = 103;
const ERR_INVALID_LANGUAGE = 104;
const ERR_INVALID_TAGS = 105;
const ERR_DUPLICATE_NARRATIVE = 106;
const ERR_NARRATIVE_NOT_FOUND = 108;
const ERR_INVALID_IPFS_CID = 111;
const ERR_MAX_NARRATIVES_EXCEEDED = 115;
const ERR_INVALID_NARRATIVE_TYPE = 116;
const ERR_INVALID_DURATION = 117;
const ERR_INVALID_FORMAT = 118;
const ERR_INVALID_SENSITIVITY_LEVEL = 119;
const ERR_INVALID_REWARD_AMOUNT = 121;
const ERR_INVALID_UPDATE_HASH = 114;

interface Narrative {
  contentHash: string;
  ipfsCid: string | null;
  title: string;
  description: string;
  language: string;
  culturalTags: string[];
  timestamp: number;
  submitter: string;
  narrativeType: string;
  duration: number;
  format: string;
  sensitivityLevel: number;
  verificationStatus: boolean;
  rewardAmount: number;
}

interface NarrativeUpdate {
  updateHash: string;
  updateTitle: string;
  updateDescription: string;
  updateTimestamp: number;
  updater: string;
}

class NarrativeSubmissionMock {
  state!: {
    nextNarrativeId: number;
    maxNarratives: number;
    narratives: Map<number, Narrative>;
    narrativesByHash: Map<string, number>;
    narrativeUpdates: Map<number, NarrativeUpdate>;
  };
  blockHeight = 0;
  caller = "ST1TEST";
  verifiedUsers = new Set<string>();

  constructor() {
    this.reset();
  }

  reset() {
    this.state = {
      nextNarrativeId: 0,
      maxNarratives: 10000,
      narratives: new Map(),
      narrativesByHash: new Map(),
      narrativeUpdates: new Map(),
    };
    this.blockHeight = 0;
    this.caller = "ST1TEST";
    this.verifiedUsers.add("ST1TEST");
  }

  isVerifiedUser(principal: string): { ok: boolean; value: boolean } {
    return { ok: true, value: this.verifiedUsers.has(principal) };
  }

  submitNarrative(
    contentHash: string,
    ipfsCid: string | null,
    title: string,
    description: string,
    language: string,
    culturalTags: string[],
    narrativeType: string,
    duration: number,
    format: string,
    sensitivityLevel: number,
    rewardAmount: number
  ): { ok: boolean; value: number | number } {
    const nextId = this.state.nextNarrativeId;
    if (nextId >= this.state.maxNarratives) return { ok: false, value: ERR_MAX_NARRATIVES_EXCEEDED };
    if (contentHash.length !== 64 || !/^[0-9a-fA-F]+$/.test(contentHash)) return { ok: false, value: ERR_INVALID_HASH };
    if (ipfsCid && ipfsCid.length !== 46) return { ok: false, value: ERR_INVALID_IPFS_CID };
    if (!title || title.length > 100) return { ok: false, value: ERR_INVALID_TITLE };
    if (!description || description.length > 500) return { ok: false, value: ERR_INVALID_DESCRIPTION };
    if (!language) return { ok: false, value: ERR_INVALID_LANGUAGE };
    if (culturalTags.length > 10) return { ok: false, value: ERR_INVALID_TAGS };
    if (!["oral-history", "folktale", "myth"].includes(narrativeType)) return { ok: false, value: ERR_INVALID_NARRATIVE_TYPE };
    if (duration > 3600) return { ok: false, value: ERR_INVALID_DURATION };
    if (!["audio", "text", "video"].includes(format)) return { ok: false, value: ERR_INVALID_FORMAT };
    if (sensitivityLevel < 1 || sensitivityLevel > 5) return { ok: false, value: ERR_INVALID_SENSITIVITY_LEVEL };
    if (rewardAmount > 10000) return { ok: false, value: ERR_INVALID_REWARD_AMOUNT };
    if (!this.isVerifiedUser(this.caller).value) return { ok: false, value: ERR_NOT_AUTHORIZED };
    if (this.state.narrativesByHash.has(contentHash)) return { ok: false, value: ERR_DUPLICATE_NARRATIVE };

    const newNarrative: Narrative = {
      contentHash,
      ipfsCid,
      title,
      description,
      language,
      culturalTags,
      timestamp: this.blockHeight,
      submitter: this.caller,
      narrativeType,
      duration,
      format,
      sensitivityLevel,
      verificationStatus: false,
      rewardAmount,
    };
    this.state.narratives.set(nextId, newNarrative);
    this.state.narrativesByHash.set(contentHash, nextId);
    this.state.nextNarrativeId++;
    return { ok: true, value: nextId };
  }

  getNarrative(id: number): { ok: boolean; value: Narrative | null } {
    const narrative = this.state.narratives.get(id);
    return narrative ? { ok: true, value: narrative } : { ok: false, value: null };
  }

  updateNarrative(
    id: number,
    updateHash: string,
    updateTitle: string,
    updateDescription: string
  ): { ok: boolean; value: boolean | number } {
    const narrative = this.state.narratives.get(id);
    if (!narrative) return { ok: false, value: ERR_NARRATIVE_NOT_FOUND };
    if (narrative.submitter !== this.caller) return { ok: false, value: ERR_NOT_AUTHORIZED };
    if (updateHash.length !== 64 || !/^[0-9a-fA-F]+$/.test(updateHash)) return { ok: false, value: ERR_INVALID_UPDATE_HASH };
    if (!updateTitle || updateTitle.length > 100) return { ok: false, value: ERR_INVALID_TITLE };
    if (!updateDescription || updateDescription.length > 500) return { ok: false, value: ERR_INVALID_DESCRIPTION };

    const existingId = this.state.narrativesByHash.get(updateHash);
    if (existingId !== undefined && existingId !== id) return { ok: false, value: ERR_DUPLICATE_NARRATIVE };

    const oldHash = narrative.contentHash;
    this.state.narrativesByHash.delete(oldHash);
    this.state.narrativesByHash.set(updateHash, id);

    const updated: Narrative = {
      ...narrative,
      contentHash: updateHash,
      title: updateTitle,
      description: updateDescription,
      timestamp: this.blockHeight,
    };
    this.state.narratives.set(id, updated);
    this.state.narrativeUpdates.set(id, {
      updateHash,
      updateTitle,
      updateDescription,
      updateTimestamp: this.blockHeight,
      updater: this.caller,
    });
    return { ok: true, value: true };
  }
}

describe("NarrativeSubmission", () => {
  let contract: NarrativeSubmissionMock;
  beforeEach(() => (contract = new NarrativeSubmissionMock()));

  it("submits a valid narrative", () => {
    const result = contract.submitNarrative(
      "a".repeat(64),
      null,
      "Ancient Tale",
      "A story from old times",
      "English",
      ["myth", "legend"],
      "folktale",
      1200,
      "audio",
      3,
      500
    );
    expect(result.ok).toBe(true);
    expect(contract.getNarrative(0).value?.title).toBe("Ancient Tale");
  });

  it("rejects invalid hash", () => {
    const result = contract.submitNarrative(
      "bad",
      null,
      "Title",
      "Desc",
      "Lang",
      [],
      "oral-history",
      600,
      "text",
      2,
      100
    );
    expect(result).toEqual({ ok: false, value: ERR_INVALID_HASH });
  });

  it("rejects invalid IPFS CID", () => {
    const result = contract.submitNarrative(
      "a".repeat(64),
      "invalidcid",
      "Title",
      "Desc",
      "Lang",
      [],
      "oral-history",
      600,
      "text",
      2,
      100
    );
    expect(result).toEqual({ ok: false, value: ERR_INVALID_IPFS_CID });
  });

  it("rejects duplicate narrative", () => {
    contract.submitNarrative(
      "a".repeat(64),
      null,
      "Title1",
      "Desc1",
      "Lang",
      [],
      "oral-history",
      600,
      "text",
      2,
      100
    );
    const result = contract.submitNarrative(
      "a".repeat(64),
      null,
      "Title2",
      "Desc2",
      "Lang",
      [],
      "oral-history",
      600,
      "text",
      2,
      100
    );
    expect(result).toEqual({ ok: false, value: ERR_DUPLICATE_NARRATIVE });
  });

  it("updates a valid narrative", () => {
    contract.submitNarrative(
      "a".repeat(64),
      null,
      "Old Title",
      "Old Desc",
      "Lang",
      [],
      "oral-history",
      600,
      "text",
      2,
      100
    );
    const res = contract.updateNarrative(0, "b".repeat(64), "New Title", "New Desc");
    expect(res.ok).toBe(true);
    expect(contract.getNarrative(0).value?.title).toBe("New Title");
  });

  it("rejects update for non-existent narrative", () => {
    const res = contract.updateNarrative(99, "b".repeat(64), "New Title", "New Desc");
    expect(res).toEqual({ ok: false, value: ERR_NARRATIVE_NOT_FOUND });
  });
});