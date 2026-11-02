# T01 - Goods Receipt from Inbound Delivery (`ZT01_OATTY01`)

SAP Fiori Elements Application (**List Report + Object Page**, **RAP Managed with Draft**, **OData V4**) on **SAP S/4HANA Public Cloud** (ABAP Cloud Language Version 5).
Designed to allow users to select an **Inbound Delivery** (`I_InboundDelivery`), review its header and delivery items (`ZI_SD_GRREPORTITEM`), save a draft or active Goods Receipt document (`ZSDTGRR`), and trigger Goods Receipt posting via released SAP Standard RAP BO EML (`I_InboundDeliveryTP`).

---

## 1. Purpose & Business Requirement
- **Select Inbound Delivery before Creating Goods Receipt**: Users select an Inbound Delivery via Value Help (`ZI_SD_GRREPORT_VH`), which automatically defaults Reference Document (`BillOfLading`) and displays read-only standard fields (`Supplier`, `Plant`, `PurchaseOrder`, `PlannedGRDate`) via association path in `ZC_SD_GRREPORT` and item lines via `ZI_SD_GRREPORTITEM` (`#LINEITEM_REFERENCE`).
- **Status & Criticality**:
  - `N` = **New** (Criticality `0` - Neutral)
  - `P` = **Posted** (Criticality `3` - Green)
  - `E` = **Error** (Criticality `1` - Red)

---

## 2. Repository Object Inventory (Peony Standard)

| # | Object Type | Object Name | Files in `src/` | Description |
|---|---|---|---|---|
| 1 | `DEVC` | `ZT01_OATTY01` | `package.devc.xml` | Package: T01 Goods Receipt from Inbound Delivery |
| 2 | `DOMA` | `ZDM_SD_GRREPORTRSN` | `zdm_sd_grreportrsn.doma.xml` | Domain: GR Movement Type / Reason (`101`, `103`, `105`) |
| 3 | `DTEL` | `ZELM_SD_GRREPORTRSN` | `zelm_sd_grreportrsn.dtel.xml` | Data Element: GR Report Reason / Movement Type |
| 4 | `DOMA` | `ZDM_SD_GRREPORTSTAT` | `zdm_sd_grreportstat.doma.xml` | Domain: GR Report Status (`N`, `P`, `E`) |
| 5 | `DTEL` | `ZELM_SD_GRREPORTSTAT` | `zelm_sd_grreportstat.dtel.xml` | Data Element: GR Report Status |
| 6 | `TABL` | `ZSDTGRR` | `zsdtgrr.tabl.xml` | Active Persistent Table for GR Report |
| 7 | `TABL` | `ZSDTGRRD` | `zsdtgrrd.tabl.xml` | Draft Table for `ZI_SD_GRREPORT` |
| 8 | `DDLS` | `ZI_SD_GRREPORTRSN_VH` | `zi_sd_grreportrsn_vh.ddls.asddls`, `.xml`, `.baseinfo` | Fixed-Value VH on `DDCDS_CUSTOMER_DOMAIN_VALUE_T` |
| 9 | `DDLS` | `ZI_SD_GRREPORT_VH` | `zi_sd_grreport_vh.ddls.asddls`, `.xml`, `.baseinfo` | Inbound Delivery Value Help on `I_InboundDelivery` |
| 10 | `DDLS` | `ZI_SD_GRREPORTITEM` | `zi_sd_grreportitem.ddls.asddls`, `.xml`, `.baseinfo` | Read-Only Delivery Item View on `I_InboundDeliveryItem` |
| 11 | `DDLS` | `ZI_SD_GRREPORT` | `zi_sd_grreport.ddls.asddls`, `.xml`, `.baseinfo` | Root CDS View Entity on `ZSDTGRR` |
| 12 | `DDLS` | `ZC_SD_GRREPORT` | `zc_sd_grreport.ddls.asddls`, `.xml`, `.baseinfo` | Transactional Projection View (`transactional_query`) |
| 13 | `DDLX` | `ZC_SD_GRREPORT` | `zc_sd_grreport.ddlx.asddlxs`, `.xml` | UI Metadata Extension (List Report + Object Page) |
| 14 | `BDEF` | `ZI_SD_GRREPORT` | `zi_sd_grreport.bdef.asbdef`, `.xml` | Managed Behavior Definition (`strict ( 2 )`, `with draft`) |
| 15 | `BDEF` | `ZC_SD_GRREPORT` | `zc_sd_grreport.bdef.asbdef`, `.xml` | Projection Behavior Definition |
| 16 | `CLAS` | `ZCL_SD_GRREPORT_ACTION` | `zcl_sd_grreport_action.clas.abap`, `.xml` | Business Logic Class (SQL + Standard BO EML + Constants) |
| 17 | `CLAS` | `ZBP_I_SD_GRREPORT` | `zbp_i_sd_grreport.clas.abap`, `.locals_imp.abap`, `.xml` | Behavior Pool for `ZI_SD_GRREPORT` |
| 18 | `SRVD` | `ZSD_SD_GRREPORT_SRV` | `zsd_sd_grreport_srv.srvd.srvdsrv`, `.xml` | OData V4 Service Definition |
| 19 | `SRVB` | `ZSB_SD_GRREPORT_UI` | *(Created manually in ADT)* | OData V4 - UI Service Binding |

---

## 3. Behavior & Architecture Summary
- **Determinations**:
  - `setDefaultValues` (`on modify { create; }`): Defaults `Status = 'N'`, `DocumentDate = today`, `PostingDate = today`, `ReasonCode = '101'`.
  - `setDeliveryDefaults` (`on modify { field InboundDelivery; }`): Reads `BillOfLading` from `I_InboundDelivery` via `ZCL_SD_GRREPORT_ACTION` and populates `ReferenceDocument` if empty.
  - `setReportNo` (`on save { create; }`): Assigns sequential `ReportNo` (`GR00000001`, ...) using `SELECT MAX( report_no )` in `ZCL_SD_GRREPORT_ACTION`.
