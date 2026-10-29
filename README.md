# README — Avalia Pro V2

## 1. Resumo do Projeto

O **Avalia Pro** é uma aplicação mobile desenvolvida em **Flutter** com o objetivo de auxiliar professores no processo de criação, aplicação, correção e acompanhamento de provas.

A aplicação permite organizar turmas e alunos, gerenciar provas e questões, realizar o fluxo de correção das avaliações e visualizar informações relacionadas ao desempenho dos alunos e da turma.

O projeto é desenvolvido em etapas. A N1 contemplou a estrutura do aplicativo e seus principais fluxos, utilizando dados mockados em algumas funcionalidades. A N2 dá continuidade ao desenvolvimento com a integração ao **Firebase e Cloud Firestore**, permitindo a persistência e consulta de dados reais nas funcionalidades integradas.

---

## 2. Objetivo

O objetivo do projeto é desenvolver uma aplicação mobile que centralize o processo de gerenciamento de turmas, alunos e avaliações, desde a criação das provas até sua correção e acompanhamento dos resultados.

A aplicação busca facilitar principalmente:

- Gerenciamento de turmas e alunos;
- Criação e gerenciamento de provas;
- Criação, edição e remoção de questões;
- Definição das alternativas e do gabarito;
- Processo de correção das avaliações;
- Visualização dos resultados;
- Acompanhamento das estatísticas da turma e dos alunos;
- Armazenamento e consulta dos dados por meio do Firebase.

---

## 3. Escopo do Projeto

O projeto contempla o desenvolvimento de um aplicativo mobile utilizando Flutter, integrado ao Firebase para autenticação e persistência de dados.

### Incluído no projeto

- Estrutura e navegação da aplicação;
- Dashboard;
- Gerenciamento de turmas e alunos;
- Gerenciamento de provas;
- Gerenciamento de questões;
  - Criação, edição e remoção de questões;
  - Cadastro de alternativas;
  - Definição da alternativa correta;
- Fluxo de correção;
  - Seleção da prova para correção;
  - Fluxo relacionado ao QR Code;
  - Definição do gabarito;
  - Captura das provas;
- Visualização dos resultados;
- Estatísticas da turma e dos alunos;
- Configurações e perfil;
- Autenticação por meio do Firebase Authentication;
- Persistência e consulta de dados no Cloud Firestore;
- Tratamento de erros e estados das operações com o banco de dados.

### Fora do escopo do projeto

- Desenvolvimento de um Back-End próprio;
- Criação de uma API intermediária;
- Implementação de serviços de Back-End próprios;
- Autenticação através de um servidor próprio;
- Integração com serviços externos não previstos no projeto.

> A persistência e consulta dos dados são realizadas diretamente pela aplicação por meio dos serviços Firebase, sem a utilização de um Back-End intermediário.

### Divisão por entregas

- **N1:** desenvolvimento da estrutura inicial, telas, navegação e principais fluxos da aplicação, com utilização de dados mockados.
- **N2:** integração com Firebase Authentication e Cloud Firestore, substituição dos dados mockados nas funcionalidades integradas e correção de problemas identificados durante o desenvolvimento.

---

## 4. Requisitos Funcionais — RF

- **RF01 — Dashboard:** O sistema deve apresentar uma tela inicial com acesso às principais funcionalidades da aplicação.
- **RF02 — Gerenciamento de turmas e alunos:** O sistema deve permitir o cadastro e a gestão de turmas e alunos.
- **RF03 — Gerenciamento de provas:** O sistema deve permitir visualizar e gerenciar as provas cadastradas.
- **RF04 — Gerenciamento de questões:** O sistema deve permitir adicionar, editar e remover questões, cadastrar enunciados e alternativas e definir uma alternativa como correta.
- **RF05 — Validação das questões:** O sistema deve realizar validações básicas durante o cadastro e edição das questões.
- **RF06 — Correção de provas:** O sistema deve disponibilizar um fluxo para iniciar a correção de uma prova.
  - Fluxo principal: `Selecionar prova` → `QR Code` → `Gabarito` → `Captura das provas` → `Conclusão` → `Resultados`.
