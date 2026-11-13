# Avalia Pro — Sistema Mobile de Avaliações, Geração de Variantes e Correção OMR (Entrega Final N3)

## 1. Resumo do Projeto

O **Avalia Pro** é uma aplicação mobile e multiplataforma desenvolvida em **Flutter** e integrada ao **Firebase (Authentication + Cloud Firestore)** com o objetivo de automatizar todo o ciclo de avaliação escolar para professores: desde o cadastro/importação de turmas e alunos, elaboração de provas com embaralhamento antifraude (ou geração rápida de gabarito avulso para provas externas), exportação de cadernos de prova em **PDF (sem corte de questões entre páginas)** e **Word (`.doc` editável)**, emissão de **folhas de resposta OMR nominais com QR Code**, leitura automatizada por **visão computacional (OMR + QR Code)** via câmera, até a análise estatística por alternativa e exportação de relatórios completos em **Excel (`.xlsx`)** e **CSV (`.csv`)**.

📘 **Documentação de Uso:** consulte o [**Manual do Usuário Completo (`docs/MANUAL_DO_USUARIO.md`)**](docs/MANUAL_DO_USUARIO.md).

---

## 2. Evolução das Entregas (N1 → N2 → N3)

- **Entrega N1:** Estrutura de navegação, prototipação de alta fidelidade e fluxos principais do aplicativo.
- **Entrega N2:** Integração real com **Firebase Authentication** (E-mail/Senha, Recuperação de Senha e Convidado Anônimo) e **Cloud Firestore** para persistência isolada por professor (`users/{uid}/...`).
- **Entrega N3 (Versão Final):**
  - **CRUD Completo no Firestore:** criação, leitura, edição e exclusão de Turmas, Alunos (individual e importação em lote `.csv`/`.xlsx`/`.xls`), Provas, Questões (até 30 questões com 5 alternativas `A–E`), Variantes, Submissões/Resultados e Perfil do Professor;
  - **Gabarito Rápido (Prova Externa):** modo expresso para professores que já possuem a prova diagramada fora do sistema e desejam gerar apenas as folhas de resposta OMR com QR Code e gabarito oficial;
  - **Motor de Randomização e Mapeamento Canônico (`ExamRandomizerService`):** embaralhamento configurável de questões e alternativas (`A–E`), mantendo o rastreamento canônico (`originalQuestionNumber` e `originalLetter`) para consolidar estatísticas e planilhas mesmo quando cada aluno responde uma variante diferente;
  - **Folhas OMR Nominais e Exportação PDF + `.doc` (`ExamPdfService`):** geração de folhas de resposta identificadas por aluno (mesmo em provas únicas), cadernos de prova em PDF com blocos indivisíveis (sem cortar questões entre páginas) e exportação editável para Microsoft Word (`.doc`);
  - **Visão Computacional OMR (`OmrImageService` + `ExamGradingService`):** decodificação de QR Code, detecção de marcadores fiduciais nos 4 cantos, correção de perspectiva por transformação homográfica, detecção adaptativa de bolhas preenchidas, em branco e rasuras (múltiplas marcações), além de suporte a anulação de questões;
  - **Estatísticas Pedagógicas e Exportação Excel/CSV (`FirestoreStatisticsRepository` + `ResultExportService`):** distribuição percentual e contagem por alternativa (`A` a `E` e `Branco`), destaque da **alternativa mais assinalada** em cada questão e exportação de planilhas `.xlsx` multi-abas (`Resultados`, `Estatisticas`, `Gabarito_Respostas`) e `.csv`.

---

## 3. Escopo do Projeto

### Incluído no projeto
- Autenticação completa com Firebase Auth (Login, Cadastro, Recuperação de Senha, Sessão Convidado e Código Institucional `PROF-XXXX`);
- Edição de perfil do professor (`Nome de exibição` e `Escola / Instituição`);
- CRUD completo de Turmas e Alunos + Importação de alunos via arquivo `.csv`/`.xlsx`/`.xls` com remoção de duplicados;
- CRUD completo de Provas e Questões (até 30 questões por folha OMR, alternativas `A` a `E`) + Assistente de **Gabarito Rápido (Prova Externa)**;
- Geração de variantes embaralhadas (cadernos A, B, C, D ou provas individuais por aluno) e folhas OMR nominais por aluno;
- Exportação de cadernos de prova em **PDF** (sem quebra de questão entre páginas) e **Word (`.doc`)** editável;
- Correção automatizada por câmera/imagem com leitura de QR Code, retificação de perspectiva e revisão interativa;
- Salvamento automático de submissões ao concluir a correção, com histórico e exclusão de resultados;
- Estatísticas da turma (média, aprovação, distribuição de notas, percentual por alternativa `A–E` e alternativa mais marcada) e evolução individual do aluno;
- Exportação e compartilhamento nativo em **Excel (`.xlsx`)** e **CSV (`.csv`)**.

### Fora do escopo do projeto
- Desenvolvimento de um servidor Back-End intermediário próprio (toda a persistência e segurança operam diretamente via Firebase Authentication, Cloud Firestore e regras declarativas `firestore.rules`).

---

## 4. Requisitos Funcionais — RF

