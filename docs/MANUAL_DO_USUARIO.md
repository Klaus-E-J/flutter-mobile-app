# Manual do Usuário — Avalia Pro (Entrega N3)

Bem-vindo ao **Avalia Pro**, o sistema mobile completo para criação de avaliações, geração de variantes antifraude, folhas de resposta OMR com QR Code, correção automatizada por visão computacional e análise estatística pedagógica.

---

## Sumário

1. [Acesso e Perfil do Professor](#1-acesso-e-perfil-do-professor)
2. [Gestão de Turmas e Alunos (Cadastro e Importação CSV/Excel)](#2-gestão-de-turmas-e-alunos-cadastro-e-importação-csvexcel)
3. [Criação de Provas, Questões e Gabarito Rápido (Prova Externa)](#3-criação-de-provas-questões-e-gabarito-rápido-prova-externa)
4. [Geração de Variantes, Folhas OMR Nominais, PDF sem Cortes e Word (.doc)](#4-geração-de-variantes-folhas-omr-nominais-pdf-sem-cortes-e-word-doc)
5. [Correção OMR por Câmera / Imagem e Revisão Interativa](#5-correção-omr-por-câmera--imagem-e-revisão-interativa)
6. [Resultados, Estatísticas por Alternativa e Exportação (.xlsx / .csv)](#6-resultados-estatísticas-por-alternativa-e-exportação-xlsx--csv)

---

## 1. Acesso e Perfil do Professor

1. Na tela inicial (**Acesso do Professor**), você pode:
   - **Entrar com E-mail e Senha**;
   - **Criar uma nova conta** informando Nome, Escola/Instituição, E-mail e Senha;
   - **Recuperar senha** por e-mail;
   - **Continuar como Convidado** (sessão anônima no Firebase).
2. Em **Configurações** (menu `Mais > Configurações`):
   - Toque no ícone de lápis (**Editar perfil**) no cabeçalho para atualizar seu **Nome de exibição** e **Escola / Instituição**.
   - Expanda **Acesso e código institucional** para visualizar ou regenerar seu código único (`PROF-XXXX`).

---

## 2. Gestão de Turmas e Alunos (Cadastro e Importação CSV/Excel)

1. Acesse a aba **Turmas** na barra inferior.
2. Toque em **Nova turma**, informe o **Nome da turma** (ex.: `3º Ano A`) e a **Série** (ex.: `3º Ano do Ensino Médio`).
3. No cartão de cada turma, utilize o menu de opções (`⋮`) para **Editar turma** (sincronizando automaticamente o nome nas provas e resultados vinculados) ou **Excluir turma**.
4. Toque sobre a turma para abrir a lista de alunos:
   - **Adicionar aluno manualmente:** informe Nome, Matrícula (opcional) e E-mail (opcional).
   - **Importar lista (CSV/Excel):** selecione um arquivo `.csv`, `.xlsx` ou `.xls` (para CSV, separado por `;`, `,` ou tabulação). O sistema remove duplicados automaticamente e exibe uma pré-visualização antes de salvar em lote.
   - **Editar ou remover aluno:** utilize os ícones de edição ou exclusão ao lado de cada aluno.

---

## 3. Criação de Provas, Questões e Gabarito Rápido (Prova Externa)

1. Acesse a aba **Provas** e toque em **Nova prova**.
2. Informe o **Nome da prova**, selecione uma ou mais **Turmas** e escolha o **Modo da prova**:
   - **Mesma prova para todos:** gera cadernos de prova padronizados ou variantes (A, B, C, D).
   - **Provas diferentes por aluno:** gera um caderno exclusivo para cada aluno cadastrado na turma.
3. Você possui duas formas de definir as questões e o gabarito (limite de até **30 questões** por folha OMR, com até **5 alternativas A–E**):
   - **Opção A — Gerenciar questões (Prova Completa):** digite o enunciado e o texto das alternativas `A` a `E`, marcando a alternativa correta de cada questão.
   - **Opção B — Gabarito Rápido (Prova Externa):** ideal quando você já diagramou a prova no Word/PDF fora do sistema e deseja usar o Avalia Pro apenas para gerar a folha de respostas com QR Code e corrigir automaticamente. Basta informar o número de questões (`1` a `30`), escolher a quantidade de alternativas (`A–D` ou `A–E`) e tocar na letra correta de cada questão na grade rápida.

---

## 4. Geração de Variantes, Folhas OMR Nominais, PDF sem Cortes e Word (.doc)

1. Dentro do formulário da prova (ou pelo menu `⋮` da prova em **Provas**), selecione **Gerar Variantes e Folhas PDF**.
2. Configure as opções de embaralhamento:
   - **Embaralhar ordem das questões**;
   - **Embaralhar alternativas (A–E)**;
   - **Folhas OMR nominais por aluno** (no modo *Mesma prova para todos*, permite gerar folhas de respostas já identificadas com Nome, Matrícula e QR Code individual de cada aluno da turma).
3. Toque em **Regenerar Variantes** caso deseje um novo sorteio.
4. Escolha o formato de exportação/impressão:
   - **Pacote Completo (Cadernos + Folhas OMR + Resumo do Professor em PDF)**;
   - **Apenas Cadernos de Prova (PDF):** layout otimizado que garante que **nenhuma questão seja cortada ao meio** na virada de página;
   - **Apenas Folhas de Resposta OMR (PDF):** com marcadores fiduciais nos 4 cantos e QR Code;
   - **Exportar Prova Editável (.doc):** gera arquivo compatível com Microsoft Word contendo cabeçalho institucional, questões numeradas com proteção contra quebra de página (`page-break-inside: avoid`) e tabela de gabarito oficial ao final.

---

## 5. Correção OMR por Câmera / Imagem e Revisão Interativa

1. Acesse a aba **Corrigir** e selecione a prova desejada.
2. Siga o assistente:
   - **Passo 1 — QR Code / Variante:** escaneie o QR Code da folha do aluno pela câmera ou selecione a variante correspondente.
   - **Passo 2 — Gabarito Oficial:** confira o gabarito da variante ativa. Se necessário, você pode **anular questões** (questões anuladas concedem ponto integral automaticamente a todos os alunos).
   - **Passo 3 — Captura OMR:** fotografe a folha de respostas com a câmera ou carregue uma imagem (`PNG`/`JPG`). O motor de visão computacional:
     - Lê o QR Code para identificar automaticamente a prova, a variante e o aluno;
     - Localiza os 4 marcadores fiduciais nos cantos e aplica correção de perspectiva (homografia);
     - Detecta marcações únicas (`A`–`E`), questões **em branco** e **múltiplas marcações (rasuras)**;
     - Abre o modal de **Revisão OMR** para confirmação ou ajuste manual pelo professor.
3. Ao concluir, a tela **Resultado da Correção** salva automaticamente todas as submissões no Cloud Firestore.

---

## 6. Resultados, Estatísticas por Alternativa e Exportação (.xlsx / .csv)

1. **Resultados (`Mais > Resultados`):**
   - Visualize o histórico de provas corrigidas, a média da turma e a nota individual de cada aluno (`0–10` e percentual).
   - Toque em um aluno para ver o detalhamento questão por questão (incluindo o número da questão original quando a variante foi embaralhada).
   - É possível excluir resultados individuais ou de uma avaliação inteira caso deseje refazer a correção.
2. **Estatísticas (`Mais > Estatísticas`):**
   - **Visão Turma:** média geral, taxa de aprovação, maior/menor nota, distribuição por faixas e **análise por questão canônica** exibindo o percentual de cada alternativa (`A` a `E` e `Branco`) e destacando **qual alternativa foi a mais assinalada pela turma**.
   - **Visão Aluno:** evolução individual do estudante comparada à média da turma.
3. **Exportação (`Mais > Exportar`):**
   - Exporte os dados em **Excel (`.xlsx`)** (com 3 abas: `Resultados`, `Estatisticas` e `Gabarito_Respostas`) ou **CSV (`.csv`)** compatível com Excel (UTF-8 com BOM).
   - Mesmo em provas com variantes embaralhadas, a planilha organiza as questões na ordem canônica original (`Q1..QN`), mostra a letra exata marcada pelo aluno e apresenta o percentual de marcação de cada alternativa (`% A` a `% E`) e a alternativa mais marcada em cada questão.
