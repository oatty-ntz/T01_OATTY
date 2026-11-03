@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Goods Receipt from Inbound Delivery'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
@Search.searchable: true
define root view entity ZC_SD_GRREPORT
  provider contract transactional_query
  as projection on ZI_SD_GRREPORT
{
  key GrUuid,

      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
      ReportNo,

      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
      @Consumption.valueHelpDefinition: [{
        entity: { name: 'ZI_SD_GRREPORT_VH', element: 'InboundDelivery' },
        additionalBinding: [
          { localElement: 'ReferenceDocument', element: 'BillOfLading', usage: #RESULT }
        ]
      }]
      InboundDelivery,

      DocumentDate,
      PostingDate,

      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
      ReferenceDocument,

      @Consumption.valueHelpDefinition: [{
        entity: { name: 'ZI_SD_GRREPORTRSN_VH', element: 'ReasonCode' }
      }]
      @ObjectModel.text.element: ['ReasonText']
      ReasonCode,

      _ReasonVH.Description             as ReasonText,

      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
      MaterialDocument,

      MaterialDocumentYear,
      Status,
      StatusCriticality,
      Message,

      /* Read-only standard fields pulled via association path */
      @ObjectModel.text.element: ['SupplierName']
      _InboundDelivery.Supplier         as Supplier,

      _InboundDelivery.SupplierName     as SupplierName,
      _InboundDelivery.Plant            as Plant,

      _InboundDelivery.PurchaseOrder    as PurchaseOrder,

      _InboundDelivery.PlannedGRDate    as PlannedGRDate,

      CreatedBy,
      CreatedAt,
      LocalLastChangedBy,
      LocalLastChangedAt,
      LastChangedAt,

      /* Associations */
      _InboundDelivery,
      _Items,
      _ReasonVH
}