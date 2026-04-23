@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'user projection view'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define root view entity zcit_c_excel_ad303
  as projection on zcit_i_excel_ad303

{
  key EmpId,
  key DevId,
      DevDescription,
      @Semantics.largeObject : {
      mimeType: 'Mimetype',
      fileName: 'Filename',
      acceptableMimeTypes: [ 'application/vnd.ms-excel','application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'],
      contentDispositionPreference: #ATTACHMENT
      }
      Attachment,
      @Semantics.mimeType: true
      Mimetype,
      Filename,
      FileStatus,
      Criticality,
      TemplateStatus,
      TemplateCriticality,
      LocalCreatedBy,
      LocalCreatedAt,
      LocalLastChangedBy,
      LocalLastChangedAt,
      LastChangedAt,
      /* Associations */
      _UserDev : redirected to composition child ZCIT_C_USER_AD303
}