- **RF01 — Autenticação e Sessão:** permitir login com e-mail/senha, criação de conta, redefinição de senha e modo convidado via Firebase Authentication.
- **RF02 — Gestão de Turmas (CRUD):** cadastrar, listar, editar (sincronizando o nome nas provas e submissões) e excluir turmas no Cloud Firestore.
- **RF03 — Gestão e Importação de Alunos (CRUD):** adicionar, editar e remover alunos manualmente ou importar listas em lote via arquivos `.csv`, `.xlsx` e `.xls`.
- **RF04 — Gestão de Provas (CRUD):** criar, editar e excluir avaliações vinculadas a uma ou mais turmas, configurando prova única ou prova individual por aluno.
- **RF05 — Gestão de Questões e Gabarito Rápido:** cadastrar até 30 questões de múltipla escolha (até 5 alternativas `A–E`) ou utilizar o assistente **Gabarito Rápido (Prova Externa)** para definir apenas as letras corretas sem digitar enunciados.
- **RF06 — Randomização e Mapeamento Canônico:** gerar variantes embaralhadas preservando a correspondência exata com a questão e a alternativa originais da prova mestre.
- **RF07 — Impressão PDF e Exportação Word (`.doc`):** gerar cadernos de prova em PDF (garantindo que nenhuma questão seja cortada entre páginas), cadernos editáveis em `.doc` e folhas de resposta OMR (avulsas ou nominais por aluno) com QR Code e marcadores fiduciais.
- **RF08 — Leitura OMR e Correção Automatizada:** processar imagens/fotos das folhas de resposta, identificando automaticamente o QR Code, corrigindo a inclinação/perspectiva, detectando alternativas marcadas, em branco ou rasuradas, e permitindo anular questões.
- **RF09 — Gestão de Resultados:** persistir automaticamente as correções no Firestore, consultar o detalhamento por aluno/questão e permitir a exclusão de submissões individuais ou por prova.
- **RF10 — Estatísticas da Turma e do Aluno:** apresentar indicadores gerais da turma, distribuição de respostas por alternativa (`A–E` e `Branco`), identificação da alternativa mais marcada por questão e histórico individual do estudante.
- **RF11 — Exportação de Dados (`.xlsx` e `.csv`):** exportar notas, estatísticas por alternativa e matriz canônica de respostas (`Q1..QN`) em formatos Excel e CSV.
- **RF12 — Configurações e Perfil:** permitir editar nome e escola do professor, gerenciar código institucional e encerrar sessão.

---

## 5. Requisitos Não Funcionais — RNF

- **RNF01 — Tecnologia:** desenvolvido em Flutter (SDK `^3.11.1`) e Dart, seguindo Material Design 3.
- **RNF02 — Persistência Cloud e Isolamento:** armazenamento em tempo real no Cloud Firestore sob `users/{uid}/...`, protegido por regras de segurança (`firestore.rules`).
- **RNF03 — Processamento OMR Local:** execução do pipeline de visão computacional e leitura de QR Code diretamente no dispositivo, com compensação de iluminação local e perspectiva.
- **RNF04 — Integridade de Paginação:** blocos de questões indivisíveis tanto no gerador PDF quanto no documento `.doc` (`page-break-inside: avoid`).
- **RNF05 — Qualidade e Testes:** cobertura automatizada de testes unitários, de widgets e de fluxo ponta a ponta (`flutter test`) e análise estática limpa (`dart analyze`).

---

## 6. Estrutura do Projeto

```text
lib/
├── core/
│   ├── routes/          # Rotas nomeadas (AppRoutes)
│   ├── services/        # FirebaseService e AuthService
│   ├── theme/           # Tema Material 3 (AppTheme / AppColors)
│   └── widgets/         # Componentes reutilizáveis (AppButton, AppCard, AppTextField, AppDialog)
├── features/
│   ├── access/          # Autenticação e perfil do professor (AuthRepository, UserProfile)
│   ├── classes/         # CRUD de turmas/alunos e importação CSV/Excel (ClassRepository, StudentImportService)
│   ├── config/          # Configurações e edição de perfil (ConfigScreen)
│   ├── correction/      # Motor OMR, correção e submissões (OmrImageService, ExamGradingService, SubmissionRepository)
│   ├── dashboard/       # Tela inicial com resumo em tempo real (DashboardScreen)
│   ├── exams/           # CRUD de provas, variantes e exportação PDF/.doc (ExamRepository, ExamRandomizerService, ExamPdfService)
│   ├── export/          # Exportação Excel (.xlsx) e CSV (.csv) (ResultExportService, ExportScreen)
│   ├── results/         # Central de resultados e detalhamento por aluno (ResultsScreen, ExamResultsScreen, StudentResultScreen)
│   └── statistics/      # Estatísticas da turma e do aluno (FirestoreStatisticsRepository, ClassStatsView, StudentStatsView)
└── screens/
    ├── correcao/        # Fluxo guiado de correção OMR (SelecaoProvaScreen, LeituraQrScreen, LeituraGabaritoScreen, ResultadoCorrecaoScreen)
    └── provas/          # Editor de questões e Gabarito Rápido (ProvaQuestoesScreen, Questao, AlternativaItem)
```

---

## 7. Como Executar e Testar o Projeto

### Pré-requisitos
- Flutter SDK (`^3.11.1`) e Dart SDK instalados (`flutter doctor`).

### Instalar dependências
```bash
flutter pub get
```

### Executar análise estática e suíte de testes automatizados
```bash
dart analyze
flutter test
```

### Executar a aplicação
```bash
flutter run
```

### Gerar APK de Release
```bash
flutter build apk --release
```
O APK será gerado em `build/app/outputs/flutter-apk/app-release.apk`.

---

## 8. Links Úteis

- **Manual do Usuário (N3):** [`docs/MANUAL_DO_USUARIO.md`](docs/MANUAL_DO_USUARIO.md)
- **Repositório GitHub:** https://github.com/Klaus-E-J/flutter-mobile-app.git
- **Vídeo de Demonstração:** [Assistir no YouTube](https://youtu.be/Xq8bVgVs0Ks)