- **RF07 — Seleção da prova:** O usuário deve conseguir selecionar a prova que deseja corrigir.
- **RF08 — QR Code:** O sistema deve apresentar uma etapa relacionada à identificação da prova por QR Code.
- **RF09 — Captura das provas:** O sistema deve apresentar uma etapa de captura das provas, conforme o fluxo de leitura das avaliações.
- **RF10 — Resultados:** O sistema deve apresentar e armazenar os resultados obtidos após o processo de correção.
- **RF11 — Estatísticas da turma:** O sistema deve apresentar informações estatísticas relacionadas ao desempenho geral da turma.
- **RF12 — Estatísticas do aluno:** O sistema deve apresentar informações relacionadas ao desempenho individual de um aluno.
- **RF13 — Configurações e perfil:** O sistema deve disponibilizar uma área para visualização e configuração das informações do usuário.
- **RF14 — Autenticação:** O sistema deve utilizar Firebase Authentication para autenticação e controle de sessão.
- **RF15 — Persistência de dados:** O sistema deve utilizar o Cloud Firestore para armazenar e consultar turmas, alunos, provas, questões e resultados.

---

## 5. Requisitos Não Funcionais — RNF

- **RNF01 — Tecnologia:** A aplicação deve ser desenvolvida utilizando Flutter e Dart.
- **RNF02 — Interface:** As telas devem seguir um padrão visual consistente, mantendo componentes, espaçamentos, tipografia e navegação coerentes entre as diferentes funcionalidades.
- **RNF03 — Navegação:** A navegação entre as telas deve ser clara e permitir que o usuário consiga acessar os principais fluxos da aplicação.
- **RNF04 — Responsividade:** A interface deve se adaptar aos diferentes tamanhos de tela suportados pelo aplicativo.
- **RNF05 — Manutenibilidade:** O código deve ser organizado de forma a facilitar a manutenção e evolução da aplicação.
- **RNF06 — Componentização:** Sempre que possível, devem ser utilizados componentes reutilizáveis para evitar duplicação de código e manter a consistência visual.
- **RNF07 — Integração com banco de dados:** A aplicação deve realizar a integração diretamente com o Firebase, sem a utilização de um Back-End intermediário.
- **RNF08 — Persistência:** Os dados das funcionalidades integradas devem ser armazenados no Cloud Firestore, substituindo os dados mockados correspondentes.
- **RNF09 — Tratamento de estados:** As telas devem considerar estados como carregamento, sucesso, erro e ausência de dados quando aplicável.
- **RNF10 — Segurança:** O acesso aos dados deve respeitar as regras de segurança configuradas no Firebase.

---

## 6. Principais Telas

- **Dashboard:** Tela inicial da aplicação, responsável por apresentar as principais funcionalidades e direcionar o usuário para os diferentes fluxos.
- **Turmas e Alunos:** Área destinada ao gerenciamento das turmas e dos estudantes.
- **Provas:** Área destinada à visualização e gerenciamento das provas.
- **Questões:** Tela responsável pelo gerenciamento das questões de uma prova, permitindo adicionar, editar e remover questões e suas alternativas.
- **Correção:** Fluxo responsável por conduzir o usuário durante o processo de correção das provas.
  - *Fluxo principal:* Seleção da prova → QR Code → Gabarito → Captura → Conclusão.
- **Resultados:** Tela destinada à apresentação dos resultados obtidos após a correção.
- **Estatísticas da Turma:** Apresenta informações gerais sobre o desempenho da turma, incluindo dados estatísticos e gráficos.
- **Estatísticas do Aluno:** Apresenta informações relacionadas ao desempenho individual do aluno.
- **Configurações e Perfil:** Área destinada às informações do usuário e configurações da aplicação.

