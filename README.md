# AlojaMatch — etapa 2

Aplicação React/Vite ligada ao Supabase. Inclui criação de conta, sessão, papel de candidato ou proprietário, contacto privado, perfil de procura, publicação e pesquisa de alojamentos, envio de propostas, aceitação/recusa e consulta de contactos de acordo com o estado da proposta.

## Regra dos contactos

1. O proprietário guarda o seu contacto privado e envia uma proposta de um alojamento a um candidato. Só esse candidato pode consultar o contacto do proprietário.
2. O candidato pode aceitar ou recusar. Para aceitar, tem de guardar o seu contacto privado. Apenas após a aceitação, o proprietário que enviou a proposta pode consultar o contacto do candidato.
3. Os contactos são guardados numa tabela privada. A função `proposal_contact` verifica a identidade e o estado da proposta na base de dados. A interface não recebe os contactos por uma consulta geral.

## Instalar e executar

Requer Node.js 22 ou superior.

1. Criar um projeto Supabase e executar `supabase/schema.sql` no SQL Editor de um projeto **novo**.
2. Copiar `.env.example` para `.env` e preencher `VITE_SUPABASE_URL` e `VITE_SUPABASE_PUBLISHABLE_KEY` com a URL e a chave **publicável** do projeto. Nunca usar a chave `service_role` no site.
3. Em Supabase Auth, configurar o URL do site e os URLs de redirecionamento. O registo por email pode exigir confirmação da caixa de correio.
4. Executar `npm ci` e `npm run dev`. Para validar a publicação, executar `npm run build`.
5. Criar um repositório GitHub e colocar estes ficheiros na raiz. Nas definições do repositório, selecionar GitHub Pages → GitHub Actions. Criar as variáveis do repositório `VITE_SUPABASE_URL`, `VITE_SUPABASE_PUBLISHABLE_KEY` e `VITE_BASE_PATH`. Usar `/nome-do-repositorio/` para o endereço `utilizador.github.io/nome-do-repositorio/`; usar `/` quando o domínio próprio estiver associado. Enviar para a branch `main`.

## Teste manual essencial

- Criar duas contas distintas, uma como candidato e outra como proprietário. Cada uma define o seu contacto privado.
- Candidato publica perfil; proprietário publica alojamento e envia uma proposta.
- Antes da aceitação: candidato consegue consultar contacto do proprietário; proprietário não consegue consultar contacto do candidato.
- Após aceitação: proprietário consegue consultar contacto do candidato. Uma terceira conta não consegue consultar nenhum dos contactos pela proposta.
- Verificar também que um candidato não consegue enviar propostas e que um proprietário não consegue aceitar propostas alheias.

## Limites desta etapa

Não há ainda fotografias, favoritos, denúncias, administração, pesquisa geográfica avançada ou documentação completa de privacidade/RGPD. A plataforma não deve ser aberta ao público antes de acrescentar moderação, informação de privacidade, mecanismos de eliminação/exportação de dados, proteção contra abuso e testes no projeto Supabase efetivo. Não há dados fictícios nesta versão. A publicidade e as aplicações móveis ficam para fases posteriores.
