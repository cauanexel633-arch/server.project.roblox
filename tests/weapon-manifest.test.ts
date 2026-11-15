import { describe, expect, it } from "vitest";
import { WeaponManifestSchema } from "../packages/shared/src/weapon-manifest.js";

describe("WeaponManifestSchema", () => {
  it("rejects a manifest with an invalid color", () => {
    const result = WeaponManifestSchema.safeParse({
      schema_version: "1.0.0",
      weapon: { name: "Espada", category: "melee.sword", description: "Uma espada de teste", style: "fantasy", rarity: "rare" },
      geometry: { format: "glb", units: "studs", max_triangles: 1000, components: [] },
      materials: [{ id: "steel", base_color: "blue", metallic: 1, roughness: 0.3 }],
      gameplay: { damage: 20, cooldown_seconds: 1, range_studs: 10 },
      provenance: { job_id: "00000000-0000-4000-8000-000000000000", tenant_id: "00000000-0000-4000-8000-000000000001", created_at: "2026-11-15T00:00:00.000Z" }
    });
    expect(result.success).toBe(false);
  });
});
