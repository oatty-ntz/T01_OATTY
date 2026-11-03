@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Inbound Delivery Value Help'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType: {
  serviceQuality: #B,
  sizeCategory:   #L,
  dataClass:      #TRANSACTIONAL
}
@Search.searchable: true
define view entity ZI_SD_GRREPORT_VH
  as select from I_InboundDelivery
  left outer to one join I_InboundDeliveryItem as _FirstItem
    on  I_InboundDelivery.InboundDelivery = _FirstItem.InboundDelivery
    and _FirstItem.InboundDeliveryItem    = '000010'
{
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
      @EndUserText.label: 'Inbound Delivery'
  key I_InboundDelivery.InboundDelivery                as InboundDelivery,

      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
      @EndUserText.label: 'Purchase Order'
      // VERIFY: ReferenceSDDocument holds PO number on I_InboundDeliveryItem
      _FirstItem.ReferenceSDDocument                   as PurchaseOrder,

      @EndUserText.label: 'Supplier'
      I_InboundDelivery.Supplier                       as Supplier,

      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
      @EndUserText.label: 'Supplier Name'
      I_InboundDelivery._Supplier.SupplierName         as SupplierName,

      @EndUserText.label: 'Plant'
      I_InboundDelivery.ReceivingPlant                 as Plant,

      @EndUserText.label: 'Planned GR Date'
      I_InboundDelivery.DeliveryDate                   as PlannedGRDate,

      @EndUserText.label: 'Reference Document'
      I_InboundDelivery.BillOfLading                   as BillOfLading,

      @EndUserText.label: 'GM Status'
      I_InboundDelivery.OverallGoodsMovementStatus     as OverallGoodsMovementStatus
}