---

## 7. Tecnologias Utilizadas

- Flutter;
- Dart;
- Material Design;
- Firebase Authentication;
- Cloud Firestore;
- Git e GitHub para versionamento do projeto.

---

## 8. Como Executar o Projeto

### Pré-requisitos

Para executar o projeto, é necessário ter instalado:

- Flutter SDK;
- Dart SDK;
- Android Studio ou VS Code;
- Android Emulator ou dispositivo físico configurado.

Para verificar se o ambiente está configurado corretamente:

```bash
flutter doctor
```

### Clonar o projeto

O código-fonte do projeto está disponível no GitHub:

**Repositório:** https://github.com/Klaus-E-J/flutter-mobile-app.git

Para clonar o projeto:

```bash
git clone https://github.com/Klaus-E-J/flutter-mobile-app.git
```

Depois, entre no diretório:

```bash
cd flutter-mobile-app
```

### Instalar as dependências

```bash
flutter pub get
```

### Executar a aplicação

Para executar a aplicação em um dispositivo ou emulador:

```bash
flutter run
```

Para executar a aplicação em um navegador:
```bash
flutter run -d web-server
```

Para visualizar os dispositivos disponíveis:

```bash
flutter devices
```

E executar em um dispositivo específico:

```bash
flutter run -d <device_id>
```

### Gerar APK

Para gerar o APK de release:

```bash
flutter build apk --release
```

O arquivo será gerado em:

```text
build/app/outputs/flutter-apk/app-release.apk
```

---

## 9. Estrutura do Projeto

A aplicação está organizada de forma a separar as diferentes responsabilidades do Front-End e dos serviços de integração, facilitando a manutenção e evolução das funcionalidades.

De forma geral, o projeto possui estruturas relacionadas a:

```text
lib/
├── ...
├── screens/
├── widgets/
├── models/
├── services/
└── ...
```

A estrutura poderá ser expandida conforme novas funcionalidades e integrações com o banco de dados forem implementadas.

---

## 10. Demonstração

Vídeo de demonstração da aplicação:

[Vídeo da aplicação](https://youtu.be/Xq8bVgVs0Ks)

---

## 11. Repositório

O código-fonte da aplicação está disponível no GitHub:

https://github.com/Klaus-E-J/flutter-mobile-app.git

---

## 12. Backlog e Divisão de Atividades — N2

| Tarefa | Tempo estimado | Prioridade | Responsável |
|---|---:|---|---|
| Acesso real, autenticação anônima e código de acesso | 16 h | Alta | Kaue |
| Infraestrutura Firebase e Firestore | 20 h | Alta | Klaus |
| Persistência real de turmas e alunos | 16 h | Alta | Klaus |
| Persistência real de provas e questões | 20 h | Alta | Kaue e Klaus |
| Persistência e integração dos resultados reais | 16 h | Média | Kaue |
| Corrigir a disposição visual dos cartões de turmas | 4 h | Média | João |
| Remover comentário interno de desenvolvimento da tela de criação de provas | 1 h | Média | João |
| Corrigir o contador e o controle de folhas durante a correção de provas | 4 h | Alta | Miguel |
| Corrigir erro na tela de estatísticas quando há alunos com nomes iguais | 3 h | Alta | Marcos Paulo |

**Estimativa total: 100 horas.**

As estimativas representam o esforço previsto para análise, implementação e testes das atividades.

---

## 13. Status do Projeto

**N1 — Concluída para entrega.**

A primeira entrega contemplou a estrutura principal do aplicativo e os fluxos definidos para a versão inicial, incluindo gerenciamento de questões, correção de provas, resultados e estatísticas.

**N2 — Evolução do projeto.**

A segunda entrega contempla a integração com Firebase e Cloud Firestore, a substituição dos dados mockados nas funcionalidades integradas, as correções identificadas durante o desenvolvimento e a atualização da documentação.
