# Zeebe vs Peex BPMN Engine Notes

This document captures the current understanding of Zeebe’s BPMN processors and contrasts them with the Elixir/OTP-based Peex prototype, focusing on flow-node behavior, orchestration responsibilities, and which capabilities are provided by the runtime versus implemented manually.

## Flow Node Implementations

### Zeebe highlights
- **Events:** Start, intermediate catch/throw, end, boundary, and event-based gateways each have dedicated processors that coordinate variable mappings, subscriptions, publication, and runtime instructions.
- **Tasks:** Service/external (`JobWorkerTaskProcessor`), business-rule, script, send, receive, manual/undefined, and user tasks all share common behaviors for IO mappings, incidents, compensation, and job management.
- **Gateways:** Exclusive, inclusive, parallel, and event-based gateway processors evaluate expressions, fork tokens, or await events, folding directly into the state-transition machinery.
- **Containers:** Process, subprocess (including event/adhoc/multi-instance), and call activity processors manage flow scopes, enforce call-depth limits, and spawn inner instances.

### Peex highlights
- **Events:** `Peex.Core.StartEvent` inserts the initial token and forwards execution; `Peex.Core.EndEvent` marks completion.
- **Tasks:** `ServiceTask` resolves `camunda:topic` modules and applies business logic; `ScriptTask` evaluates inline Elixir; both rely on shared persistence helpers.
- **Gateways:** `ExclusiveSplitGateway` evaluates branch conditions; `ExclusiveJoinGateway` rejoins tokens without additional logic.
- **Infrastructure:** All flow nodes `use Peex.Core.FlowNode`, inheriting GenServer plumbing and persistence via `Contracts.Processtoken`.

## Orchestration Layer Comparison

| Zeebe component group | OTP counterpart | Rationale |
| --- | --- | --- |
| `BpmnStreamProcessor`, `ProcessInstanceLifecycle`, `ProcessInstanceStateTransitionGuard` | `Supervisor` trees, `GenStateMachine`/`:gen_statem` | Manage replay vs. processing phases and guard lifecycle transitions similar to OTP supervisors/state machines. |
| `BpmnElementProcessor`, `BpmnElementContainerProcessor`, `BpmnElementProcessors` | Behaviour dispatch + registries (`GenServer`, `Supervisor`, `Registry`, `DynamicSupervisor`) | Route work to the correct processor much like OTP behaviours routed via registries. |
| `BpmnElementContext` structs | `GenServer` state (callback arguments) | Carry element-instance metadata akin to process state passed through OTP callbacks. |
| Shared behaviors (`BpmnStateTransitionBehavior`, `BpmnStateBehavior`, `BpmnVariableMappingBehavior`, `BpmnEventSubscriptionBehavior`, `BpmnIncidentBehavior`, `BpmnJobBehavior`, etc.) | Helper modules layered on OTP (Ecto, PubSub, Oban, telemetry) | Encapsulate persistence, incidents, subscriptions, and job orchestration that OTP developers typically pull from existing libraries. |
| Event publication/subscription behaviors (`BpmnEventSubscriptionBehavior`, `BpmnSignalBehavior`, `BpmnEventPublicationBehavior`) | Pub/Sub primitives (`Phoenix.PubSub`, `:pg`, `Registry.dispatch`) | Handle wait-state subscriptions and signal dispatch just as OTP pub/sub systems distribute messages. |
| Incident & compensation behaviors (`BpmnIncidentBehavior`, `BpmnCompensationSubscriptionBehaviour`) | Supervisor/monitor patterns, saga coordinators | Detect failures, escalate, and register compensating actions similar to OTP monitors and saga workflows. |
| Job & user-task behaviors (`BpmnJobBehavior`, `BpmnUserTaskBehavior`, `BpmnDecisionBehavior`) | Worker pools/Task supervisors (`Task.Supervisor`, GenStage, Oban) | Create workers, evaluate expressions/decisions, and manage long-running jobs analogous to OTP job infrastructures. |

## Technical Complexity Snapshot

Zeebe implements most orchestration pieces itself: logstream replay, state-transition guards, event subscriptions, incident handling, job scheduling, and exporters are **custom** Java modules that must be designed, tested, and tuned independently of the JVM. In BEAM, equivalent mechanics are **on-board**: supervisors restart crashed processes, `GenServer`/`:gen_statem` enforce state transitions, `Registry`/`Phoenix.PubSub` provide message routing, and worker pools (Task, Oban, GenStage) handle jobs and compensation. As a result, Peex can lean on standardized OTP semantics while Zeebe gains flexibility at the cost of higher ongoing maintenance.

## Custom vs. On-Board Capabilities

| Dimension | Zeebe (Camunda 8) | Peex (Elixir/OTP) |
| --- | --- | --- |
| Runtime mechanics (supervision, state machine, messaging) | **Custom** stream processor, transition guards, incident subsystems | **On-board** OTP supervisors, `GenServer`/`:gen_statem`, BEAM messaging |
| Persistence/state handling | **Custom** RocksDB logstream, snapshots, exporters | **On-board** Ecto/Postgres and OTP supervision |
| Event/pub-sub and job scheduling | **Custom** event subscription behaviors, job worker orchestration | **On-board** `Phoenix.PubSub`/`:pg`, Task/GenServer patterns |
| BPMN feature scope | **Custom** comprehensive processors for gateways, events, user tasks, DMN/FEEL | **Custom** minimal set of flow nodes implemented manually |
| Scalability / HA | **Custom** broker partitions, Atomix consensus, gateway cluster | **On-board** BEAM clustering if needed (prototype currently single node) |
| Operational overhead | **Custom** logstream operation, backups, exporter lifecycle | **On-board** rely on BEAM + database tooling |


