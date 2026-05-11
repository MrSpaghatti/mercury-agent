import std/[asynchttpserver, asyncdispatch, net]

var server = newAsyncHttpServer()
asyncCheck server.serve(Port(0), proc (req: Request) {.async.} = discard)

let localAddr = server.getPort()
echo "Port: ", localAddr.int
