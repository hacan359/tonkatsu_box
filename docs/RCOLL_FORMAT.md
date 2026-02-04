# .rcoll File Format

The `.rcoll` format is used to share game collections between users.

## Format

JSON file with `.rcoll` extension.

## Structure

```json
{
  "version": 1,
  "name": "My SNES Classics",
  "author": "username",
  "created": "2025-02-02T12:00:00Z",
  "description": "Best RPGs for SNES",
  "games": [
    {
      "igdb_id": 1234,
      "platform_id": 19,
      "comment": "All-time favorite"
    }
  ]
}
```

## Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| version | number | yes | Format version |
| name | string | yes | Collection name |
| author | string | yes | Creator name |
| created | string | yes | ISO 8601 date |
| description | string | no | Collection description |
| games | array | yes | List of games |

### Game Object

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| igdb_id | number | yes | IGDB game ID |
| platform_id | number | yes | IGDB platform ID |
| comment | string | no | Author's comment |

## How It Works

The file only contains IDs, not full game data. When imported:

1. App reads the .rcoll file
2. Fetches game metadata from IGDB using the IDs
3. Displays full collection with covers and details

This keeps files tiny (~500 bytes for 100 games) while ensuring data is always fresh.

## Example

A collection of 50 games is about 2KB. Share via Discord, email, or any file hosting.
