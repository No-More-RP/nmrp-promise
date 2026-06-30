require 'module/promise.class.lua';

--- Give the (otherwise framework-agnostic) promise core a scheduler so the
--- time-based helpers (Promise.delay / :Timeout) and unhandled-rejection
--- detection work. The core stays pure Lua and remains usable without this:
--- handler dispatch is synchronous and :Await() rides on coroutines. This is the
--- only place that touches a nanos-native API.
Promise.SetTimer(Timer.SetTimeout);

Package.Export("Promise", Promise);
Package.Export("async", async);
Package.Export("await", await);
