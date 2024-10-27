#### release v2

- Implemented IsBagFull() function to check for free slots in bags
- Ensures players can manage loot manually when bags are full
- Added check for item presence using LootSlotHasItem(i)
- Hid LootFrame instead of unregistering all events to prevent conflicts
- Optimized usage of LOOT_DELAY to avoid duplicate looting
- Cleaned up and improved code reliability
