# Database Schema & RLS Policies

## Relational Model
The database is structured to support mission-critical integrity and local caching.

### 1. `missions` Table
Stores the root assignment data for field agents.
- `id` (uuid, primary key)
- `dossier_id` (text, unique)
- `agent_id` (uuid, ref: auth.users)
- `status` (enum: pending, ongoing, completed)
- `metadata` (jsonb)

### 2. `evidences` Table
Certified evidence collected during missions.
- `id` (uuid, primary key)
- `mission_id` (uuid, ref: missions.id)
- `media_url` (text)
- `hash_sha256` (text)
- `gps_lat` (float8)
- `gps_lng` (float8)
- `captured_at` (timestamp)

### 3. `field_reports` Table
Human-readable reports linked to certified media.
- `id` (uuid, primary key)
- `mission_id` (uuid, ref: missions.id)
- `content` (text)
- `created_at` (timestamp)

## Security (RLS)
The WITI ecosystem enforces Zero-Trust at the database level:
- **Agents**: Can only `SELECT` missions assigned to their `agent_id`.
- **Agents**: Can only `INSERT` evidence for missions they own.
- **Auditors**: Read-only access to all verified reports.
