# PHASE 1: Opening Balance - Implementation Guide

## Files to Download and Place

### 1. Data Models
**File:** `opening_balance_model.dart`
**Location:** `lib/data/models/opening_balance_model.dart`
**What it does:** Defines the OpeningBalance data structure

### 2. Database (REPLACE EXISTING)
**File:** `local_database_v2.dart`
**Location:** `lib/data/datasources/local_database.dart` (REPLACE)
**What it does:** 
- Upgrades database from version 1 to 2
- Adds `opening_balances` table
- Handles migration automatically

### 3. Repository Interface
**File:** `opening_balance_repository.dart`
**Location:** `lib/domain/repositories/opening_balance_repository.dart`
**What it does:** Defines contract for opening balance operations

### 4. Repository Implementation
**File:** `opening_balance_repository_impl.dart`
**Location:** `lib/data/repositories/opening_balance_repository_impl.dart`
**What it does:** 
- Implements database operations
- Calculates closing balance
- Handles CRUD for opening balances

### 5. Riverpod Provider
**File:** `opening_balance_provider.dart`
**Location:** `lib/presentation/providers/opening_balance_provider.dart`
**What it does:** State management for opening balances

### 6. Dashboard (REPLACE EXISTING)
**File:** `dashboard_screen.dart`
**Location:** `lib/presentation/screens/dashboard/dashboard_screen.dart` (REPLACE)
**What it does:**
- Shows opening balance card
- Shows closing balance card
- "Set Opening Balance" button
- Dialog to input amount

---

## Additional Setup Required

### Update `lib/presentation/providers/providers.dart`

Add this provider:

```dart
import '../data/repositories/opening_balance_repository_impl.dart';

final openingBalanceRepositoryImplProvider = Provider<OpeningBalanceRepositoryImpl>((ref) {
  return OpeningBalanceRepositoryImpl(ref.watch(localDatabaseProvider));
});
```

---

## What Phase 1 Adds

### Dashboard Changes:
```
┌─────────────────────────────────┐
│ [February 2026]         [v]     │
├─────────────────────────────────┤
│ Opening Balance:    ৳50,000     │ ← NEW
│ [Set]                           │
├─────────────────────────────────┤
│ Net Cash Flow:      ৳35,000     │
├─────────────────────────────────┤
│ Income / Expense cards...       │
├─────────────────────────────────┤
│ Borrow/Lend summary...          │
├─────────────────────────────────┤
│ Current Balance:    ৳85,000     │ ← NEW
│ (Money you have now)            │
└─────────────────────────────────┘
```

### Features:
1. ✅ Set opening balance per month
2. ✅ Automatic calculation of closing balance
3. ✅ Formula: Opening + Income - Expense + Borrowed - Lent = Closing
4. ✅ Database migration (v1 → v2)
5. ✅ "Current Balance" shows real cash on hand

---

## Testing Steps

1. **Start app** → Database auto-migrates to v2
2. **Go to Dashboard**
3. **Click "Set" button** next to Opening Balance
4. **Enter amount** (e.g., 50000)
5. **Save**
6. **Opening Balance** should show ৳50,000
7. **Closing Balance** should calculate automatically
8. **Add some expenses/income**
9. **Closing Balance updates** in real-time

---

## Database Migration

**Automatic!** When you run the app:
- Detects current version = 1
- Runs upgrade to version 2
- Adds `opening_balances` table
- Keeps all existing data

No manual steps needed!

---

## Next: Phase 2

After Phase 1 is working, we'll add:
- Mark as Settled button
- Group by Person view
- Add to Existing Debt (optional)

---

Reply: "Phase 1 files downloaded" when ready to test!
