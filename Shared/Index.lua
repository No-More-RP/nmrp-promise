require 'module/promise.class.lua';

--- Wire the nanos event loop into the (otherwise framework-agnostic) promise core
--- so callbacks defer as microtasks and Promise.delay / :Timeout work. The core
--- stays pure Lua and remains usable without this (synchronous scheduling); this
--- is the only place that touches a nanos-native API.
Promise.SetTimer(Timer.SetTimeout);

Package.Export("Promise", Promise);
Package.Export("async", async);
Package.Export("await", await);
