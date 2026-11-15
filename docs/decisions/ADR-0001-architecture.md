# ADR-0001: Arquitetura inicial

- Status: proposta inicial
- Data: 2026-11-15

## Decisão
Usar TypeScript strict, Node.js em Vercel Functions, Supabase PostgreSQL/Storage/Queues, Zod e Vitest.

## Execução assíncrona
Supabase Queues (pgmq) é a fila definida pela especificação. Não adicionar Inngest, Redis ou outro provedor de filas.

## Segurança
Credenciais privilegiadas Supabase permanecem exclusivamente no backend. Toda tabela do schema exposto recebe RLS. Dados do jogo são sempre isolados por `tenant_id`.

## Limitações desta entrega
O bootstrap ainda não contém pipeline de geração, worker, agentes, geometria, integração OpenRouter ou integração Roblox. Essas fases não devem ser consideradas implementadas.
