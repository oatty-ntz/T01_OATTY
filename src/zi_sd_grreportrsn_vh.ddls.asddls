@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Value Help for GR Reason / Movement'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType: {
  serviceQuality: #A,
  sizeCategory:   #S,
  dataClass:      #CUSTOMIZING
}
@ObjectModel.resultSet.sizeCategory: #XS
define view entity ZI_SD_GRREPORTRSN_VH
  as select from DDCDS_CUSTOMER_DOMAIN_VALUE_T( p_domain_name: 'ZDM_SD_GRREPORTRSN' )
{
      @UI.hidden: true
  key domain_name,
      @UI.hidden: true
  key value_position,
      @UI.hidden: true
      @Semantics.language: true
  key language,
      @ObjectModel.text.element: ['Description']
      @EndUserText.label: 'Movement Reason'
  key value_low as ReasonCode,
      @Semantics.text: true
      @EndUserText.label: 'Description'
      text      as Description
}
where
  language = $session.system_language