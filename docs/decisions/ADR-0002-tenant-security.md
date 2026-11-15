# ADR-0002: Isolamento multi-tenant

- Status: proposta inicial
- Data: 2026-11-15

Toda entidade pertencente a um jogo carrega `tenant_id`. O universo Roblox identifica o tenant no limite de autenticação, mas o `universe_id` recebido só é confiável após validação HMAC. Políticas RLS para usuários autenticados usam `auth.uid()` e a relação `tenants.owner_user_id`; o backend usa a chave privilegiada somente em ambiente server-side.
