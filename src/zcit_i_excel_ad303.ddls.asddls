@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'User Details'
@Metadata.ignorePropagatedAnnotations: true
define root view entity zcit_i_excel_ad303
  as select from zcit_excel_ad303
  composition [0..*] of zcit_i_user_ad303 as _UserDev
{
  key emp_id          as EmpId,
  key dev_id          as DevId,
      dev_description as DevDescription,
      attachment      as Attachment,
      mimetype        as Mimetype,
      filename        as Filename,
      file_status     as FileStatus,
      template_status as TemplateStatus,

      // to give color coding to file status
      case file_status
        when 'File Selected'   then 2
        when 'Excel Uploaded'  then 3
        when 'File not Selected' then 1
        else 0
      end             as Criticality,

      case template_status
        when 'Present' then 3
        when 'Absent'  then 1
        else 0
      end             as TemplateCriticality,

      @Semantics.user.createdBy: true
      local_created_by      as LocalCreatedBy,
      @Semantics.systemDateTime.createdAt: true
      local_created_at      as LocalCreatedAt,
      @Semantics.user.lastChangedBy: true
      local_last_changed_by as LocalLastChangedBy,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at       as LastChangedAt,

      _UserDev
}
