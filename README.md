# Network Library

The `Network` library provides a type-safe, high-level interface for RemoteEvents and RemoteFunctions in Roblox. It automatically manages the creation, replication, and invocation of remotes, meaning you no longer have to manually create folders, assign remotes, or handle client/server differences.

By enforcing argument type safety and abstracting away the boilerplate, this library reduces runtime errors and makes networking incredibly simple. It also features a powerful, optional [Middleware](#middleware) system that allows you to secure your network events (like adding rate-limiters or admin checks) without cluttering your core game logic.

---

## Installation

You can install the latest version of NetworkManager directly from GitHub:

1. Navigate to the [Latest Release Page](https://github.com/Distracted-Games/NetworkManager/releases/latest).
2. Download the `.rbxm` file attached to the release.
3. Drag and drop the `.rbxm` file into Roblox Studio, moving the contents to inside `ReplicatedStorage`.

---

## Features

* **Zero-Boilerplate Setup**: Automatic creation of RemoteEvent and RemoteFunction folders and instances.
* **Strict Typing**: Type-safe enums for all remote names, reducing typo-prone string usage and providing rich auto-complete.
* **Smart Routing**: Automatically handles client/server distinctions when connecting events or binding functions.
* **Safe Invocation**: Client/server invocations are wrapped in `pcall` for automatic network error handling.
* **Middleware Support**: Intercept and filter network requests easily using built-in or custom middleware.
* **Modular Design**: Lightweight and fully compatible with Rojo and VS Code workflows.

---

## Getting Started

### Server Setup

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = require(ReplicatedStorage.Network)

-- Initialize remotes on the server
Network.startServer()
```

### Client Setup

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = require(ReplicatedStorage.Network)

-- Wait for server to replicate all remotes
Network.startClientAsync()
```

> **Warning:** Both `startServer()` and `startClientAsync()` must be called before any other Network functions are used. For better script management in this regard, I suggest using a framework such as my own [ModuleLoader](https://github.com/Distracted-Games/ModuleLoader) framework.

---

## Using Network

### Adding RemoteEvents/RemoteFunctions

Inside of the `RemoteName` folder are the `RemoteEventName` and `RemoteFunctionName` Enum lists. Simply add the name of the remote that you want to add to the appropriate list (i.e., `"ExampleRemote"`, `"ExampleRemoteFunc"`). These files contain example remotes already, simply replace them with your own.

> *Note: If you only have a single remote string in the list, the custom StrictEnum.FromUnion type function will show a type error. Once you add a second remote to the list, this error will go away. If you only want to use a single RemoteEvent or RemoteFunction, or none of one or the other, you can simply remove the custom type function altogether to clear the error.*

### Connecting RemoteEvents

```lua
Network.connectEvent(Network.RemoteEvents.ExampleRemote, function(player, message)
    print(player.Name, message)
end)
```
*Note: Automatically handles `OnServerEvent` vs `OnClientEvent` based on where it is called.*

### Binding RemoteFunctions

```lua
Network.bindFunction(Network.RemoteFunctions.ExampleRemoteFunc, function(player, x, y)
    return x + y
end)
```
*Note: Automatically handles `OnServerInvoke` vs `OnClientInvoke` based on where it is called. (Please don't be that person that uses server-to-client RemoteFunctions)*

### Firing Events

```lua
-- From client to server
Network.fireServer(Network.RemoteEvents.ExampleRemote, "Hello Server!")

-- From server to one client
Network.fireClient(Network.RemoteEvents.ExampleRemote, player, "Hello Player!")

-- From server to all clients
Network.fireAllClients(Network.RemoteEvents.ExampleRemote, "Hello Everyone!")

-- From server to specific clients in a table
Network.fireSpecificClients(Network.RemoteEvents.ExampleRemote, { player1, player2 }, "Hello!")

-- From server to all clients EXCEPT those in a table
Network.fireAllClientsExcept(Network.RemoteEvents.ExampleRemote, { excludedPlayer }, "Hello!")

-- From server to all clients within range of a position
Network.fireClientsInRange(Network.RemoteEvents.ExampleRemote, Vector3.zero, 100, "Hello!")

-- From server to all clients within range EXCEPT those in a table
Network.fireClientsInRangeExcept(Network.RemoteEvents.ExampleRemote, Vector3.zero, 100, { excludedPlayer }, "Hello!")
```

### Invoking Functions

```lua
-- Client calls server function
local success, result = Network.invokeServerAsync(Network.RemoteFunctions.ExampleRemoteFunc, 2, 3)

-- Server calls client function (You probably shouldn't be doing this)
local success, result = Network.invokeClientAsync(Network.RemoteFunctions.ExampleRemoteFunc, player, 2, 3)
```
*Note: All invocations are wrapped in `pcall` to prevent the client or server from hanging indefinitely if a network error occurs.*

---

## Middleware

Middleware functions act as security checkpoints for your network events. They intercept the event *before* your main callback runs, allowing you to check conditions (like cooldowns or admin privileges) and decide whether to let the event through or drop it.

This is highly recommended for securing your server from bad actors or exploiters without cluttering your core game code.

### Using Built-in Middleware

The library comes with two built-in middlewares that you can easily attach to any `connectEvent` or `bindFunction` call by passing them in an array as the third argument:

#### 1. RateLimit
Prevents players from spamming an event. The argument is the cooldown in seconds.

```lua
Network.connectEvent(
    Network.RemoteEvents.ShootWeapon,
    function(player, targetPos)
        -- This logic will only run if the player hasn't fired in the last 0.5 seconds
    end,
    {
        Network.Middleware.RateLimit(0.5)
    }
)
```

#### 2. Admin
Restricts an event so that only players with specific `UserId`s can trigger it.

```lua
Network.connectEvent(
    Network.RemoteEvents.AdminCommand,
    function(player, command)
        -- This logic will only run if the player's UserId is 12345678 or 87654321
    end,
    {
        Network.Middleware.Admin({ 12345678, 87654321 })
    }
)
```

### Stacking Middleware

You can combine multiple middleware functions simply by adding them to the array. They will be checked in order.

```lua
Network.connectEvent(
    Network.RemoteEvents.SpecialAction,
    function(player)
        -- Game logic here
    end,
    {
        Network.Middleware.Admin({ 12345678 }), -- Must be an admin
        Network.Middleware.RateLimit(1)         -- Can only fire once per second
    }
)
```

### Passing Your Own Custom Middleware

You can pass any function that returns `(boolean, string?)` to the array. The `boolean` is the value that determines if the remote should be allowed to run, the optional `string?` is useful specifically for RemoteFunctions as the `Network` module will kick back a `false, errorMessage` to the caller in case of failure.

```lua
local function LevelRequirementMiddleware(player: Player): (boolean, string?)
    local playerLevel = player:GetAttribute("Level") or 1

    if playerLevel >= 10 then
        return true, nil -- returning `nil` as the second value to satisfy new Luau type solver
    end
    
    return false, "You must be at least Level 10 to perform this action!"
end

-- Example using a RemoteFunction so the client can receive the error message
Network.bindFunction(
    Network.RemoteFunctions.UnlockSecretArea,
    function(player)
        return "Welcome to the secret area!"
    end,
    { LevelRequirementMiddleware }
)
```
