-- Forge3D Cloud V2 — persistence foundation
-- Review before applying to any hosted database.
create extension if not exists pgcrypto;
create extension if not exists vector with schema extensions;

create table if not exists public.tenants (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid references auth.users(id) on delete set null,
  universe_id bigint not null unique,
  name text not null,
  credentials_ref text,
  settings jsonb not null default '{}'::jsonb,
  rate_limits jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.players (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  roblox_user_id bigint not null,
  username text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique (tenant_id, roblox_user_id),
  unique (tenant_id, id)
);

create table if not exists public.weapons (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  player_id uuid,
  name text not null,
  category text not null,
  status text not null default 'draft' check (status in ('draft','generating','approved','rejected','archived')),
  current_version integer,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (tenant_id, id),
  foreign key (tenant_id, player_id) references public.players(tenant_id, id)
);

create table if not exists public.weapon_versions (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  weapon_id uuid not null,
  version integer not null check (version > 0),
  manifest jsonb not null,
  manifest_sha256 text not null,
  quality_score numeric(5,4),
  created_at timestamptz not null default now(),
  unique (weapon_id, version),
  unique (tenant_id, id),
  foreign key (tenant_id, weapon_id) references public.weapons(tenant_id, id) on delete cascade
);

create table if not exists public.assets (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  weapon_version_id uuid,
  bucket_id text not null,
  object_path text not null,
  asset_kind text not null,
  mime_type text not null,
  size_bytes bigint not null check (size_bytes >= 0),
  sha256 text not null,
  version integer not null default 1,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique (bucket_id, object_path),
  unique (tenant_id, id),
  foreign key (tenant_id, weapon_version_id) references public.weapon_versions(tenant_id, id) on delete cascade
);

create table if not exists public.generation_jobs (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  player_id uuid,
  weapon_id uuid,
  status text not null default 'queued' check (status in ('queued','running','waiting','completed','failed','cancelled')),
  current_stage text,
  progress integer not null default 0 check (progress between 0 and 100),
  request jsonb not null,
  idempotency_key text,
  trace_id uuid not null default gen_random_uuid(),
  error jsonb,
  created_at timestamptz not null default now(),
  started_at timestamptz,
  completed_at timestamptz,
  unique (tenant_id, id),
  unique (tenant_id, idempotency_key),
  foreign key (tenant_id, player_id) references public.players(tenant_id, id),
  foreign key (tenant_id, weapon_id) references public.weapons(tenant_id, id)
);

create table if not exists public.generation_stages (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  job_id uuid not null,
  stage_key text not null,
  status text not null default 'pending' check (status in ('pending','queued','running','waiting','completed','failed','skipped')),
  attempt integer not null default 0,
  checkpoint jsonb,
  input_hash text,
  output_hash text,
  started_at timestamptz,
  completed_at timestamptz,
  error jsonb,
  created_at timestamptz not null default now(),
  unique (job_id, stage_key),
  foreign key (tenant_id, job_id) references public.generation_jobs(tenant_id, id) on delete cascade
);

create table if not exists public.agent_runs (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  job_id uuid not null,
  stage_id uuid,
  agent_name text not null,
  model_id text,
  status text not null,
  attempt integer not null default 1,
  input_artifact_ids uuid[] not null default '{}',
  output jsonb,
  token_usage jsonb,
  latency_ms integer,
  created_at timestamptz not null default now(),
  foreign key (tenant_id, job_id) references public.generation_jobs(tenant_id, id) on delete cascade,
  foreign key (tenant_id, stage_id) references public.generation_stages(tenant_id, id)
);

create table if not exists public.security_audits (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  job_id uuid not null,
  weapon_version_id uuid,
  status text not null check (status in ('pending','approved','rejected','needs_review')),
  findings jsonb not null default '[]'::jsonb,
  auditor_version text not null,
  created_at timestamptz not null default now(),
  foreign key (tenant_id, job_id) references public.generation_jobs(tenant_id, id) on delete cascade,
  foreign key (tenant_id, weapon_version_id) references public.weapon_versions(tenant_id, id)
);

create table if not exists public."references" (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  job_id uuid,
  url text not null,
  title text,
  source_type text,
  summary text,
  confidence numeric(5,4),
  consulted_at timestamptz not null default now(),
  metadata jsonb not null default '{}'::jsonb,
  foreign key (tenant_id, job_id) references public.generation_jobs(tenant_id, id) on delete cascade
);

create table if not exists public.library_embeddings (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  weapon_version_id uuid not null,
  embedding extensions.vector(1536),
  searchable_text text not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique (tenant_id, weapon_version_id),
  foreign key (tenant_id, weapon_version_id) references public.weapon_versions(tenant_id, id) on delete cascade
);

create table if not exists public.feedback (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  weapon_id uuid not null,
  player_id uuid,
  rating smallint check (rating between 1 and 5),
  comment text,
  created_at timestamptz not null default now(),
  foreign key (tenant_id, weapon_id) references public.weapons(tenant_id, id) on delete cascade,
  foreign key (tenant_id, player_id) references public.players(tenant_id, id)
);

create table if not exists public.idempotency_keys (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  key text not null,
  request_hash text not null,
  response jsonb,
  expires_at timestamptz not null,
  created_at timestamptz not null default now(),
  unique (tenant_id, key)
);

create table if not exists public.audit_events (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid references public.tenants(id) on delete cascade,
  actor_type text not null,
  actor_id text,
  event_type text not null,
  resource_type text,
  resource_id text,
  trace_id uuid,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.model_catalog (
  id text primary key,
  provider text not null,
  model_name text not null,
  is_free boolean not null default false,
  supports_tools boolean not null default false,
  supports_vision boolean not null default false,
  context_length integer,
  metadata jsonb not null default '{}'::jsonb,
  checked_at timestamptz,
  enabled boolean not null default true
);

create table if not exists public.rate_limits (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  subject_type text not null,
  subject_id text not null,
  window_started_at timestamptz not null,
  request_count integer not null default 0,
  token_count bigint not null default 0,
  updated_at timestamptz not null default now(),
  unique (tenant_id, subject_type, subject_id, window_started_at)
);

create index if not exists idx_players_tenant on public.players(tenant_id);
create index if not exists idx_weapons_tenant_status on public.weapons(tenant_id, status);
create index if not exists idx_jobs_tenant_status_created on public.generation_jobs(tenant_id, status, created_at desc);
create index if not exists idx_stages_tenant_job_status on public.generation_stages(tenant_id, job_id, status);
create index if not exists idx_assets_tenant_kind on public.assets(tenant_id, asset_kind);
create index if not exists idx_audit_events_tenant_created on public.audit_events(tenant_id, created_at desc);
create index if not exists idx_library_embeddings_tenant on public.library_embeddings(tenant_id);

-- RLS is enabled on every table in the exposed public schema.
do $$
declare
  t text;
begin
  foreach t in array array[
    'tenants','players','weapons','weapon_versions','assets','generation_jobs',
    'generation_stages','agent_runs','security_audits','references',
    'library_embeddings','feedback','idempotency_keys','audit_events',
    'model_catalog','rate_limits'
  ] loop
    execute format('alter table public.%I enable row level security', t);
  end loop;
end $$;

-- Authenticated dashboard owners can access only their own tenant data.
create policy "tenant owners can read own tenant"
on public.tenants for select to authenticated
using (owner_user_id = (select auth.uid()));

create policy "tenant owners can update own tenant"
on public.tenants for update to authenticated
using (owner_user_id = (select auth.uid()))
with check (owner_user_id = (select auth.uid()));

do $$
declare
  t text;
begin
  foreach t in array array[
    'players','weapons','weapon_versions','assets','generation_jobs',
    'generation_stages','agent_runs','security_audits','references',
    'library_embeddings','feedback','idempotency_keys','audit_events','rate_limits'
  ] loop
    execute format(
      'create policy %I on public.%I for all to authenticated using (exists (select 1 from public.tenants x where x.id = tenant_id and x.owner_user_id = (select auth.uid()))) with check (exists (select 1 from public.tenants x where x.id = tenant_id and x.owner_user_id = (select auth.uid())))',
      'tenant owner access ' || t, t
    );
  end loop;
end $$;

-- Model catalog is operational metadata; keep it server-only by default.
revoke all on public.model_catalog from anon, authenticated;
grant all on public.model_catalog to service_role;

-- Private buckets; object paths must start with the tenant UUID.
insert into storage.buckets (id, name, public)
values
  ('meshes','meshes',false),
  ('textures','textures',false),
  ('animations','animations',false),
  ('packages','packages',false),
  ('references','references',false),
  ('previews','previews',false),
  ('scripts','scripts',false)
on conflict (id) do update set public = false;

create policy "tenant owners read own forge objects"
on storage.objects for select to authenticated
using (
  bucket_id in ('meshes','textures','animations','packages','references','previews','scripts')
  and exists (
    select 1 from public.tenants t
    where t.id::text = (storage.foldername(name))[1]
      and t.owner_user_id = (select auth.uid())
  )
);

create policy "tenant owners insert own forge objects"
on storage.objects for insert to authenticated
with check (
  bucket_id in ('meshes','textures','animations','packages','references','previews','scripts')
  and exists (
    select 1 from public.tenants t
    where t.id::text = (storage.foldername(name))[1]
      and t.owner_user_id = (select auth.uid())
  )
);

create policy "tenant owners update own forge objects"
on storage.objects for update to authenticated
using (
  bucket_id in ('meshes','textures','animations','packages','references','previews','scripts')
  and exists (
    select 1 from public.tenants t
    where t.id::text = (storage.foldername(name))[1]
      and t.owner_user_id = (select auth.uid())
  )
)
with check (
  bucket_id in ('meshes','textures','animations','packages','references','previews','scripts')
  and exists (
    select 1 from public.tenants t
    where t.id::text = (storage.foldername(name))[1]
      and t.owner_user_id = (select auth.uid())
  )
);

create policy "tenant owners delete own forge objects"
on storage.objects for delete to authenticated
using (
  bucket_id in ('meshes','textures','animations','packages','references','previews','scripts')
  and exists (
    select 1 from public.tenants t
    where t.id::text = (storage.foldername(name))[1]
      and t.owner_user_id = (select auth.uid())
  )
);
