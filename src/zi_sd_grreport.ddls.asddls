@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Goods Receipt from Inbound Delivery'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZI_SD_GRREPORT
  as select from zsdtgrr
  association [0..1] to ZI_SD_GRREPORT_VH    as _InboundDelivery on $projection.InboundDelivery = _InboundDelivery.InboundDelivery
  association [0..*] to ZI_SD_GRREPORTITEM   as _Items           on $projection.InboundDelivery = _Items.InboundDelivery
  association [0..1] to ZI_SD_GRREPORTRSN_VH as _ReasonVH        on $projection.ReasonCode      = _ReasonVH.ReasonCode
{
  key gr_uuid                  as GrUuid,
      report_no                as ReportNo,
      inbound_delivery         as InboundDelivery,
      document_date            as DocumentDate,
      posting_date             as PostingDate,
      reference_document       as ReferenceDocument,
      reason_code              as ReasonCode,
      material_document        as MaterialDocument,
      material_document_year   as MaterialDocumentYear,
      status                   as Status,
      case status
        when 'P' then 3
        when 'E' then 1
        else 0
      end                      as StatusCriticality,
      message                  as Message,
      @Semantics.user.createdBy: true
      created_by               as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at               as CreatedAt,
      @Semantics.user.localInstanceLastChangedBy: true
      local_last_changed_by    as LocalLastChangedBy,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at    as LocalLastChangedAt,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at          as LastChangedAt,

      /* Associations */
      _InboundDelivery,
      _Items,
      _ReasonVH
}