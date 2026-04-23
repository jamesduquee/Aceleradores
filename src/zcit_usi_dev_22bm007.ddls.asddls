@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'User Development Details Interface'
@Metadata.ignorePropagatedAnnotations: true

define view entity ZCIT_USI_DEV_22BM007
  as select from zcit_us_dev
  association to parent ZCIT_USI_22BM007 as _User on  $projection.EmpId = _User.EmpId
                                                  and $projection.DevId = _User.DevId
{
  key emp_id      as EmpId,
  key dev_id      as DevId,
  key serial_no   as SerialNo,
      object_type as ObjectType,
      object_name as ObjectName,
      
      _User 
}
