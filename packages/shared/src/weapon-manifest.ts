import { z } from "zod";

const HexColor = z.string().regex(/^#[0-9A-Fa-f]{6}$/);

export const WeaponManifestSchema = z.object({
  schema_version: z.literal("1.0.0"),
  weapon: z.object({
    name: z.string().trim().min(2).max(80),
    category: z.enum(["melee.sword", "melee.axe", "melee.staff", "ranged.bow", "ranged.firearm", "melee.gauntlet"]),
    description: z.string().trim().min(10).max(2000),
    style: z.string().trim().min(2).max(80),
    rarity: z.enum(["common", "uncommon", "rare", "epic", "legendary"]),
  }),
  geometry: z.object({
    format: z.enum(["glb", "gltf", "obj", "rbxmx"]),
    units: z.literal("studs"),
    max_triangles: z.number().int().min(12).max(100_000),
    components: z.array(z.object({
      id: z.string().regex(/^[a-z0-9][a-z0-9_-]{0,63}$/),
      role: z.enum(["handle", "blade", "guard", "ornament", "core", "other"]),
      material_id: z.string().min(1).max(64),
      transform: z.object({
        position: z.tuple([z.number(), z.number(), z.number()]),
        rotation: z.tuple([z.number(), z.number(), z.number()]),
        scale: z.tuple([z.number().positive(), z.number().positive(), z.number().positive()]),
      }),
    }).max(128)),
  }),
  materials: z.array(z.object({
    id: z.string().min(1).max(64),
    base_color: HexColor,
    metallic: z.number().min(0).max(1),
    roughness: z.number().min(0).max(1),
    emissive_color: HexColor.optional(),
    emissive_strength: z.number().min(0).max(20).default(0),
  })).min(1).max(16),
  gameplay: z.object({
    damage: z.number().min(0).max(500),
    cooldown_seconds: z.number().min(0.05).max(120),
    range_studs: z.number().min(0).max(500),
  }),
  provenance: z.object({
    job_id: z.string().uuid(),
    tenant_id: z.string().uuid(),
    created_at: z.string().datetime(),
  }),
}).strict();

export type WeaponManifest = z.infer<typeof WeaponManifestSchema>;
export const WeaponManifestJsonSchema = z.toJSONSchema(WeaponManifestSchema);
