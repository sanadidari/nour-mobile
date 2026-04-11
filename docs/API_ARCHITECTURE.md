# API & System Architecture - Nour Mobile

## Overview
Nour Mobile is a judicial field intervention application designed for the Moroccan bailiff corps. It implements the WITI ecosystem's core principles: sovereignty, offline-first reliability, and cryptographic proof-of-presence.

## Core Infrastructure
The application leverages **Supabase** as its primary backend-as-a-service (BaaS), ensuring high availability and secure data synchronization.

### 1. Authentication Service
- **Provider**: Supabase Auth (Email/Password).
- **Security**: JWT-based session management.
- **Role-Based Access**: Integrated with PostgreSQL Row Level Security (RLS).

### 2. Evidence Service (WASSIT Protocol)
The heartbeat of the application, responsible for capturing and certifying field evidence.
- **Media Capture**: High-resolution photo capture with integrated metadata.
- **Cryptographic Hashing**: SHA-256 local hashing of media before upload.
- **GPS Metadata**: Hard-linking GPS coordinates (Latitude, Longitude) and network timestamps to each evidence piece.
- **Storage**: Supabase Storage buckets with strict RLS policies.

### 3. Sync Service
Handles the transition between field (offline) and office (online) states.
- **Offline Persistence**: Local SQLite cache for pending interventions.
- **Retry Mechanism**: Exponential backoff for failed uploads.
- **Batch Processing**: Parallel uploads of media files to optimize network usage.

## Technical Stack
- **Framework**: Flutter (3.x)
- **State Management**: Riverpod (3.0 Beta)
- **Architecture**: Clean Architecture (Feature-first)
- **Persistence**: Shared Preferences & Supabase Local Storage.
