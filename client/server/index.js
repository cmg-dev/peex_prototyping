const path = require('path')
const express = require('express')
const amqp = require("amqp")
const request = require("request-promise-native")
const app = express()

const http = require('http').createServer(app)
const io = require('socket.io')(http)

app.get('/', (_, res) =>{
    res.sendFile(path.join(__dirname,'../build/index.html'));
});

app.get('/processes', async (_, res) => {

    let response = await request("http://localhost:4000/processes")

    res.contentType('application/json')
    res.send(response)
})

app.get('/processes/:processId/definition', async (req, res) => {

    const processId = req.params["processId"]

    let url = `http://localhost:4000/processes/${processId}/definition`

    let response = await request(url)

    res.contentType('application/xml')
    res.send(response)
});

app.post('/processes/:processId/start/:startEventId', async (req, res) => {

    const processId = req.params["processId"]
    const startEventId = req.params["startEventId"]

    let url = `http://localhost:4000/processes/${processId}/start/${startEventId}`
    console.log(url)

    let response = await request(url, { method: "POST" })

    res.send(response)
});

app.use(express.static(path.join(__dirname, '../build')))

io.on('connection', function(socket){

    console.log("Client connected")

    socket.on("disconnect", () => {
        console.log("Client disconnected")
    })
});

http.listen(3000, function(){
    console.log('listening on *:3000');
});


const amqpConfig = {
    host: "localhost",
    login: "guest",
    password: "guest",
}

const connection = amqp.createConnection(amqpConfig)

connection.on("ready", () => {

    connection.queue("peex_monitoring", queue => {

        queue.bind("peex_exchange")

        queue.subscribe(message => {

            token = JSON.parse(message.data.toString())

            io.emit("flow_node_activated", token.flow_node_id)
        })
    })
})
