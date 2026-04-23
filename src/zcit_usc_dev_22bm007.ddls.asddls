@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'user development details'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}

define view entity ZCIT_USC_DEV_22BM007
  as projection on ZCIT_USI_DEV_22BM007
{
  key EmpId,
  key DevId,
  key SerialNo,
      ObjectType,
      ObjectName,
      
      /* Associations */
      _User : redirected to parent ZCIT_USC_22BM007
}
