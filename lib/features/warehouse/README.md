---
📦 WAREHOUSE FEATURE

STATUS: ACTIVE

FEATURE RESPONSIBILITY:
Warehouse operations and inventory management including:
- Warehouse dashboard and inventory overview
- Order preparation and picking workflows
- Stock movement tracking and management
- QR code scanning for inventory operations

CURRENT STATE:
- Multiple implemented dashboard variants (mobile, tablet, simple)
- Working order preparation screen with QR integration
- Mixed implementation: real files + placeholder architecture

WHERE NEW WORK SHOULD HAPPEN:
✅ Extend existing implemented files
✅ Add new warehouse features in screens/ folder
✅ Use viewmodels/ for state management
✅ Use widgets/ for reusable warehouse components

ARCHITECTURE:
- screens/ - Warehouse dashboard, inventory management
- widgets/ - Reusable warehouse UI components
- viewmodels/ - Warehouse state management

Rules:
- UI only (no business logic)
- QR code scanning integration
- Real-time inventory updates
- Order preparation workflows
---
