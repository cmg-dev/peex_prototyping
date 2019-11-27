import React, { ChangeEvent, useState, useEffect } from "react"

import * as styles from "./App.scss"

import { BPMNView } from "./components/BPMNView"
import { useActiveFlowNode } from "./Hooks/useActiveFlowNode"
import { useFetch, useFetchAsString } from "./Hooks/useFetch"

interface IAppProps {
    title: string
}

const tasks: string[] = [
    "StartEvent_1", 
    "ScriptTask_0qrmmga", 
    "ExclusiveGateway_0btyrc3", 
    "ServiceTask_1ly7xt9", 
    "ExclusiveGateway_1dj30yk",
    "ExclusiveGateway_0btyrc3", 
    "ServiceTask_1ly7xt9", 
    "ExclusiveGateway_1dj30yk", 
    "ScriptTask_19h9wpb", 
    "EndEvent_1"
]

interface IProcessInfo {
    id: string
    start_events: string[]
}

export const App: React.FC<IAppProps> = _props => {

    const activeFlowNode = useActiveFlowNode()

    const processes = useFetch<IProcessInfo[]>("/processes") ?? []

    const [selectedProcess, setSelectedProcess] = useState<string>()

    const [startEvents, setStartEvents] = useState<string[]>([])

    const [selectedStartEvent, setSelectedStartEvent] = useState()

    const diagram = useFetchAsString(`/processes/${selectedProcess}/definition`)

    function handleProcessSelected(event: ChangeEvent<HTMLSelectElement>) {
        
        const process = processes.find(process => process.id == event.target.value)

        setSelectedProcess(event.target.value)

        setStartEvents(process?.start_events ?? [])
        setSelectedStartEvent(process?.start_events?.[0])
    }

    function handleStartEventSelected(event: ChangeEvent<HTMLSelectElement>) {
        setSelectedStartEvent(event.target.value)
    } 

    async function handleStartProcess() {

        if (!selectedProcess || !selectedStartEvent) {
            return
        }

        const url = `/processes/${selectedProcess}/start/${selectedStartEvent}`

        await fetch(url, { method: "POST" })
    }

    useEffect(() => {

        if (processes.length <= 0) {
            return
        }

        const defaultSelectedProcess = processes[0]

        setSelectedProcess(defaultSelectedProcess.id)
        setStartEvents(defaultSelectedProcess.start_events)
        setSelectedStartEvent(defaultSelectedProcess.start_events[0])

    }, [processes])

    return (
        <div className={styles["app"]}>
            <div>
                <select onChange={handleProcessSelected} value={selectedProcess}>
                {processes.map(process =>
                    <option key={`process_${process.id}`} value={process.id}>{process.id}</option>
                )}
                </select>
                <select onChange={handleStartEventSelected} value={selectedStartEvent}>
                {startEvents.map(startEvent =>
                    <option key={`startEvent_${startEvent}`} value={startEvent}>{startEvent}</option>
                )}
                </select>
                <button onClick={handleStartProcess}>Start</button>
            </div>
            <BPMNView diagram={diagram} activeTask={activeFlowNode} />
        </div>
    )
}
