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
define view entity zcit_c_user_ad303
  as projection on zcit_i_user_ad303

{
  key EmpId,
  key DevId,
  key SerialNo,
      ObjectType,
      ObjectName,
      /* Associations */
      _User : redirected to parent zcit_c_excel_ad303
}
