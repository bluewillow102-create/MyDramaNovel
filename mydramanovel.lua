-- MyDramaNovel extension: Random Joke Generator
-- Uses an external joke API. The host may provide a `fetch(url)` function and a `json.decode` function via opts.

local MyDramaNovel = {
  id = "mydramanovel",
  name = "MyDramaNovel",
  version = 2,
}

local host = {}
local socket_http, ltn12, dkjson, cjson

local function try_require(name)
  local ok, m = pcall(require, name)
  if ok then return m end
  return nil
end

-- Try to load common Lua HTTP/JSON libraries as a fallback
socket_http = try_require("socket.http")
ltn12 = try_require("ltn12")
dkjson = try_require("dkjson")
cjson = try_require("cjson")

function MyDramaNovel.init(opts)
  -- opts may include:
  --  - fetch(url) -> string body
  --  - json = { decode = function(str) ... end }
  --  - log = function(msg) ... end
  host = opts or {}
  if host.log then
    host.log("MyDramaNovel initialized (joke generator)")
  else
    print("MyDramaNovel initialized (joke generator)")
  end
end

local function fetch_url(url)
  -- Prefer host-provided fetch function
  if host and type(host.fetch) == "function" then
    local ok, res = pcall(host.fetch, url)
    if ok then return true, res end
    return false, tostring(res)
  end

  -- Try LuaSocket (may not support HTTPS depending on build)
  if socket_http and ltn12 then
    local body = {}
    local res, code, headers, status = socket_http.request{ url = url, sink = ltn12.sink.table(body) }
    if res then
      return true, table.concat(body)
    else
      return false, tostring(code or status)
    end
  end

  return false, "no http client available; provide opts.fetch(url)"
end

local function decode_json(str)
  if host and host.json and type(host.json.decode) == "function" then
    local ok, res = pcall(host.json.decode, str)
    if ok then return res end
    return nil, tostring(res)
  end
  if dkjson and type(dkjson.decode) == "function" then
    local ok, res = pcall(dkjson.decode, str)
    if ok then return res end
    return nil, tostring(res)
  end
  if cjson and type(cjson.decode) == "function" then
    local ok, res = pcall(cjson.decode, str)
    if ok then return res end
    return nil, tostring(res)
  end
  return nil, "no json decoder available; provide opts.json.decode"
end

-- Public function: fetches a random joke from an external API and returns a table
function MyDramaNovel.random_joke()
  -- Using a free public API that requires no API key
  local api = "https://official-joke-api.appspot.com/random_joke"
  local ok, body_or_err = fetch_url(api)
  if not ok then
    return { ok = false, error = "fetch_error: " .. tostring(body_or_err) }
  end

  local obj, err = decode_json(body_or_err)
  if not obj then
    return { ok = false, error = "json_error: " .. tostring(err) }
  end

  -- official-joke-api returns { id, type, setup, punchline }
  local joke_text
  if obj.setup and obj.punchline then
    joke_text = obj.setup .. " " .. obj.punchline
  else
    -- Fallback for other APIs
    joke_text = obj.joke or obj.value or obj.message or "(no joke found)"
  end

  return { ok = true, joke = joke_text, raw = obj }
end

-- Host-facing run method: accepts context.action == "random_joke" to return a joke
function MyDramaNovel.run(context)
  context = context or {}
  if context.action == "random_joke" or context.action == "joke" then
    return MyDramaNovel.random_joke()
  end
  -- Default behavior: return a short description
  return {
    ok = true,
    message = "MyDramaNovel extension ready. Call action='random_joke' to fetch a joke.",
  }
end

-- Export
return MyDramaNovel
