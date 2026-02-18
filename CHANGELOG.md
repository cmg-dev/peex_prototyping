# Changelog

## [Unreleased]

### Feat
- Implement inclusive gateway (split + join) with marker-based pub/sub activation
- Add generic `bpmn:task` parsing and execution (`Peex.Core.Task`)
- Extend `BPMNParser` to handle `inclusiveGateway` elements with paired join resolution via BFS
- Add condition expression to `feedback_volker_joingw.bpmn` for exclusive gateway testability

### Fix
- Preserve token markers through `FlowNode._persist_on_exit` calls
- Atomize `config.id` in `ProcessSupervisor._construct_child` so node IDs are consistent atoms (was charlist from SweetXml)

### Previous Feat
- Created `processes/stc_process.bpmn` to model the Skip The Counter (STC) car rental process flow based on the STC architecture diagram.
- Added `BPMNDiagram` visualization data to `processes/stc_process.bpmn` to support graphical editing.
- feat: Add BPM assessment guide for CTO audience (`docs/bpm_assessment_guide.md`)
- feat: Add BPM assessment prompt template for AI agents (`docs/bpm_assessment_prompt.md`)
