# README — Flutter Mobile App V1

## 1. Resumo do Projeto
O **Flutter Mobile App** é uma aplicação mobile desenvolvida em **Flutter** com o objetivo de auxiliar professores no processo de criação, aplicação, correção e acompanhamento de provas.
A aplicação permite organizar provas e questões, realizar o fluxo de correção das avaliações e visualizar informações relacionadas ao desempenho dos alunos e da turma.
A primeira versão do projeto tem como foco o desenvolvimento do aplicativo mobile em Flutter, contemplando os principais fluxos definidos para a aplicação e utilizando dados mockados para representar algumas funcionalidades.

---

## 2. Objetivo
O objetivo do projeto é desenvolver uma aplicação mobile que centralize o processo de criação e correção de avaliações, proporcionando uma experiência simples e organizada para os professores.
A aplicação busca facilitar principalmente:

- Criação e gerenciamento de provas;
- Criação, edição e remoção de questões;
- Definição das alternativas e do gabarito;
- Processo de correção das avaliações;
- Visualização dos resultados;
- Acompanhamento das estatísticas da turma e dos alunos.

---

## 3. Escopo Delimitado — V1
Nesta primeira versão, o projeto é focado no desenvolvimento do aplicativo mobile utilizando Flutter.

### Incluído na V1
- Estrutura inicial da aplicação;
- Navegação entre as principais telas;
- Dashboard;
- Gerenciamento de provas;
- Gerenciamento de questões;
  - Criação, edição e remoção de questões;
  - Cadastro de alternativas;
  - Definição da alternativa correta;
- Fluxo de correção;
  - Seleção da prova para correção;
  - Fluxo relacionado ao QR Code;
  - Definição do gabarito;
  - Simulação da captura das provas;
- Visualização dos resultados;
- Estatísticas da turma;
- Estatísticas individuais do aluno;
- Configurações e perfil;
- Utilização de dados mockados nas funcionalidades que ainda não possuem integração com o banco de dados.

### Fora do escopo da V1
- Desenvolvimento de um Back-End próprio;
- Criação de uma API intermediária;
- Implementação de serviços de Back-End;
- Autenticação através de um servidor próprio;
- Integração com serviços externos não previstos no projeto.

> A persistência e consulta dos dados serão realizadas através de integração direta da aplicação com o banco de dados, conforme definido para o projeto.

---

## 4. Requisitos Funcionais — RF

- **RF01 — Dashboard:** O sistema deve apresentar uma tela inicial com acesso às principais funcionalidades da aplicação.
- **RF02 — Gerenciamento de provas:** O sistema deve permitir visualizar e acessar as provas cadastradas.
- **RF03 — Gerenciamento de questões:** O sistema deve permitir:
  - Adicionar questões;
  - Editar questões;
  - Remover questões;
  - Cadastrar o enunciado;
  - Cadastrar alternativas;
  - Definir uma alternativa como correta.
- **RF04 — Validação das questões:** O sistema deve realizar validações básicas durante o cadastro e edição das questões.
- **RF05 — Correção de provas:** O sistema deve disponibilizar um fluxo para iniciar a correção de uma prova.
  - O fluxo principal deve contemplar: `Selecionar prova` → `QR Code` → `Gabarito` → `Captura das provas` → `Conclusão` → `Resultados`
- **RF06 — Seleção da prova:** O usuário deve conseguir selecionar a prova que deseja corrigir.
- **RF07 — QR Code:** O sistema deve apresentar uma etapa relacionada à identificação da prova por QR Code.
- **RF08 — Gabarito:** O sistema deve permitir visualizar o gabarito utilizado durante o processo de correção.
- **RF09 — Captura das provas:** O sistema deve apresentar uma etapa de captura das provas, simulando o processo de leitura das avaliações.
- **RF10 — Resultados:** O sistema deve apresentar os resultados obtidos após o processo de correção.
- **RF11 — Estatísticas da turma:** O sistema deve apresentar informações estatísticas relacionadas ao desempenho geral da turma.
- **RF12 — Estatísticas do aluno:** O sistema deve apresentar informações relacionadas ao desempenho individual de um aluno.
- **RF13 — Configurações e perfil:** O sistema deve disponibilizar uma área para visualização e configuração das informações do usuário.

---

## 5. Requisitos Não Funcionais — RNF

