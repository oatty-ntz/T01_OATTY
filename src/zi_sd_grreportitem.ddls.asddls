@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Inbound Delivery Item for GR Report'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType: {
  serviceQuality: #B,
  sizeCategory:   #L,
  dataClass:      #TRANSACTIONAL
}
define view entity ZI_SD_GRREPORTITEM
  as select from I_InboundDeliveryItem
{
      @UI.hidden: true
      @EndUserText.label: 'Inbound Delivery'
  key InboundDelivery,

      @UI.lineItem: [{ position: 10, importance: #HIGH }]
      @EndUserText.label: 'Delivery Item'
  key InboundDeliveryItem,

      @EndUserText.label: 'Purchase Order'
      // VERIFY: ReferenceSDDocument holds PO number on I_InboundDeliveryItem
      ReferenceSDDocument                as PurchaseOrder,

      @UI.lineItem: [{ position: 20, importance: #HIGH }]
      @EndUserText.label: 'PO Item'
      ReferenceSDDocumentItem            as PurchaseOrderItem,

      @UI.lineItem: [{ position: 30, importance: #HIGH }]
      @EndUserText.label: 'Material'
      Material,

      @UI.lineItem: [{ position: 40, importance: #HIGH }]
      @EndUserText.label: 'Description'
      DeliveryDocumentItemText           as MaterialDescription,

      @UI.lineItem: [{ position: 50, importance: #HIGH }]
      @Semantics.quantity.unitOfMeasure: 'DeliveryQuantityUnit'
      @EndUserText.label: 'Delivery Qty'
      ActualDeliveryQuantity,

      @UI.lineItem: [{ position: 60, importance: #MEDIUM }]
      @Semantics.quantity.unitOfMeasure: 'DeliveryQuantityUnit'
      @EndUserText.label: 'Open Qty'
      ActualDeliveryQuantity             as OpenQuantity,

      @UI.lineItem: [{ position: 70, importance: #HIGH }]
      @Semantics.quantity.unitOfMeasure: 'DeliveryQuantityUnit'
      @EndUserText.label: 'GR Qty'
      ActualDeliveryQuantity             as GoodsReceiptQuantity,

      @UI.lineItem: [{ position: 80, importance: #HIGH }]
      @EndUserText.label: 'UoM'
      DeliveryQuantityUnit,

      @UI.lineItem: [{ position: 90, importance: #HIGH }]
      @EndUserText.label: 'Batch'
      Batch,

      @UI.lineItem: [{ position: 100, importance: #MEDIUM }]
      @EndUserText.label: 'Production Date'
      ManufactureDate,

      @UI.lineItem: [{ position: 110, importance: #MEDIUM }]
      @EndUserText.label: 'SLED/BBD'
      ShelfLifeExpirationDate,

      @EndUserText.label: 'Plant'
      Plant,

      @UI.lineItem: [{ position: 120, importance: #HIGH }]
      @EndUserText.label: 'Storage Location'
      StorageLocation,

      @UI.lineItem: [{ position: 130, importance: #HIGH }]
      @EndUserText.label: 'GM Status'
      GoodsMovementStatus,

      @UI.hidden: true
      HigherLvlItmOfBatSpltItm,

      @UI.hidden: true
      MaterialIsBatchManaged
}