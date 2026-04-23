@EndUserText.label: 'Taxi Booking Interface'
define root view entity ZI_Booking_22bm007
as select from zbook_22bm007
association [0..1] to ZI_Driver_22bm007 as _Driver
on $projection.driver_id = _Driver.driver_id
{
  key booking_uuid,
      booking_id,
      customer_name,
      pickup_location,
      drop_location,
      booking_date,
      driver_id,
      vehicle_number,
      status,
      fare_amount,
      currency_code,
      last_changed_at,
      local_last_changed_at,

      _Driver
}
