# DAO-RPC protocol

Wire contract between the browser client and the selfhost server. The transport
boundary is a **DAO method**, not a SQL statement: one round trip carries a whole
method, so a transaction runs entirely on the server and no network sits inside
SQLite's writer lock.

`kProtocolVersion` (`lib/src/protocol.dart`) is currently **1**. Client and
server ship in the same image, so a mismatch only means a stale browser tab —
the client is told to reload rather than negotiating.

Status: implemented and wired on both ends for all 23 DAOs (266 methods).
`packages/core/tool/generate_rpc.dart` emits the stubs, the per-DAO dispatchers,
the name→dispatcher table and `RemoteDaoSet`; `--survey` type-checks the whole
surface without writing anything.

The browser reaches the server through `DioRpcTransport`
(`lib/core/rpc/dio_rpc_transport.dart`), which posts to the page's own origin.
A `flutter run -d chrome` session serves the page from somewhere else, so it
needs `--dart-define=SERVER_BASE_URL=http://localhost:8080` — the same define
also points `/proxy` (below) at that server.

## Request

`POST /rpc`, `Content-Type: application/json`

```json
{
  "protocol": 1,
  "dao": "CollectionDao",
  "method": "addItemsBatchReturningIds",
  "args": { "collectionId": 12, "items": [ /* … */ ] }
}
```

- `dao` — the concrete class name in `packages/core/lib/database/dao/`.
- `method` — a public async method of that class.
- `args` — named arguments as an object. Positional parameters are passed under
  their declared names too; the generator knows the signature on both ends.

## Response

```json
{ "ok": true, "result": [ "42", "43" ] }
```

```json
{ "ok": false, "error": { "kind": "database", "message": "UNIQUE constraint failed" } }
```

- `kind` is a stable machine-readable tag (`database`, `notFound`,
  `badRequest`, `protocol`, `internal`); `message` is for logs, never parsed.
- The client rethrows the error as the same exception type the local DAO would
  have thrown, so callers above the DAO layer see no difference.
- HTTP status stays `200` for a DAO-level error — the call reached the DAO and
  came back. Transport failures use real 4xx/5xx.

## Type rules

Only JSON-safe values cross the wire. Conversion happens at the boundary, never
in the DAO.

| Dart | Wire | Note |
|------|------|------|
| `int` | **string** | every one of them, see below |
| `double`, `bool`, `String` | as-is | doubles are exact in JS |
| `DateTime` | ISO-8601 string, UTC | `toUtc().toIso8601String()` |
| `enum` | `.name` string | never the index — reordering must not break stored data |
| model | object of its constructor parameters | see below |
| `null` | `null` | a missing key and an explicit null mean the same |
| `List` / `Set` / `Iterable` | array | element rules apply recursively |
| `Map` with a `String` / `int` / enum key | object | keys stringified |
| `Map` with any other key | array of `{k, v}` | a record or a nullable key has no JSON-object form |
| a sealed hierarchy | object with a `_` tag | see below |
| record | object with field names | positional fields as `"$1"`, `"$2"` |
| `dynamic` (a raw row) | tagged | `{"$i": "123"}` for an int, `{"$b": "<base64>"}` for bytes |
| a value class | object of its constructor parameters | **not** `toDb()`, see below |

### Every int is a string

`dart2js` compiles `int` to a double: everything above 2^53 loses precision.
Stable ids from `fnv1a64` (`packages/core/lib/utils/stable_id.dart` — Google
Books, MangaDex and friends) are 63-bit and already sit in real databases, so
they cannot be renumbered.

The rule is **all ints, not just id-shaped ones**. Deciding which parameter is
"an id" is a guess the generator cannot make safely, and one missed guess is a
silently corrupted identifier. Counts and sizes ride along as strings; the cost
is a few bytes.

`Map<String, dynamic>` — a raw database row — has no static type to drive that
rule, and `external_id` inside one is exactly the 63-bit case. Those values are
therefore *tagged*: an int becomes `{"$i": "123"}`, bytes become
`{"$b": "<base64>"}`, and everything else stays a plain JSON value. Without the
tag the far side could not tell a genuine string from a stringified int.

The browser must never *compute* an id: `fnv1a64` is BigInt-based and compiles,
but its `toInt()` is lossy in dart2js. Ids come from the server.

### Models travel by constructor, not by `toDb()`

`toDb()` is a *storage* codec: it emits the row a table holds, which is less
than the object holds. A hydrated `CollectionItem` carries its `movie` /
`game` / `anime`; `toDb()` does not, so a `toDb`-based wire format would have
returned stripped items from `getCollectionItemsWithData` and no type error
would have shown it.

So a model is encoded field by field from its unnamed constructor: every
parameter goes on the wire, which is lossless by construction. A class without
a generative unnamed constructor fails the generator.

### Sealed hierarchies are tagged unions

A sealed class is a sum type, so "encode the constructor parameters" has no
single answer. The wire carries which variant it was under `_`, then that
variant's own fields:

```json
{ "_": "WishlistTagFilterNamed", "tag": "mal" }
```

Decoding switches on the tag and fails loudly on one it does not know. The
variants are enumerable because Dart requires them to live in the sealed
class's own library.

## Generation

Stubs, dispatchers and the dispatch table are generated from the DAO signatures
(`dart run tool/generate_rpc.dart` inside `packages/core`), not written by hand
— 266 methods across 23 DAOs, where a hand-rolled serialization slip is a silent
bug. Three separate guards make a stale layer impossible to ship:

- a changed signature stops the stub satisfying `implements <Name>Dao`;
- a new DAO adds a **required** parameter to `buildDaoDispatchTable`, so the
  server stops compiling until it is wired in;
- CI regenerates and asserts an empty diff — the only guard that catches a
  change to a *model* the DAO returns, which no signature check can see.

An unknown type in a signature must fail the generator loudly ("no rule for X")
rather than fall back to `toString()`.
