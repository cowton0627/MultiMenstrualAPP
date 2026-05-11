# Privacy

MultiMenstrualAPP is designed as an offline, on-device menstrual-cycle tracker.

## Data Stored

The app stores the following data in the device's local Core Data store:

- Profile names
- Profile colors
- Period start and end dates
- Period notes

## Network Use

The app does not upload menstrual-cycle data to a server and does not include
third-party analytics, advertising SDKs, or cloud sync in the current codebase.

## Backup Export

The JSON export feature creates a user-selected backup file containing profile
names, period dates, and notes. Treat exported backup files as sensitive private
data and store them only in trusted locations.

## Import

The JSON import feature reads a user-selected local JSON file and merges records
by UUID into the app's local data store.
