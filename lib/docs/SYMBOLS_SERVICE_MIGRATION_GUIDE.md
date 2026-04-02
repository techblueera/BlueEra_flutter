# Symbols Service Migration Guide

Complete integration guide for migrating symbols (stories/posts) from `be_chat_service` to the independent `be_symbols_service`.

**GitHub Repo:** https://github.com/techblueera/be_symbols_service

---

## Endpoint URL Changes

All 14 symbol endpoints moved to `be_symbols_service`. Paths are identical — only base URL changes.

| Method | Path | Old Base URL | New Base URL |
|--------|------|-------------|-------------|
| POST | `/symbols/` | `https://chat.blueera.ai/` | `https://symbols.blueera.ai/` |
| GET | `/symbols/user/:userId` | `https://chat.blueera.ai/` | `https://symbols.blueera.ai/` |
| GET | `/symbols/feed` | `https://chat.blueera.ai/` | `https://symbols.blueera.ai/` |
| PUT | `/symbols/:symbolId` | `https://chat.blueera.ai/` | `https://symbols.blueera.ai/` |
| DELETE | `/symbols/:symbolId` | `https://chat.blueera.ai/` | `https://symbols.blueera.ai/` |
| POST | `/symbols/:symbolId/like` | `https://chat.blueera.ai/` | `https://symbols.blueera.ai/` |
| DELETE | `/symbols/:symbolId/like` | `https://chat.blueera.ai/` | `https://symbols.blueera.ai/` |
| GET | `/symbols/:symbolId/likes` | `https://chat.blueera.ai/` | `https://symbols.blueera.ai/` |
| POST | `/symbols/:symbolId/comment` | `https://chat.blueera.ai/` | `https://symbols.blueera.ai/` |
| GET | `/symbols/:symbolId/comments` | `https://chat.blueera.ai/` | `https://symbols.blueera.ai/` |
| PUT | `/symbols/comment/:commentId` | `https://chat.blueera.ai/` | `https://symbols.blueera.ai/` |
| DELETE | `/symbols/comment/:commentId` | `https://chat.blueera.ai/` | `https://symbols.blueera.ai/` |
| POST | `/symbols/:symbolId/view` | `https://chat.blueera.ai/` | `https://symbols.blueera.ai/` |
| GET | `/symbols/:symbolId/views` | `https://chat.blueera.ai/` | `https://symbols.blueera.ai/` |

### What Does NOT Change

| Component | Status |
|-----------|--------|
| Socket.IO connection (`wss://chat.blueera.ai/socket`) | **No change** |
| `refetch_chat_list` socket event | **No change** — relayed via Redis pub/sub |
| Chat list includes symbol data | **No change** — fetched via gRPC |
| All chat/call/block/group endpoints | **No change** |

---

## Flutter App Changes

### `constants.dart`

```dart
// Add new constant
static const String symbolsBaseUrl = 'https://symbols.blueera.ai/';
```

### Symbol API class

Update all symbol REST calls to use the new base URL. Same paths, different host.

---

## Architecture

```
be_symbols_service (new)
  |── REST: 14 symbol endpoints
  |── Own MongoDB: symbols, symbol_likes, symbol_comments, symbol_seens
  |── gRPC server: SymbolDataBridge (GetSymbolsForChatList — called by chat service)
  |── gRPC client → be_chat_service: SymbolChatBridge (notification recipients, connections)
  |── gRPC client → be_user_service: user population
  |── Kafka → notification.service: push notifications
  |── Redis pub/sub → be_chat_service: socket event relay (refetch_chat_list)
  |── S3: media deletion on symbol delete

be_chat_service
  |── gRPC server: SymbolChatBridge (exposes contact/conversation/connection queries)
  |── gRPC client → be_symbols_service: SymbolDataBridge (fetches symbol data for chat list)
  |── Redis subscriber: symbol:socket:emit → resolves participants → emits to sockets
```

---

## What Was Added to `be_chat_service`

### New Files

| File | Purpose |
|------|---------|
| `src/grpc/services/symbolChatBridgeService.js` | 3 RPCs: GetSymbolNotificationRecipients, GetAcceptedConnections, GetContactForNotification |
| `src/grpc/protos/symbolChatBridge.proto` | Proto definition for SymbolChatBridge |
| `src/grpc/protos/symbolDataBridge.proto` | Proto for SymbolDataBridge client |
| `src/utils/symbolSocketBridge.js` | Redis subscriber for `symbol:socket:emit` → resolves participants → emits to sockets |
| `src/grpc/client/symbolDataBridgeClient.js` | gRPC client calling symbols service's GetSymbolsForChatList |

### Modified Files

| File | Change |
|------|--------|
| `src/grpc/services/index.js` | Registered symbolChatBridgeServiceDefinition |
| `index.js` | Added symbolSocketBridge initialization |
| `src/controllers/message.controller.js` | Replaced direct Symbol/SymbolLike/SymbolComment/SymbolSeen queries with gRPC call |
| `src/routes/index.js` | Removed `/symbols` route mount |

### Removed Files

| File | Reason |
|------|--------|
| `src/controllers/symbol.controller.js` | Moved to symbols service |
| `src/routes/symbol.route.js` | Moved to symbols service |
| `src/models/schema/symbol.schema.js` | Moved to symbols service |
| `src/models/schema/symbolLike.schema.js` | Moved to symbols service |
| `src/models/schema/symbolComment.schema.js` | Moved to symbols service |
| `src/models/schema/symbolSeen.schema.js` | Moved to symbols service |
| `src/swaggers/symbol.swagger.js` | Moved to symbols service |
| `src/utils/symbolNotificationHelper.js` | Logic moved to gRPC bridge |
| `src/utils/socketEmitter.js` | Only used by symbols — replaced by Redis pub/sub |

---

## Deployment Order

### Step 1: Add env vars to AWS Secrets Manager
- `MONGO_URI_SYMBOLS_SERVICE` — MongoDB URI for symbols database
- `GRPC_SYMBOLS_SERVICE_ADDRESS` — Symbols service gRPC address (e.g., `symbols.beapp.grpc:50056`)
- `HOST_URL_SYMBOLS_SERVICE` — Public URL for swagger docs

### Step 2: Deploy symbols service
- Create MongoDB database
- Run migration script: `node scripts/migrate-data.js`
- Deploy service

### Step 3: Deploy updated chat service
- SymbolChatBridge gRPC service active
- symbolSocketBridge listening
- message.controller.js using gRPC for symbol data

### Step 4: Update frontend
- Point symbol API calls to new base URL

### Step 5: Verify
1. Create/update/delete symbol → `refetch_chat_list` reaches clients
2. Like/comment/view → push notification arrives
3. Chat list includes symbol data
4. Symbol feed respects visibility rules
5. Private symbols only shown to accepted connections
6. Symbol TTL auto-deletion works
7. S3 media cleanup on symbol deletion

---

## Rollback Plan

Revert frontend base URL to `https://chat.blueera.ai/`. The chat service can re-mount the symbol routes if the symbol files are restored from git history.
