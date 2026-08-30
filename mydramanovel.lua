-- MyDramaNovel extension stub
local MyDramaNovel = {
  id = "mydramanovel",
  name = "MyDramaNovel",
  version = 1,
}

-- Called when the extension is loaded by the host
function MyDramaNovel.init(opts)
  -- opts may contain host-specific APIs; keep this lightweight
  if opts and opts.log then
    opts.log("MyDramaNovel initialized")
  else
    print("MyDramaNovel initialized")
  end
end

-- Example action the host can call
function MyDramaNovel.run(context)
  -- context is host-specific. Return a simple confirmation for now.
  return {
    ok = true,
    message = "MyDramaNovel extension executed",
    context_summary = (type(context) == "table") and (context.summary or nil) or nil,
  }
end

return MyDramaNovel
