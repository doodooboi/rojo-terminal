local request = require(script.Parent.Parent.request)

return function(host: string, port: number, secure: boolean): (boolean, request.RblxHttpResponse)
    return request("connect", "POST", {
        host = host,
        port = port,
		secure = secure
    })
end