- **RNF01 — Tecnologia:** A aplicação deve ser desenvolvida utilizando Flutter e Dart.
- **RNF02 — Interface:** As telas devem seguir um padrão visual consistente, mantendo componentes, espaçamentos, tipografia e navegação coerentes entre as diferentes funcionalidades.
- **RNF03 — Navegação:** A navegação entre as telas deve ser clara e permitir que o usuário consiga acessar os principais fluxos da aplicação.
- **RNF04 — Responsividade:** A interface deve se adaptar aos diferentes tamanhos de tela suportados pelo aplicativo.
- **RNF05 — Manutenibilidade:** O código deve ser organizado de forma a facilitar a manutenção e evolução da aplicação.
- **RNF06 — Componentização:** Sempre que possível, devem ser utilizados componentes reutilizáveis para evitar duplicação de código e manter a consistência visual.
- **RNF07 — Integração com banco de dados:** A aplicação deve ser preparada para realizar a integração diretamente com o banco de dados definido para o projeto, sem a utilização de um Back-End intermediário.
- **RNF08 — Dados mockados:** Enquanto determinadas funcionalidades não estiverem integradas ao banco de dados, poderão ser utilizados dados mockados para demonstração dos fluxos da aplicação.
- **RNF09 — Tratamento de estados:** As telas devem considerar estados como carregamento, sucesso, erro e ausência de dados quando aplicável.

---

## 6. Principais Telas

- **Dashboard:** Tela inicial da aplicação, responsável por apresentar as principais funcionalidades e direcionar o usuário para os diferentes fluxos.
- **Provas:** Área destinada à visualização e gerenciamento das provas.
- **Questões:** Tela responsável pelo gerenciamento das questões de uma prova, permitindo adicionar, editar e remover questões e suas alternativas.
- **Correção:** Fluxo responsável por conduzir o usuário durante o processo de correção das provas.
  - *Fluxo principal:* Seleção da prova → QR Code → Gabarito → Captura → Conclusão
- **Resultados:** Tela destinada à apresentação dos resultados obtidos após a correção.
- **Estatísticas da Turma:** Apresenta informações gerais sobre o desempenho da turma, incluindo dados estatísticos e gráficos.
- **Estatísticas do Aluno:** Apresenta informações relacionadas ao desempenho individual do aluno.
- **Configurações e Perfil:** Área destinada às informações do usuário e configurações da aplicação.

---

## 7. Tecnologias Utilizadas

- Flutter
- Dart
- Material Design
- Dados mockados para simulação dos fluxos
- Banco de dados para persistência das informações
- Git e GitHub para versionamento do projeto

---

## 8. Como Executar o Projeto

### Pré-requisitos
Para executar o projeto, é necessário ter instalado:
- Flutter SDK
- Dart SDK
- Android Studio ou VS Code
- Android Emulator ou dispositivo físico configurado

Para verificar se o ambiente está configurado corretamente:
```bash
flutter doctor

```

### Clonar o projeto

O código-fonte do projeto está disponível no GitHub:

**Repositório:** [https://github.com/Klaus-E-J/flutter-mobile-app.git](https://github.com/Klaus-E-J/flutter-mobile-app.git?utm_source=gemini)

Para clonar o projeto:

```bash
git clone [https://github.com/Klaus-E-J/flutter-mobile-app.git](https://github.com/Klaus-E-J/flutter-mobile-app.git)

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

Para visualizar os dispositivos disponíveis:

```bash
flutter devices

```

E executar em um dispositivo específico:

```bash
flutter run -d <device_id>

```

---

## 9. Estrutura do Projeto

A aplicação está organizada de forma a separar as diferentes responsabilidades do Front-End, facilitando a manutenção e evolução das funcionalidades.

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

[INSERIR LINK DO VÍDEO]

---

## 11. Repositório

O código-fonte da aplicação está disponível no GitHub:

[https://github.com/Klaus-E-J/flutter-mobile-app.git](https://github.com/Klaus-E-J/flutter-mobile-app.git?utm_source=gemini)

---

## 12. Status da V1

**Status:** Concluída para entrega da N1

A V1 contempla a estrutura principal do aplicativo e os principais fluxos definidos para o projeto, incluindo gerenciamento de questões, correção de provas, resultados e estatísticas.

A continuidade do projeto será voltada para a evolução das funcionalidades e para a integração da aplicação com o banco de dados, substituindo os dados mockados onde necessário.

```
