# DAO-RPC protocol

Wire contract between the browser client and the selfhost server. The transport
boundary is a **DAO method**, not a SQL statement: one round trip carries a whole
method, so a transaction runs entirely on the server and no network sits inside
SQLite's writer lock.

`kProtocolVersion` (`lib/src/protocol.dart`) is currently **1**. Client and
server ship in the same image, so a mismatch only means a stale browser tab —
the client is told to reload rather than negotiating.

Status: specification. The dispatcher and the generated stubs are the next
slice of phase 3; nothing below is implemented yet.

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
| `int` id | **string** | see below |
| other `int`, `double`, `bool`, `String` | as-is | must be < 2^53 |
| `DateTime` | ISO-8601 string, UTC | `toUtc().toIso8601String()` |
| `enum` | `.name` string | never the index — reordering must not break stored data |
| model | `toDb()` map | `fromDb()` on the far side |
| `null` | `null` | a missing key and an explicit null mean the same |
| `List` / `Map` | array / object | element rules apply recursively |
| record | object with field names | positional fields as `"$1"`, `"$2"` |

### IDs are strings

`dart2js` compiles `int` to a double: everything above 2^53 loses precision.
Stable ids from `fnv1a64` (`packages/core/lib/utils/stable_id.dart` — Google
Books, MangaDex and friends) are 63-bit and already sit in real databases, so
they cannot be renumbered. Therefore **every id-shaped value is a string on the
wire**, and the browser compares and looks them up as strings. A bare JSON
number is allowed only where the value is provably below 2^53: rowid counters,
sizes, counts, flags, timestamps-as-millis.

The browser must never *compute* an id: `fnv1a64` is BigInt-based and compiles,
but its `toInt()` is lossy in dart2js. Ids come from the server.

## Generation

Stubs and the dispatcher are generated from the DAO signatures
(`dart run tool/generate_rpc.dart`), not written by hand — ~277 methods across
23 DAOs, where a hand-rolled serialization slip is a silent bug. A signature
change that is not regenerated fails the build: the stale stub stops satisfying
`implements <Name>Dao`, and the dispatcher is compiled against the real DAO. CI
regenerates and asserts an empty diff.

An unknown type in a signature must fail the generator loudly ("no rule for X")
rather than fall back to `toString()`.
