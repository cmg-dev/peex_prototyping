# Peex Engine Usage Guide

This guide explains how to integrate and interact with the Peex BPMN workflow engine. Peex is an Elixir/OTP-based engine designed for maximising parallel task execution and processing large volumes of BPMN process instances concurrently, leveraging the BEAM's lightweight process model.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Prerequisites](#prerequisites)
3. [Embedding Peex in an Elixir Application](#embedding-peex-in-an-elixir-application)
4. [Running a Process Instance Step by Step](#running-a-process-instance-step-by-step)
5. [The Process Token](#the-process-token)
6. [Running Multiple Process Instances in Parallel](#running-multiple-process-instances-in-parallel)
7. [Exposing Peex via an HTTP API](#exposing-peex-via-an-http-api)
8. [Exposing Peex via a Message Bus](#exposing-peex-via-a-message-bus)
9. [Flow Node Reference](#flow-node-reference)
10. [Implementing Service Task Workers](#implementing-service-task-workers)
11. [Writing Script Tasks](#writing-script-tasks)
12. [Gateway Conditions](#gateway-conditions)
13. [Supervision and Fault Tolerance](#supervision-and-fault-tolerance)
14. [Database Setup](#database-setup)

---

## Architecture Overview

Peex models each BPMN flow node as an individual OTP `GenServer` process. When a BPMN diagram is parsed and loaded, a `Supervisor` starts one GenServer per flow node. Process instances (tokens) flow between these GenServers via asynchronous `GenServer.cast/2` messages, which is what enables massive parallelism — thousands of tokens can traverse the process graph simultaneously without blocking each other.

```
┌─────────────────────────────────────────────────────┐
│                  ProcessSupervisor                  │
│  (Supervisor — one per loaded process model)        │
├─────────┬───────────┬────────────┬──────────────────┤
│ Start   │ Script    │ Service    │ Exclusive        │
│ Event   │ Task      │ Task       │ Gateway          │
│ (GenSrv)│ (GenSrv)  │ (GenSrv)   │ (GenSrv)         │
└─────────┴───────────┴────────────┴──────────────────┘

Tokens flow between GenServers via GenServer.cast({:on_enter, token})
```

Key components:

| Component | Module | Role |
|---|---|---|
| BPMN Parser | `Peex.Core.BPMNParser` | Parses `.bpmn` XML files into a list of `{module, config}` tuples |
| Process Supervisor | `Peex.Core.ProcessSupervisor` | Starts and supervises all flow node GenServers for a process model |
| Flow Node base | `Peex.Core.FlowNode` | Macro providing GenServer boilerplate, persistence helpers, and inter-node messaging |
| Process Token | `Contracts.Processtoken` | Ecto schema representing a running process instance |
| Repo | `Peex.Processtoken.Repo` | Ecto Postgres repository for token persistence |

---

## Prerequisites

- **Elixir** ~> 1.9
- **PostgreSQL** (for token persistence)
- Dependencies (from `mix.exs`):
  - `ecto_sql` ~> 3.2
  - `postgrex` ~> 0.15
  - `sweet_xml` ~> 0.6
  - `jason` ~> 1.1

---

## Embedding Peex in an Elixir Application

Peex is designed to be embedded directly into another Elixir/OTP application. There is currently no standalone HTTP API or message bus interface out of the box — interaction happens through direct Elixir function calls.

### Step 1: Add Peex as a Dependency

If Peex is published to Hex:

```elixir
# In your host application's mix.exs
defp deps do
  [
    {:peex_protyping, "~> 0.1.0"}
  ]
end
```

For local development or as a Git dependency:

```elixir
defp deps do
  [
    {:peex_protyping, path: "../peex_prototyping"}
    # or
    {:peex_protyping, git: "https://your-repo-url/peex_prototyping.git"}
  ]
end
```

### Step 2: Configure the Database

In your host application's `config/config.exs` (or environment-specific config):

```elixir
config :peex_protyping, Peex.Processtoken.Repo,
  database: "peex_prototyping",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"

config :peex_protyping, ecto_repos: [Peex.Processtoken.Repo]
```

### Step 3: Run Migrations

```bash
mix ecto.create
mix ecto.migrate
```

### Step 4: Ensure the Application Starts

Peex's application module (`Peex.Processtoken.Application`) automatically starts the Ecto Repo under its own supervision tree. When added as a dependency, OTP starts it automatically.

---

## Running a Process Instance Step by Step

The lifecycle of a process instance in Peex follows three stages: **parse**, **supervise**, **start**.

### 1. Parse the BPMN File

```elixir
nodes_with_config = Peex.Core.BPMNParser.parse("processes/example/example_process.bpmn")
```

This returns a list of `{module, config}` tuples, e.g.:

```elixir
[
  {Peex.Core.StartEvent, %{id: 'StartEvent_1', next_node_id: 'SequenceFlow_1lu12nm'}},
  {Peex.Core.ScriptTask, %{id: 'ScriptTask_0qrmmga', name: 'Initialize Counter', ...}},
  {Peex.Core.ServiceTask, %{id: 'ServiceTask_1ly7xt9', topic: 'Peex.Example.Service.increment_counter', ...}},
  ...
]
```

### 2. Start the Process Supervisor

```elixir
{:ok, supervisor_pid} = Peex.Core.ProcessSupervisor.start_link(nodes_with_config)
```

This starts one GenServer child per flow node, each registered globally as `{:global, {:servername, atom_id}}`.

> **Important:** `ProcessSupervisor` is registered as a named process (`Peex.Core.ProcessSupervisor`). Only one process model can be loaded at a time in the current implementation. To load a different model, you must stop the existing supervisor first.

### 3. Create and Launch a Token

```elixir
token = %Contracts.Processtoken{
  process_model_id: "Collaboration_1ti1prd",
  correlation_id: to_string(DateTime.utc_now()),
  identity: Base.encode64("your_identity_token"),
  payload: %{counter: 0}
}

:ok = Peex.Core.StartEvent.start(:StartEvent_1, token)
```

The token is now flowing through the process graph asynchronously. Each flow node:
1. Persists the token's arrival (`_persist_on_enter`)
2. Executes its logic (evaluate script, call service, check conditions, etc.)
3. Persists the updated payload (`_persist_on_exit`)
4. Casts `{:on_enter, token}` to the next flow node

### Complete Example

```elixir
# Parse and start
nodes = Peex.Core.BPMNParser.parse("processes/example/example_process.bpmn")
{:ok, _pid} = Peex.Core.ProcessSupervisor.start_link(nodes)

# Launch a process instance
token = %Contracts.Processtoken{
  process_model_id: "Collaboration_1ti1prd",
  correlation_id: "order-12345",
  identity: Base.encode64("user:42"),
  payload: %{counter: 1}
}

:ok = Peex.Core.StartEvent.start(:StartEvent_1, token)
```

---

## The Process Token

The process token (`Contracts.Processtoken`) is the carrier of state as it moves through the process graph. It is an Ecto schema backed by the `processtokens` database table.

### Fields

| Field | Type | Description |
|---|---|---|
| `process_instance_id` | UUID | Auto-generated unique identifier for this process instance |
| `process_model_id` | String | Identifier of the BPMN process model |
| `correlation_id` | String | Business key for correlating related instances |
| `identity` | String | Identity/auth context of the initiator |
| `payload` | Map | Arbitrary business data carried through the process |
| `markers` | List of maps | **Virtual field** (not persisted). Used internally by inclusive gateways to track expected token counts at join points |
| `flow_node_id` | String | ID of the flow node currently holding this token |
| `flow_node_instance_id` | String | UUID of the specific GenServer instance |
| `parent_caller_instance_id` | UUID | Reserved for subprocess/call activity support |
| `created_at` | DateTime | Timestamp of token creation |
| `updated_at` | DateTime | Timestamp of last update |

### Payload Convention

The `payload` is a free-form map. Service tasks, script tasks, and gateway conditions all interact with the payload through the `token` variable:

```elixir
# In a script task
result = %{counter: token.payload.counter + 1}

# In a condition expression
token.payload.counter > 10

# In a service task function
def my_function(token) do
  %{result: token.payload.input * 2}
end
```

The return value of service tasks and script tasks **replaces** the token's payload entirely. To preserve existing fields, merge explicitly:

```elixir
# Service task that preserves existing payload
def enrich(token) do
  Map.merge(token.payload, %{enriched: true})
end
```

---

## Running Multiple Process Instances in Parallel

Because flow nodes are GenServers and tokens flow via asynchronous casts, you can launch thousands of process instances simultaneously:

```elixir
for i <- 1..10_000 do
  token = %Contracts.Processtoken{
    process_model_id: "Collaboration_1ti1prd",
    correlation_id: "batch-#{i}",
    identity: Base.encode64("system"),
    payload: %{counter: 1, batch_id: i}
  }

  Peex.Core.StartEvent.start(:StartEvent_1, token)
end
```

Each token traverses the process graph independently. The BEAM scheduler distributes work across all available CPU cores automatically.

> **Note on join gateways:** Inclusive and parallel join gateways maintain per-process-instance state keyed by `process_instance_id`. Multiple instances converging at the same join gateway are tracked independently and will not interfere with each other.

---

## Exposing Peex via an HTTP API

Peex does not ship with an HTTP API, but integrating one via Phoenix is straightforward since Peex is a standard OTP application.

### Example: Phoenix Controller

```elixir
defmodule MyAppWeb.ProcessController do
  use MyAppWeb, :controller

  def start_instance(conn, %{"process_file" => file, "payload" => payload}) do
    # Assumes the process model is already loaded via ProcessSupervisor
    token = %Contracts.Processtoken{
      process_model_id: file,
      correlation_id: Ecto.UUID.generate(),
      identity: get_identity(conn),
      payload: payload
    }

    case Peex.Core.StartEvent.start(:StartEvent_1, token) do
      :ok ->
        json(conn, %{
          status: "started",
          process_instance_id: token.process_instance_id
        })

      {:error, reason} ->
        conn
        |> put_status(500)
        |> json(%{error: inspect(reason)})
    end
  end

  def load_process(conn, %{"file_path" => path}) do
    nodes = Peex.Core.BPMNParser.parse(path)
    {:ok, _pid} = Peex.Core.ProcessSupervisor.start_link(nodes)
    json(conn, %{status: "loaded"})
  end

  defp get_identity(conn) do
    # Extract from auth headers, session, etc.
    Base.encode64("api_user")
  end
end
```

### Example: Phoenix Router

```elixir
scope "/api", MyAppWeb do
  pipe_through :api

  post "/processes/load", ProcessController, :load_process
  post "/processes/start", ProcessController, :start_instance
end
```

### Querying Process State

Since tokens are persisted in Postgres, you can query them via Ecto:

```elixir
import Ecto.Query

# Find all tokens for a process instance
Peex.Processtoken.Repo.all(
  from t in Contracts.Processtoken,
  where: t.process_instance_id == ^instance_id
)

# Find tokens currently at a specific flow node
Peex.Processtoken.Repo.all(
  from t in Contracts.Processtoken,
  where: t.flow_node_id == "ServiceTask_1ly7xt9"
)
```

---

## Exposing Peex via a Message Bus

Peex does not include a message bus integration, but the OTP ecosystem provides several primitives that make it straightforward to add one.

### Option A: Phoenix.PubSub

Use `Phoenix.PubSub` to broadcast process lifecycle events and accept commands:

```elixir
# Broadcasting from inside a custom flow node or wrapper
Phoenix.PubSub.broadcast(MyApp.PubSub, "process:events", {
  :token_arrived,
  %{
    process_instance_id: token.process_instance_id,
    flow_node_id: state.id,
    payload: token.payload
  }
})

# Subscribing from an external consumer
Phoenix.PubSub.subscribe(MyApp.PubSub, "process:events")
```

### Option B: Erlang :pg (Process Groups)

For distributed BEAM clusters, `:pg` provides built-in process group management:

```elixir
# Join a group
:pg.join(:peex_workers, self())

# Send to all members
for pid <- :pg.get_members(:peex_workers) do
  send(pid, {:start_process, token})
end
```

### Option C: External Message Brokers

For integration with external systems (RabbitMQ, Kafka, etc.), use libraries like `Broadway` or `GenRMQ` to consume messages and translate them into `Peex.Core.StartEvent.start/2` calls:

```elixir
defmodule MyApp.ProcessStarter do
  use Broadway

  def handle_message(_, %Broadway.Message{data: data}, _) do
    payload = Jason.decode!(data)

    token = %Contracts.Processtoken{
      process_model_id: payload["model_id"],
      correlation_id: payload["correlation_id"],
      identity: payload["identity"],
      payload: payload["data"]
    }

    Peex.Core.StartEvent.start(:StartEvent_1, token)
    message
  end
end
```

---

## Flow Node Reference

| Flow Node | Module | BPMN Element | Configuration |
|---|---|---|---|
| Start Event | `Peex.Core.StartEvent` | `bpmn:startEvent` | `next_node_id` |
| End Event | `Peex.Core.EndEvent` | `bpmn:endEvent` | — |
| Task | `Peex.Core.Task` | `bpmn:task` | `name`, `next_node_id` |
| Service Task | `Peex.Core.ServiceTask` | `bpmn:serviceTask` | `name`, `topic` (camunda:topic), `next_node_id` |
| Script Task | `Peex.Core.ScriptTask` | `bpmn:scriptTask` | `name`, `script` (bpmn:script), `next_node_id` |
| Exclusive Split | `Peex.Core.ExclusiveSplitGateway` | `bpmn:exclusiveGateway` (>1 outgoing) | `next_nodes` with conditions |
| Exclusive Join | `Peex.Core.ExclusiveJoinGateway` | `bpmn:exclusiveGateway` (1 outgoing) | `next_node_id` |
| Inclusive Split | `Peex.Core.InclusiveSplitGateway` | `bpmn:inclusiveGateway` (>1 outgoing) | `next_nodes` with conditions, `paired_join_id` |
| Inclusive Join | `Peex.Core.InclusiveJoinGateway` | `bpmn:inclusiveGateway` (≤1 outgoing) | `next_node_id` |
| Parallel Split | `Peex.Core.ParallelSplitGateway` | Not parsed from BPMN (manual only) | `next_nodes` |
| Parallel Join | `Peex.Core.ParallelJoinGateway` | Not parsed from BPMN (manual only) | `next_node_id` |

---

## Implementing Service Task Workers

Service tasks delegate execution to an Elixir module and function, identified by the `camunda:topic` attribute.

### Topic Format

The topic is a dot-separated string following the pattern:

```
Module.Namespace.function_name
```

Everything before the last dot is the module name; the last segment is the function name.

Examples:
- `Peex.Example.Service.increment_counter` → calls `Peex.Example.Service.increment_counter/1`
- `MyApp.Billing.calculate_total` → calls `MyApp.Billing.calculate_total/1`

### Function Signature

The function receives the full token struct and must return a map that becomes the new payload:

```elixir
defmodule MyApp.Billing do
  def calculate_total(token) do
    items = token.payload["items"] || []
    total = Enum.reduce(items, 0, fn item, acc -> acc + item["price"] end)
    Map.merge(token.payload, %{"total" => total})
  end
end
```

### Reference: Built-in Example

```elixir
defmodule Peex.Example.Service do
  def increment_counter(token) do
    current_value = token.payload.counter
    %{counter: current_value + 1}
  end
end
```

> **Important:** The function's return value **replaces** the entire `token.payload`. If you need to preserve existing payload fields, use `Map.merge/2`.

---

## Writing Script Tasks

Script tasks contain inline Elixir code in the `bpmn:script` element. The code is evaluated at runtime with `Code.eval_string/2`.

### Available Variables

Inside the script, the variable `token` is bound to the current process token struct. You can access `token.payload`, `token.process_instance_id`, etc.

### Return Value

The evaluated result of the script becomes the new `token.payload`.

### Examples

```elixir
# Initialize a counter
result = %{counter: 1}

# Transform payload
result = %{counter: token.payload.counter * 2, doubled: true}

# Clear payload
result = %{}
```

> **Security note:** `Code.eval_string/2` executes arbitrary Elixir code. Ensure that BPMN files are only loaded from trusted sources.

---

## Gateway Conditions

Both exclusive and inclusive gateways evaluate conditions on outgoing sequence flows. Conditions are Elixir expressions placed in the `bpmn:conditionExpression` element of a sequence flow.

### Available Variables

The variable `token` is available, providing access to the token struct and its payload.

### Exclusive Gateway

Evaluates conditions in order. The **first** condition that returns `true` wins. A sequence flow without a condition acts as the **default route** and is evaluated last.

```elixir
# Condition on a sequence flow
token.payload.counter > 10

# Another branch
token.payload["status"] == "approved"
```

### Inclusive Gateway

Activates **all** branches whose condition evaluates to `true` (or have no condition). The token is forked to every activated branch.

```elixir
# Path A: always taken (no condition = unconditional)
# Path B: taken when amount exceeds threshold
token.payload["amount"] > 1000
```

---

## Supervision and Fault Tolerance

### ProcessSupervisor

`Peex.Core.ProcessSupervisor` is an OTP `Supervisor` with `:one_for_one` strategy. If a flow node GenServer crashes, only that specific node is restarted — all other nodes continue operating.

### Global Registration

Flow nodes register globally via `{:global, {:servername, flow_node_id}}`. This means:
- Node lookup works across a BEAM cluster (if distributed Erlang is configured)
- Flow node IDs must be unique within the cluster

### Token Persistence

Every token transition is persisted to Postgres via Ecto. If a node crashes mid-processing, the token's last known position can be queried from the database for recovery.

---

## Database Setup

### Using Docker for Postgres

```bash
docker run --name peex-postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_USER=postgres \
  -p 5432:5432 \
  -d postgres:12-alpine
```

### Create Database and Run Migrations

```bash
mix ecto.create
mix ecto.migrate
```

### Schema: `processtokens`

| Column | Type |
|---|---|
| `id` | integer (PK) |
| `process_instance_id` | UUID |
| `process_model_id` | string |
| `correlation_id` | string |
| `identity` | string |
| `flow_node_instance_id` | string |
| `flow_node_id` | string |
| `parent_caller_instance_id` | UUID |
| `payload` | map (JSONB) |
| `created_at` | UTC datetime |
| `updated_at` | UTC datetime |

### Environment Variables (Docker)

When running in Docker, the following environment variables override the database config:

| Variable | Default |
|---|---|
| `DATABASE_NAME` | `peex_prototyping` |
| `DATABASE_USER` | `postgres` |
| `DATABASE_PASS` | `postgres` |
| `DATABASE_HOST` | `localhost` |
