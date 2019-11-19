import { useEffect, useState } from "react";

export function useFetch<T>(info: RequestInfo, init?: RequestInit) {

    const [response, setResponse] = useState<T>() 

    useEffect(() => {

        const fetchData = async () => {

            const res = await fetch(info, init);

            if (res.status !== 200 && res.status !== 201) {
                return
            } 

            const json = await res.json() as T;

            setResponse(json);
        };

        fetchData();

    }, [info, init]);

    return response
}

export function useFetchAsString(info: RequestInfo, init?: RequestInit) {

    const [response, setResponse] = useState<string>() 

    useEffect(() => {

        const fetchData = async () => {

          const res = await fetch(info, init);
          const json = await res.text();

          setResponse(json);
        };

        fetchData();

    }, [info, init]);

    return response
}