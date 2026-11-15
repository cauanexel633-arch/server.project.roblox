# Forge3D Cloud V2

Backend modular para geração e gerenciamento de assets 3D destinados ao Roblox.

## Estado inicial

Este repositório contém o bootstrap da Fase 1: monorepo TypeScript, API para Vercel, contratos compartilhados, persistência Supabase, isolamento multi-tenant, OpenAPI e pipeline de CI.

## Requisitos

- Node.js 22+
- pnpm 9+
- Projeto Supabase configurado

## Desenvolvimento

```bash
pnpm install
pnpm test
pnpm typecheck
```

## Segurança

Segredos e credenciais administrativas permanecem exclusivamente no servidor. Nunca exponha `SUPABASE_SERVICE_ROLE_KEY` ao cliente Roblox.

A migração em `supabase/migrations` ainda precisa ser revisada e aplicada explicitamente ao projeto Supabase de destino.
