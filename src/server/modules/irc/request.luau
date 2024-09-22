local HttpService = game:GetService("HttpService")

local proxyHost = "https://irc-proxy.beenman.com/"
local token = require(script.Parent.token)

type endpoint = 'connect' | 'update' | 'status' | 'close'

type HttpMethod = ("CONNECT" | "DELETE" | "GET" | "HEAD" | "OPTIONS" | "PATCH" | "POST" | "PUT" | "TRACE")?
type RblxHttpRequest = {
	Url: string,

	Method: HttpMethod,
	Headers: {[string]: string}?,
	Body: string?,
	Compress: Enum.HttpCompression
}

export type RblxHttpResponse = {
	Success: boolean,
	StatusCode: number,
	StatusMessage: string,

	Headers: {[string]: string},
	Body: string?
}

return function<T>(endpoint: endpoint, method: HttpMethod, body: T?): (boolean, RblxHttpResponse)
	local options: RblxHttpRequest = {
		Url = proxyHost..endpoint,
		Method = method,
		Compress = Enum.HttpCompression.None,
		Body = body and HttpService:JSONEncode(body),

		Headers = {
			['X-Auth-Token'] = token,
			['Content-Type'] = 'application/json'
		}
	}

	local success, response: RblxHttpResponse = pcall(HttpService.RequestAsync, HttpService, options)
	return success, response
end