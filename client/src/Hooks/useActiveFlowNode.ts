import { useState, useEffect } from "react";

interface SocketIO {

    on(topic: string, messageHandler: (message: any) => void): void

    disconnect(): void
}

export function useActiveFlowNode(): string | undefined {

    const [activeFlowNode, setActiveFlowNode] = useState<string | undefined>()

    useEffect(() => {

        const socket = window["io"]() as SocketIO

        socket.on("flow_node_activated", (activatedFlowNode: string) => {
            console.log("next_node")
            setActiveFlowNode(activatedFlowNode)
        })

        return () => {
            socket.disconnect()
        }
    }, [])

    return activeFlowNode
}