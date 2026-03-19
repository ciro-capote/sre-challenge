Esse repositório é a minha solução para o desafio de Platform Engineering / SRE. 
A ideia aqui foi montar algo completo e funcional: provisionamento de infraestrutura no GKE, containerização da aplicação em Python e deploy usando Helm, sempre com foco em boas práticas, resiliência e, principalmente, isolamento entre ambientes.

## 📐 Como eu pensei a arquitetura

### 🔹 Isolamento entre Staging e Prod
Uma das coisas que eu quis garantir desde o início foi que staging e produção não se misturassem de jeito nenhum. Pra isso usei duas coisas em conjunto:
* **NodeSelector:** direciona o pod para o nó correto (ex: `environment=staging`).
* **Taints (NoSchedule) e Tolerations:** funcionam como uma barreira. Se o pod não estiver configurado explicitamente para tolerar o ambiente, ele simplesmente não sobe naquele node.
Na prática, isso evita qualquer chance de um workload de staging cair em produção (ou o contrário), mesmo em caso de erro de configuração.

### 🔹 Infraestrutura como Código (Terragrunt)
O desafio sugere separar `staging` e `prod` em pastas diferentes (`terragrunt/staging` e `terragrunt/prod`) mas ainda assim usar o mesmo cluster. Aqui eu preferi seguir uma abordagem mais segura para o estado da infraestrutura:
👉 Gerenciar o mesmo cluster com múltiplos statefiles é arriscado.
👉 Pode dar conflito e até corromper o estado.

**A decisão foi:**
* Criar clusters independentes por ambiente.
* Reutilizar o mesmo módulo base (`modules/gke-cluster`).
Isso mantém o isolamento de verdade e reduz bastante o risco de problemas maiores (blast radius bem menor).

### 🔹 Resiliência, Observabilidade e Auto-Scaling
A aplicação não foi apenas conteinerizada, ela foi preparada para sobreviver a falhas:
* **Health Checks:** Configuração rigorosa de *Liveness* e *Readiness Probes* no Helm, garantindo zero downtime em atualizações e reiniciando pods travados.
* **Resource Limits:** Definição clara de `requests` e `limits` de CPU/Memória para evitar *OOMKilled* e o problema do "vizinho barulhento".
* **Escalabilidade Dinâmica:** Implementação do **Horizontal Pod Autoscaler (HPA)** integrado ao Metrics Server, permitindo que a API escale de 2 para até 5 réplicas automaticamente caso o consumo de CPU ultrapasse 70%.
* **Logs Estruturados:** A API FastAPI foi ajustada para emitir logs em formato JSON, facilitando a ingestão por stacks de monitoramento.

### 🔹 CI/CD e Deploy
Montei workflows no GitHub Actions para simular um fluxo real de entrega:
* Build da imagem Docker (multi-stage e rodando como non-root, focando em segurança e leveza).
* Push para o registry.
* Deploy com Helm baseado na branch.
A ideia foi deixar algo simples, mas perfeitamente alinhado com o fluxo de engenharia do dia a dia.

---

## ⚠️ Sobre a Validação e Execução Local

Por causa de mudanças recentes nas políticas de faturamento/cotas do GCP, não foi possível provisionar o GKE de fato para a demonstração. Em vez de travar por causa disso, segui uma abordagem prática de SRE:
1. Escrevi todo o Terraform/Terragrunt pensando em um ambiente de nuvem real.
2. Validei a aplicação, Helm, regras de agendamento e auto-scaling usando **Kind (Kubernetes in Docker)**.

Com isso consegui testar e comprovar o funcionamento de:
✅ Separação de ambientes, Taints e NodeSelectors.
✅ Deploy da aplicação rodando com estabilidade.
✅ HPA escalando pods sob stress.

### 🚀 Quer testar o Auto-scaling localmente?
Se você clonar este repositório e rodar no Kind, pode testar a resiliência da API assim:

1. Abra um terminal para monitorar o HPA:
   `kubectl get hpa -w`
2. Abra a porta do serviço:
   `kubectl port-forward svc/api-staging-crypto-svc 8000:80`
3. Em outro terminal, inicie o teste de carga:
   `while true; do curl -s http://localhost:8000/BTC > /dev/null; done`

Em cerca de 1 minuto, você verá o uso de CPU subir e o Kubernetes criar novos pods automaticamente para suprir a demanda.

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
