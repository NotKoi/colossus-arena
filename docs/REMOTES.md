# Remote contract

All names are in `ReplicatedStorage.Modules.RemoteNames`. All remotes are RemoteEvents created by server Remotes.Start.

Client requests: Swing() (no target or damage), Buy(itemId), Equip(itemId), Teleport(), Sync(). Server validates types, ownership, life, range where appropriate, and per-player rate limits.
Server notifications: Profile(snapshot), Telegraph(data with kind, cycle, start server timestamp), Damage(worldPosition, actualDamage, playerUserId), Results(sortedRows, killed), RareDrop(winnerName, itemId, winnerId), Notice(text), OpenShop().
BossState replicated attributes provide snapshot countdown and HP so late joiners do not miss state events. Clients never set authoritative state.
