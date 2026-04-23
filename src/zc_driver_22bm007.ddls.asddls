@EndUserText.label: 'Driver Master - Consumption'
@AccessControl.authorizationCheck: #NOT_REQUIRED

define view entity ZC_DRIVER_22BM007
  as select from ZI_Driver_22bm007
{
    key driver_id,
    driver_name,
    vehicle_number,
    phone_number,
    availability_status
}