- **Validations** (`on save` and included in `draft determine action Prepare`):
  - `validateInboundDelivery`: Checks that `InboundDelivery` is provided, exists in `I_InboundDelivery`, and is not already completely posted (`OverallGoodsMovementStatus = 'C'`).
  - `validateDates`: Ensures `DocumentDate` and `PostingDate` are filled.
- **Instance Features (`get_instance_features`)**:
  - Disables `Update`, `Delete`, `Edit`, and `PostGoodsReceipt` when `Status = 'P'` (Posted).
  - Disables `PostGoodsReceipt` while in Draft mode (`%is_draft = if_abap_behv=>mk-on`) so standard BO EML runs strictly on active instances in the interaction phase.
- **Action (`PostGoodsReceipt`)**:
  - Executes on active instances only (interaction phase, never during the Save sequence).
  - Calls `ZCL_SD_GRREPORT_ACTION->post_goods_receipt( )`, which executes EML `PostGoodsMovement` on `I_InboundDeliveryTP` and updates `Status`, `MaterialDocument`, `MaterialDocumentYear`, and `Message`.

---

## 4. Points Marked with `VERIFY`
1. **`ZI_SD_GRREPORT_VH` & `ZI_SD_GRREPORTITEM` (`ReferenceSDDocument` as `PurchaseOrder`)**:
   - In `I_InboundDeliveryItem`, `ReferenceSDDocument` / `ReferenceSDDocumentItem` stores the originating Purchase Order and PO Item (or `PurchaseOrder` / `PurchaseOrderItem` depending on S/4HANA release). Verify in ADT Element Info.
2. **`ZCL_SD_GRREPORT_ACTION->post_goods_receipt` (`I_InboundDeliveryTP` action `PostGoodsMovement`)**:
   - Standard EML `MODIFY ENTITIES OF I_InboundDeliveryTP ENTITY InboundDelivery EXECUTE PostGoodsMovement` posts the Goods Receipt for the Inbound Delivery. If custom partial quantities or movement types without delivery update are required, switch to `MODIFY ENTITIES OF I_MaterialDocumentTP ENTITY MaterialDocument CREATE ... CREATE BY \_MaterialDocumentItem`.
   - Also verify if `I_InboundDeliveryTP` requires invocation via background PF / `cl_abap_parallel` if late-numbering Material Document retrieval (`I_MaterialDocumentItem_2`) happens after commit.

---

## 5. Activation Order in ADT
1. **Domains**: `ZDM_SD_GRREPORTRSN`, `ZDM_SD_GRREPORTSTAT`
2. **Data Elements**: `ZELM_SD_GRREPORTRSN`, `ZELM_SD_GRREPORTSTAT`
3. **Database Table**: `ZSDTGRR`
4. **Value Help & Item CDS Views**: `ZI_SD_GRREPORTRSN_VH`, `ZI_SD_GRREPORT_VH`, `ZI_SD_GRREPORTITEM`
5. **Root Interface CDS View**: `ZI_SD_GRREPORT`
6. **Projection CDS View & Metadata Extension**: `ZC_SD_GRREPORT` (DDLS), `ZC_SD_GRREPORT` (DDLX)
7. **Draft Table**: `ZSDTGRRD`
8. **Business Logic Class**: `ZCL_SD_GRREPORT_ACTION`
9. **Root Behavior Definition & Behavior Pool**: `ZI_SD_GRREPORT` (BDEF) + `ZBP_I_SD_GRREPORT` (CLAS)
10. **Projection Behavior Definition**: `ZC_SD_GRREPORT` (BDEF)
11. **Service Definition**: `ZSD_SD_GRREPORT_SRV`
12. **Service Binding (Manual in ADT)**: Create `ZSB_SD_GRREPORT_UI` (Binding Type: `OData V4 - UI`) -> Activate -> Publish -> Preview `GrReport`.

---

## 6. Git Push / ADT Pull Commands

### Push from Local PowerShell
```powershell
cd E:\Peony\App\T01_OATTY
git init -b main
git config user.name "oatty-ntz"
git config user.email "pwatsharate@netizen.co.th"
git add -A
git commit -m "Initial commit: T01 Goods Receipt from Inbound Delivery (ZT01_OATTY01)"
git remote add origin https://github.com/oatty-ntz/T01_OATTY.git
git push -u origin main
```

### Pull into ADT via abapGit Repositories
1. *(First time only)* **Help â†’ Install New Software** â†’ `https://eclipse.abapgit.org/updatesite/` â†’ Select **abapGit for ADT** â†’ Restart Eclipse.
2. Select your ABAP Cloud Project â†’ **Window â†’ Show View â†’ Other... â†’ abapGit Repositories**.
3. Click **`+` (Link abapGit Repository)**:
   - **URL**: `https://github.com/oatty-ntz/T01_OATTY`
   - **User**: `oatty-ntz`
   - **Password**: `<Your GitHub Personal Access Token>`
   - **Branch**: `refs/heads/main`
   - **Package**: `ZT01_OATTY01`
   - **Folder Logic**: `FULL`
4. Right-click the linked repository â†’ **Pull...** â†’ Select Transport Request â†’ **Finish**.
5. Activate objects in the order listed in Section 5 above, then create Service Binding `ZSB_SD_GRREPORT_UI` (`OData V4 - UI`), **Activate**, **Publish**, and **Preview**.