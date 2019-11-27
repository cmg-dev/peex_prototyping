import React, { useRef, useEffect, useState } from "react"

import BpmnViewer from "bpmn-js"

import * as styles from "./BPMNView.scss"

interface IBPMNViewProps {
    diagram?: string
    activeTask?: string
}

export const BPMNView: React.FC<IBPMNViewProps> = props => {

    const {diagram, activeTask} = props

    const containerRef = useRef<HTMLDivElement>()
    const activeTaskMarkerRef = useRef<string>()
    const [viewer, setViewer] = useState<any>()

    useEffect(() => {

        if (!diagram) {
            return
        }

        const viewer = new BpmnViewer({
            container: containerRef.current,
        })

        viewer.importXML(diagram, (error?: Error) => {

            if (error) {
                console.log('error rendering', error);
                return
            }
            
            setViewer(viewer)
        })


        return () => {
            viewer.detach()
        }
    }, [diagram])

    useEffect(() => {

        if (!viewer) {
            return
        }

        if (activeTaskMarkerRef.current === activeTask) {
            return
        }

        const canvas = viewer.get("canvas")

        if (activeTaskMarkerRef.current) {
            canvas.removeMarker(activeTaskMarkerRef.current, styles["active-task"])
        }

        if (!props.activeTask) {
            return
        }

        canvas.addMarker(props.activeTask, styles["active-task"])

        activeTaskMarkerRef.current = props.activeTask

    }, [viewer, activeTask])

    return (
        <div className={styles["bpmn-view"]} ref={containerRef}></div>
    )
}