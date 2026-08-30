# Modelagem de Dados — Sistema de Provas (Firestore)

## Árvore de coleções

```
professores/{codigo}
  turmas/{turmaId}
    alunos/{alunoId}
    provas/{provaId}
      questoes/{questaoId}
      folhasResposta/{alunoId}
      resultados/{alunoId}
```

`{codigo}` = código de acesso do professor, também usado como `uid` de autenticação.

## Campos principais

* **professores**: nome, email, criadoEm
* **turmas**: nome, anoLetivo
* **alunos**: nome, matricula
* **provas**: titulo, dataAplicacao, valorTotal, status (rascunho/aplicada/corrigida)
* **questoes**: enunciado, tipo, alternativas, gabarito, peso, ordem
* **folhasResposta**: respostas (map: questaoId → resposta), entregueEm
* **resultados**: nota, acertos, erros, calculadoEm

IDs de documento manuais e legíveis (não automáticos): código do professor, slug da turma/prova, matrícula do aluno.

## Security Rules

```
rules\_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /professores/{codigo} {
      allow read, write: if request.auth != null \&\& request.auth.uid == codigo;

      match /{document=\*\*} {
        allow read, write: if request.auth != null \&\& request.auth.uid == codigo;
      }
    }
  }
}
```

Cada professor só acessa a própria árvore de dados (código de acesso = uid). Testado no Rules Playground: acesso permitido só com uid correspondente ao código.

## testes

Foram simuladas três situações no caminho `/professores/{codigo}/turmas/{turmaId}`: leitura com `uid` igual ao código do professor (permitida), leitura com `uid` de outro professor (negada) e leitura sem autenticação (negada). Os três resultados confirmaram o isolamento esperado entre professores.

## Outros pontos do requisito

* **Sem Cloud Functions**: o token de autenticação (uid = código do professor) é gerado pelo backend próprio, não por uma Cloud Function do Firebase.
* **Cota gratuita (plano Spark)**: a estrutura aninhada evita consultas com `where` composto, reduzindo leituras desnecessárias e mantendo o uso dentro do limite gratuito (\~50 mil leituras / \~20 mil escritas por dia).
* **Base para estatística e exportação**: os dados em `resultados/{alunoId}` já ficam estruturados por prova, prontos para serem agregados (estatísticas) ou lidos em lote (exportação) no futuro.

