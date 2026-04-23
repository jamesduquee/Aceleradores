@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Driver Master - Interface'
@Search.searchable: true

define view entity ZI_Driver_22bm007
  as select from zdriver_22bm007
{
      @Search.defaultSearchElement: true
  key driver_id,
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
      driver_name,
      phone_number,
      vehicle_number,
      availability_status
}
