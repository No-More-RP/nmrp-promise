# NMRP Promise

A **nanos world** package that brings a complete, JS-grade `Promise` to Lua. It
bundles a dependency-free [Promises/A+](https://promisesaplus.com/) core (vendored as
a git submodule) and wires it to the nanos engine: it installs the scheduler and
exports the globals **`Promise`**, **`async`** and **`await`** to every other package.

The async engine is the **Lua coroutine**: `:Await()` parks the running coroutine and
the promise resumes it on settle — no event loop. Handler dispatch (`:Then`) is
synchronous, so chaining, combinators and `async`/`await` work everywhere; only the
time-based helpers (`Promise.delay`, `:Timeout`) need the scheduler, which this package
plugs into nanos' `Timer.SetTimeout` for you.

## Installation

Add `nmrp-promise` to your package `packages_requirements`:

```toml
[script] # or [game_mode]
    packages_requirements = [ "nmrp-promise" ]
```

The globals `Promise`, `async` and `await` are then available everywhere (shared Lua
state between packages, on both server and client).

> The core ships vendored, so the package runs out of the box. If you cloned the repo,
> pull the submodule first: `git submodule update --init --recursive`.

## Creating a promise

```lua
-- Executor style (recommended): wrap a callback API.
local p <const> = Promise(function(resolve, reject)
    do_async(function(err, value)
        if (err) then reject(err); else resolve(value); end
    end);
end);

-- Deferred style: get the handle now, settle it later.
local d <const> = Promise();
do_async(function(_, value) d:Resolve(value); end);

-- Static factories.
Promise.resolve(42);
Promise.reject("nope");
```

## Chaining

`:Then` always returns a **new** promise, so chains transform values, recover from
errors, and flatten nested promises automatically.

```lua
fetch_user(id)
    :Then(function(user) return user.name; end)         -- transform
    :Then(function(name) return load_avatar(name); end) -- return a promise -> flattened
    :Catch(function(err) return default_avatar; end)    -- recover
    :Finally(function() hide_spinner(); end);           -- always runs
```

| Method | Description |
|---|---|
| `:Then(onFulfilled, onRejected)` | Attach handlers, return a chained promise. |
| `:Catch(onRejected)` | Sugar for `:Then(nil, onRejected)`. |
| `:Finally(onFinally)` | Run on settle, pass value/reason through. |
| `:Tap(onFulfilled)` | Side-effect on fulfilment, forward the value. |
| `:Timeout(ms, reason?)` | Reject if not settled within `ms`. |
| `:Resolve(value)` / `:Reject(reason)` | Settle a deferred promise. |
| `:Await()` / `:await()` | Block the current coroutine for the value (re-raises rejections). |
| `:GetState()` / `:IsSettled()` | Introspection. |

> `:Await()` parks a coroutine, so it must run inside one (an `async(...)` body or a
> `coroutine.wrap`). It is forbidden on the main thread.

## Combinators (static)

```lua
Promise.all({ a, b, c })        -- array of values, rejects on first failure
Promise.allSettled({ a, b })    -- { {status="fulfilled", value=}, {status="rejected", reason=} }
Promise.race({ a, b })          -- first to settle (either way)
Promise.any({ a, b })           -- first to FULFIL, else AggregateError
Promise.map(list, mapper)       -- map (mapper may return promises), then all
Promise.try(fn, ...)            -- run fn safely into a promise
Promise.delay(ms, value?)       -- resolve after a delay (uses the nanos Timer)
Promise.timeout(p, ms, reason?) -- race p against a timeout (uses the nanos Timer)
Promise.resolve(v) / Promise.reject(r) / Promise.is(v)
```

## async / await

`async` runs a function in a coroutine so it can `:Await()`, and itself returns a
promise for the function's result.

```lua
local job <const> = async(function()
    local user <const> = fetch_user(1):Await();
    local posts <const> = await(fetch_posts(user.id)); -- global await: any thenable
    return #posts;
end);

job:Then(function(n) print(("loaded %d posts"):format(n)); end)
   :Catch(function(err) print("failed:", err); end);
```

A rejected promise awaited inside `async` raises an error you can `pcall`, exactly like
JavaScript `try/await`.

## Unhandled rejections

A rejection that is never observed (no `:Catch`, `:Then(_, onRejected)` or `:Await`) is
reported once a tick has passed. Customise the handler:

```lua
Promise.OnUnhandledRejection(function(reason, message)
    Console.Error(("Unhandled promise rejection: %s"):format(message));
end);
```

## Interop

The instance metatable carries `__name == "Promise"`, and a generic thenable-adoption
layer recognises `Then` / `next` / `then`, so foreign promises flow through
`Promise.all`, `:Then`, `await`, etc. This is what lets [Norm](https://github.com/No-More-RP/nmrp-norm)
and [nmrp-rpc](https://github.com/No-More-RP/nmrp-rpc) return real nmrp-promise instances.

## License

[MIT](LICENSE) © 2026 JustGodWork.
