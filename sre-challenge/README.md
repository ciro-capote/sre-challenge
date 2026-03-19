# 🚀 Platform Engineering & SRE Challenge

Esse repositório é a minha solução para o desafio de Platform Engineering / SRE.

A ideia aqui foi montar algo completo e funcional: provisionamento de infraestrutura no GKE, containerização da aplicação em Python e deploy usando Helm, sempre com foco em boas práticas e, principalmente, isolamento entre ambientes.

---

## 📐 Como eu pensei a arquitetura

### 🔹 Isolamento entre staging e prod

Uma das coisas que eu quis garantir desde o início foi que staging e produção não se misturassem de jeito nenhum.

Pra isso usei duas coisas em conjunto:

- **NodeSelector**: direciona o pod para o nó correto (ex: `environment=staging`)
- **Taints (NoSchedule)**: funciona como uma barreira. Se o pod não estiver configurado corretamente, ele simplesmente não sobe naquele node

Na prática, isso evita qualquer chance de um workload de staging cair em produção (ou o contrário), mesmo em caso de erro de configuração.

---

### 🔹 Sobre o Terragrunt

O desafio sugere separar `staging` e `prod` em pastas diferentes (`terragrunt/staging` e `terragrunt/prod`) mas ainda assim usar o mesmo cluster.

Aqui eu preferi seguir a seguinte abordagem:

👉 Gerenciar o mesmo cluster com múltiplos statefiles é arriscado  
👉 Pode dar conflito e até corromper o estado

Então a decisão foi:

- Criar **clusters independentes por ambiente**
- Reutilizar o mesmo módulo base (`modules/gke-cluster`)

Isso mantém o isolamento de verdade e reduz bastante o risco de problemas maiores (blast radius bem menor).

---

### 🔹 CI/CD e deploy

Montei workflows no GitHub Actions para simular um fluxo real de entrega:

- Build da imagem Docker (multi-stage e rodando como non-root)
- Push para registry
- Deploy com Helm baseado na branch

A ideia foi deixar algo simples, mas próximo do que a gente usa no dia a dia.

---

## ⚠️ Sobre a validação

Aqui teve um ponto importante.

Por causa de mudanças recentes no GCP, não consegui provisionar o GKE de fato.

Em vez de travar por causa disso, segui uma abordagem mais prática:

1. Escrevi todo o Terraform/Terragrunt pensando em ambiente real
2. Validei a aplicação, Helm e regras de agendamento usando **Kind (Kubernetes in Docker)**

Com isso consegui testar:

- Separação de ambientes
- Taints e NodeSelectors funcionando
- Deploy da aplicação rodando normalmente

---

## 🔄 Fluxo geral

```mermaid
graph TD
    A[GitHub Actions CI/CD] -->|Docker Push| B(Docker Registry)
    A -->|Helm Upgrade| C[Cluster K8s]
    C --> D[Node Pool: Staging]
    C --> E[Node Pool: Prod]
    D -->|Taint: staging| F[Pods: Staging App]
    E -->|Taint: prod| G[Pods: Prod App]
