# BPMN Modeling Guide for Peex

This guide explains how to model BPMN process diagrams that are compatible with the Peex workflow engine. It covers each supported flow node type, the BPMN editor properties that Peex reads, and provides concrete examples with XML snippets.

---

## Table of Contents

1. [Recommended BPMN Editors](#recommended-bpmn-editors)
2. [General Principles](#general-principles)
3. [Start Event](#start-event)
4. [End Event](#end-event)
5. [Task (Generic)](#task-generic)
6. [Service Task](#service-task)
7. [Script Task](#script-task)
8. [Exclusive Gateway](#exclusive-gateway)
9. [Inclusive Gateway](#inclusive-gateway)
10. [Sequence Flows and Conditions](#sequence-flows-and-conditions)
11. [Unsupported Elements](#unsupported-elements)
12. [Complete Example: Counter Loop](#complete-example-counter-loop)

---

## Recommended BPMN Editors

Peex reads standard BPMN 2.0 XML and uses Camunda-namespaced extension attributes for service task configuration. The following editors are compatible:

| Editor | Notes |
|---|---|
| **[Camunda Modeler](https://camunda.com/download/modeler/)** | Recommended. Full support for `camunda:topic` and condition expressions. The example BPMN files shipped with Peex were created with Camunda Modeler 5.43.0. |
| **[bpmn.io](https://bpmn.io/)** | Web-based, open-source. Supports standard BPMN elements. Camunda extensions require the properties panel add-on. |
| **Any BPMN 2.0 compliant editor** | Works for standard elements (tasks, gateways, events). Camunda-specific attributes may need to be added via the XML source view. |

> **Key requirement:** The XML must use the `bpmn:` namespace prefix for BPMN elements and `camunda:` for Camunda extensions. The namespace declarations should include:
> ```xml
> xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL"
> xmlns:camunda="http://camunda.org/schema/1.0/bpmn"
> xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
> ```

---

## General Principles

### How Peex Reads BPMN

The `Peex.Core.BPMNParser` module parses BPMN XML using XPath queries (via the `sweet_xml` library). For each supported element type, it extracts:

1. **Element ID** — the `id` attribute (becomes the GenServer's registered name)
2. **Element name** — the `name` attribute (informational)
3. **Outgoing sequence flows** — resolved to their target element IDs
4. **Type-specific configuration** — scripts, topics, conditions

### Naming Convention

Element IDs from the BPMN XML are converted to atoms internally. Most BPMN editors auto-generate IDs like `StartEvent_1`, `ServiceTask_1ly7xt9`, etc. These work perfectly with Peex.

### Sequence Flow Resolution

Peex resolves the connection between nodes by following `<bpmn:outgoing>` references to `<bpmn:sequenceFlow>` elements and reading their `targetRef` attributes. You do not need to configure this manually — the editor handles it when you draw connections between nodes.

---

## Start Event

The start event is the entry point for every process instance.

### Editor Configuration

Simply place a **Start Event** on the canvas. No additional configuration is required.

### What Peex Reads

| Attribute | Source | Description |
|---|---|---|
| `id` | Element attribute | Unique identifier (e.g. `StartEvent_1`) |
| `next_node_id` | Resolved from outgoing sequence flow | The first flow node after the start |

### XML Example

```xml
<bpmn:startEvent id="StartEvent_1">
  <bpmn:outgoing>SequenceFlow_1lu12nm</bpmn:outgoing>
</bpmn:startEvent>
```

### Usage

When starting a process instance in Elixir, reference the start event's ID as an atom:

```elixir
Peex.Core.StartEvent.start(:StartEvent_1, token)
```

---

## End Event

The end event marks the completion of a process path. A process may have multiple end events.

### Editor Configuration

Place an **End Event** on the canvas. No additional configuration is needed.

### What Peex Reads

| Attribute | Source | Description |
|---|---|---|
| `id` | Element attribute | Unique identifier |

### Special Behaviour

When a token reaches an end event and carries markers from an inclusive split gateway, the end event notifies the paired inclusive join gateway via `{:token_not_coming, expected, process_instance_id}`. This is handled automatically — no modeling action required.

### XML Example

```xml
<bpmn:endEvent id="EndEvent_1">
  <bpmn:incoming>SequenceFlow_0jpw591</bpmn:incoming>
</bpmn:endEvent>
```

---

## Task (Generic)

A generic task is a pass-through node. It persists the token's arrival and departure but performs no business logic. Useful as a placeholder or for process documentation.

### Editor Configuration

Place a **Task** (not a service task or script task — the plain, untyped task) on the canvas. Optionally set a **Name**.

### What Peex Reads

| Attribute | Source | Description |
|---|---|---|
| `id` | Element attribute | Unique identifier |
| `name` | Element attribute | Display name |
| `next_node_id` | Resolved from outgoing sequence flow | Next flow node |

### XML Example

```xml
<bpmn:task id="Activity_0nf50u0" name="Validation Step">
  <bpmn:incoming>Flow_1cedjuo</bpmn:incoming>
  <bpmn:outgoing>Flow_04zlmnj</bpmn:outgoing>
</bpmn:task>
```

---

## Service Task

Service tasks delegate execution to an Elixir module and function. This is the primary mechanism for integrating business logic into a Peex process.

### Editor Configuration (Camunda Modeler)

1. Place a **Service Task** on the canvas
2. Set a **Name** (e.g. "Increment Counter")
3. In the **Properties Panel**, set:
   - **Type**: `external`
   - **Topic**: The fully qualified Elixir module and function name

The topic follows the convention:

```
Module.Namespace.function_name
```

For example: `Peex.Example.Service.increment_counter`

**Setting the topic in Camunda Modeler:**

1. Select the service task
2. Open the **Properties Panel** (right side)
3. Under **Task Definition** (or **Implementation**):
   - Set **Implementation** to `External`
   - Set **Topic** to your Elixir function path

This produces the `camunda:topic` attribute in the XML.

### What Peex Reads

| Attribute | Source | Description |
|---|---|---|
| `id` | Element attribute | Unique identifier |
| `name` | Element attribute | Display name |
| `topic` | `camunda:topic` attribute | `"Module.Name.function_name"` |
| `next_node_id` | Resolved from outgoing sequence flow | Next flow node |

### How the Topic is Resolved

Peex splits the topic string by `.`:
- All segments except the last form the **module name** (e.g. `Peex.Example.Service`)
- The last segment is the **function name** (e.g. `increment_counter`)

The function is called with the full token as its single argument, and must return a map that becomes the new token payload.

### XML Example

```xml
<bpmn:serviceTask id="ServiceTask_1ly7xt9"
                  name="Increment Counter"
                  camunda:type="external"
                  camunda:topic="Peex.Example.Service.increment_counter">
  <bpmn:incoming>SequenceFlow_1q80ujv</bpmn:incoming>
  <bpmn:outgoing>SequenceFlow_0k7xajt</bpmn:outgoing>
</bpmn:serviceTask>
```

### Corresponding Elixir Module

```elixir
defmodule Peex.Example.Service do
  def increment_counter(token) do
    current_value = token.payload.counter
    %{counter: current_value + 1}
  end
end
```

> **Important:** The module must be compiled and available in the runtime when the process executes. If using Peex as a dependency, ensure your service modules are part of your host application.

---

## Script Task

Script tasks contain inline Elixir code that is evaluated at runtime. They are useful for data transformations, initializations, and simple logic that does not warrant a separate module.

### Editor Configuration (Camunda Modeler)

1. Place a **Script Task** on the canvas
2. Set a **Name** (e.g. "Initialize Counter")
3. In the **Properties Panel**:
   - The **Script** field contains the Elixir code to execute

The script code goes into the `<bpmn:script>` child element in the XML.

### What Peex Reads

| Attribute | Source | Description |
|---|---|---|
| `id` | Element attribute | Unique identifier |
| `name` | Element attribute | Display name |
| `script` | `bpmn:script` child element | Elixir code to evaluate |
| `next_node_id` | Resolved from outgoing sequence flow | Next flow node |

### Script Environment

- The variable `token` is bound to the current `Contracts.Processtoken` struct
- The evaluated result of the script becomes the new `token.payload`
- Access payload data via `token.payload` (map access)

### XML Examples

**Initialize a counter:**

```xml
<bpmn:scriptTask id="ScriptTask_0qrmmga" name="Initialize Counter">
  <bpmn:incoming>SequenceFlow_1lu12nm</bpmn:incoming>
  <bpmn:outgoing>SequenceFlow_1ur0hhw</bpmn:outgoing>
  <bpmn:script>result = %{counter: 1}</bpmn:script>
</bpmn:scriptTask>
```

**Clear payload at end of process:**

```xml
<bpmn:scriptTask id="ScriptTask_19h9wpb" name="Clear Counter">
  <bpmn:incoming>SequenceFlow_0g86i8l</bpmn:incoming>
  <bpmn:outgoing>SequenceFlow_0jpw591</bpmn:outgoing>
  <bpmn:script>result = %{}</bpmn:script>
</bpmn:scriptTask>
```

**Transform payload using current token data:**

```xml
<bpmn:scriptTask id="ScriptTask_transform" name="Double Counter">
  <bpmn:incoming>Flow_in</bpmn:incoming>
  <bpmn:outgoing>Flow_out</bpmn:outgoing>
  <bpmn:script>%{counter: token.payload.counter * 2, doubled: true}</bpmn:script>
</bpmn:scriptTask>
```

### Writing Scripts in the BPMN Editor

In Camunda Modeler:

1. Select the script task
2. In the **Properties Panel**, find the **Script** section
3. Enter the Elixir code directly

> **Note:** In the XML, special characters like `>`, `<`, and `&` are XML-escaped (e.g. `&gt;`, `&lt;`). The BPMN editor handles this automatically — you write normal Elixir code in the properties panel.

---

## Exclusive Gateway

An exclusive gateway (XOR) routes the token to exactly **one** outgoing branch based on conditions. The first matching condition wins. A branch without a condition serves as the **default route**.

### Editor Configuration

1. Place an **Exclusive Gateway** (diamond with "X" marker) on the canvas
2. Draw outgoing sequence flows to the target nodes
3. On each outgoing sequence flow, set a **Condition Expression**:
   - In Camunda Modeler: select the sequence flow, then set the **Condition Type** to "Expression" and enter the Elixir expression
4. Optionally mark one flow as the **Default Flow** (no condition needed — it activates when no other condition matches)

### Split vs. Join Detection

Peex determines whether an exclusive gateway is a **split** or **join** based on the number of outgoing sequence flows:

- **>1 outgoing flows** → `ExclusiveSplitGateway` (evaluates conditions)
- **1 outgoing flow** → `ExclusiveJoinGateway` (pass-through merge point)

You do not need to mark this explicitly — it is inferred from the diagram topology.

### What Peex Reads (Split)

| Attribute | Source | Description |
|---|---|---|
| `id` | Element attribute | Unique identifier |
| `next_nodes` | Resolved from outgoing sequence flows | List of `{id, condition}` pairs |

### Condition Expressions

Conditions are Elixir expressions placed in the `<bpmn:conditionExpression>` element of outgoing sequence flows. The variable `token` is available.

```xml
<!-- Conditional branch -->
<bpmn:sequenceFlow id="Flow_yes" sourceRef="Gateway_1" targetRef="Task_A">
  <bpmn:conditionExpression xsi:type="bpmn:tFormalExpression">
    token.payload.counter > 10
  </bpmn:conditionExpression>
</bpmn:sequenceFlow>

<!-- Default branch (no condition) -->
<bpmn:sequenceFlow id="Flow_default" sourceRef="Gateway_1" targetRef="Task_B" />
```

### XML Example

```xml
<bpmn:exclusiveGateway id="ExclusiveGateway_1dj30yk" name="counter > 10?">
  <bpmn:incoming>SequenceFlow_0k7xajt</bpmn:incoming>
  <bpmn:outgoing>SequenceFlow_0g86i8l</bpmn:outgoing>
  <bpmn:outgoing>SequenceFlow_0oam4ud</bpmn:outgoing>
</bpmn:exclusiveGateway>

<bpmn:sequenceFlow id="SequenceFlow_0g86i8l" name="yes"
                   sourceRef="ExclusiveGateway_1dj30yk"
                   targetRef="ScriptTask_19h9wpb">
  <bpmn:conditionExpression xsi:type="bpmn:tFormalExpression">
    token.payload.counter &gt; 10
  </bpmn:conditionExpression>
</bpmn:sequenceFlow>

<!-- Default route (no condition expression) -->
<bpmn:sequenceFlow id="SequenceFlow_0oam4ud"
                   sourceRef="ExclusiveGateway_1dj30yk"
                   targetRef="ExclusiveGateway_0btyrc3" />
```

---

## Inclusive Gateway

An inclusive gateway (OR) activates **all** outgoing branches whose condition evaluates to `true`. Branches without conditions are always activated. The corresponding inclusive join gateway waits for all activated tokens to arrive before continuing.

### Editor Configuration

1. Place an **Inclusive Gateway** (diamond with "O" marker) for the **split**
2. Place another **Inclusive Gateway** for the **join** (merge point)
3. Draw outgoing sequence flows from the split gateway, setting conditions as needed
4. Connect all branches back into the join gateway

### Split vs. Join Detection

Like exclusive gateways, the parser infers split/join semantics from the number of outgoing flows:

- **>1 outgoing flows** → `InclusiveSplitGateway` (forks token to all matching branches)
- **≤1 outgoing flow** → `InclusiveJoinGateway` (waits for all expected tokens)

### Paired Join Resolution

Peex automatically pairs each inclusive split gateway with its nearest reachable inclusive join gateway using a BFS (breadth-first search) traversal of the process graph. This pairing is stored as `paired_join_id` in the split gateway's configuration.

You do not need to configure this manually. Simply ensure that:
- Every inclusive split has a corresponding inclusive join downstream
- The join is reachable from all outgoing branches (directly or transitively)

### How the Join Works

When the inclusive split activates N branches, it adds a **marker** to the token: `%{join_id: paired_join_id, expected: N}`. The join gateway tracks:
- Tokens that arrive at the join (`arrived`)
- Tokens that reach an end event instead (`not_coming_count`, notified by the end event)

When `arrived + not_coming_count >= expected`, the join activates: it merges the payloads of all arrived tokens and forwards a single merged token.

### XML Example

```xml
<!-- Inclusive Split -->
<bpmn:inclusiveGateway id="Gateway_1odavsh">
  <bpmn:incoming>Flow_1mqhboi</bpmn:incoming>
  <bpmn:outgoing>Flow_1cedjuo</bpmn:outgoing>
  <bpmn:outgoing>Flow_0mi5ri6</bpmn:outgoing>
</bpmn:inclusiveGateway>

<!-- Inclusive Join -->
<bpmn:inclusiveGateway id="Gateway_0l8ncgq">
  <bpmn:incoming>Flow_04zlmnj</bpmn:incoming>
  <bpmn:incoming>Flow_0v9m0mc</bpmn:incoming>
  <bpmn:outgoing>Flow_0pqmxki</bpmn:outgoing>
</bpmn:inclusiveGateway>
```

### Condition Example (on outgoing flows from split)

```xml
<!-- Always activated (no condition) -->
<bpmn:sequenceFlow id="Flow_1cedjuo"
                   sourceRef="Gateway_1odavsh"
                   targetRef="Activity_0nf50u0" />

<!-- Conditionally activated -->
<bpmn:sequenceFlow id="Flow_0mi5ri6"
                   sourceRef="Gateway_1odavsh"
                   targetRef="Activity_1w1ufh7">
  <bpmn:conditionExpression xsi:type="bpmn:tFormalExpression">
    token.payload["needs_review"] == true
  </bpmn:conditionExpression>
</bpmn:sequenceFlow>
```

---

## Sequence Flows and Conditions

Sequence flows are the arrows connecting BPMN elements. For gateways, they carry condition expressions.

### Adding Conditions in Camunda Modeler

1. Click on a sequence flow (arrow) leaving a gateway
2. In the **Properties Panel**, set:
   - **Condition Type**: Expression
   - **Expression**: Your Elixir expression (e.g. `token.payload.counter > 10`)

### Condition Syntax

Conditions are standard Elixir expressions evaluated with `Code.eval_string/2`. The `token` variable is in scope.

**Common patterns:**

```elixir
# Numeric comparison
token.payload.counter > 10

# String comparison
token.payload["status"] == "approved"

# Boolean check
token.payload["is_vip"] == true

# Map access (string keys)
token.payload["a"] == token.payload["b"]

# Atom keys
token.payload.amount > 1000
```

### Default Routes

A sequence flow without a `<bpmn:conditionExpression>` element acts as the default route. In the Camunda Modeler, you can also explicitly set a flow as the "Default Flow" on the gateway properties. Peex sorts condition-less flows to the end of the evaluation list, so they only match when no other condition is true.

---

## Unsupported Elements

The following BPMN elements are **not currently supported** by the Peex parser. They will be silently ignored if present in the BPMN file:

| Element | Notes |
|---|---|
| `bpmn:parallelGateway` | The parallel gateway modules exist in code (`ParallelSplitGateway`, `ParallelJoinGateway`) but are not wired into the BPMN parser. To use them, construct the config manually. |
| `bpmn:intermediateCatchEvent` | Timer events, message events, signal events are not implemented. |
| `bpmn:intermediateThrowEvent` | Not implemented. |
| `bpmn:boundaryEvent` | Not implemented. |
| `bpmn:subProcess` | Not implemented. |
| `bpmn:callActivity` | Not implemented. The `parent_caller_instance_id` field on the token schema is reserved for future use. |
| `bpmn:userTask` | Not implemented. |
| `bpmn:businessRuleTask` | Not implemented. |
| `bpmn:sendTask` / `bpmn:receiveTask` | Not implemented. |
| `bpmn:eventBasedGateway` | Not implemented. |
| `bpmn:terminateEventDefinition` | End events with terminate semantics are parsed as regular end events. |
| Data objects / data stores | Informational only — Peex does not read data associations. |
| Text annotations | Informational only — ignored by the parser. |
| Lanes | Informational only — ignored by the parser. |

---

## Complete Example: Counter Loop

This example demonstrates a process that initializes a counter, increments it via a service task in a loop, and exits when the counter exceeds 10.

### Process Flow

```
[Start] → [Script: Initialize Counter] → [Exclusive Join] → [Service: Increment Counter]
    → [Exclusive Split: counter > 10?]
        ├── yes → [Script: Clear Counter] → [End]
        └── no  → [Exclusive Join] (loop back)
```

### BPMN Elements Configuration

| Element | Type | Configuration |
|---|---|---|
| StartEvent_1 | Start Event | — |
| ScriptTask_0qrmmga | Script Task | Script: `result = %{counter: 1}` |
| ExclusiveGateway_0btyrc3 | Exclusive Gateway (Join) | — |
| ServiceTask_1ly7xt9 | Service Task | Topic: `Peex.Example.Service.increment_counter` |
| ExclusiveGateway_1dj30yk | Exclusive Gateway (Split) | — |
| ScriptTask_19h9wpb | Script Task | Script: `result = %{}` |
| EndEvent_1 | End Event | — |

### Condition on "yes" branch:

```
token.payload.counter > 10
```

### "no" branch (default):

No condition — loops back to the join gateway.

### Starting the Process

```elixir
nodes = Peex.Core.BPMNParser.parse("processes/example/example_process.bpmn")
{:ok, _} = Peex.Core.ProcessSupervisor.start_link(nodes)

token = %Contracts.Processtoken{
  process_model_id: "Collaboration_1ti1prd",
  correlation_id: to_string(DateTime.utc_now()),
  identity: Base.encode64("test_user"),
}

Peex.Core.StartEvent.start(:StartEvent_1, token)
```

The counter starts at 1, gets incremented by the service task on each loop iteration, and the process ends when the counter exceeds 10 (after ~10 iterations).
