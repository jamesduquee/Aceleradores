CLASS zcl_fill_drivers DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
ENDCLASS.

CLASS zcl_fill_drivers IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    DATA lt_drivers TYPE TABLE OF zdriver_22bm007.

    lt_drivers = VALUE #(
      ( client = sy-mandt driver_id = 'D101' driver_name = 'Senthil' vehicle_number = 'TN 01 AB 1234' phone_number = '9876543210' availability_status = 'Y' )
      ( client = sy-mandt driver_id = 'D102' driver_name = 'Kumar'   vehicle_number = 'TN 02 CD 5678' phone_number = '9876543211' availability_status = 'Y' )
      ( client = sy-mandt driver_id = 'D103' driver_name = 'Mani'    vehicle_number = 'TN 09 XY 4321' phone_number = '9876543212' availability_status = 'Y' )
      ( client = sy-mandt driver_id = 'D104' driver_name = 'Rajesh'  vehicle_number = 'TN 07 BQ 9988' phone_number = '9876543213' availability_status = 'Y' )
      ( client = sy-mandt driver_id = 'D105' driver_name = 'Anand'   vehicle_number = 'TN 10 AZ 1122' phone_number = '9876543214' availability_status = 'Y' )
    ).

    DELETE FROM zdriver_22bm007. " Clears any old data first
    INSERT zdriver_22bm007 FROM TABLE @lt_drivers. " Inserts the new 5 drivers

    out->write( '5 Drivers created successfully! ZCIT, now check your popup.' ).
  ENDMETHOD.
ENDCLASS.
