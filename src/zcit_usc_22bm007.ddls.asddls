@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'user projection view'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true

define root view entity ZCIT_USC_22BM007
  as projection on ZCIT_USI_22BM007
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
      TemplateCrticality,
      LocalCreatedBy,
      LocalCreatedAt,
      LocalLastChangedBy,
      LocalLastChangedAt,
      LastChangedAt,
      /* Associations */
      _UserDev : redirected to composition child ZCIT_USC_DEV_22BM007
}
