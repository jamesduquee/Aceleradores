CLASS lhc_Booking DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Booking RESULT result.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Booking RESULT result.

    METHODS assignDriver FOR MODIFY
      IMPORTING keys FOR ACTION Booking~assignDriver RESULT result.

    METHODS completeTrip FOR MODIFY
      IMPORTING keys FOR ACTION Booking~completeTrip RESULT result.

    METHODS startTrip FOR MODIFY
      IMPORTING keys FOR ACTION Booking~startTrip RESULT result.
ENDCLASS.

CLASS lhc_Booking IMPLEMENTATION.
  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD get_instance_features.
    " This controls which buttons are visible/enabled on the Fiori App
    result = VALUE #( FOR key IN keys (
        %tky = key-%tky
        %action-assignDriver = if_abap_behv=>fc-o-enabled
        %action-startTrip    = if_abap_behv=>fc-o-enabled
        %action-completeTrip = if_abap_behv=>fc-o-enabled
    ) ).
  ENDMETHOD.

  METHOD assignDriver.
    " Update Status to 'Driver Assigned'
    MODIFY ENTITIES OF ZI_Booking_22bm007 IN LOCAL MODE
      ENTITY Booking
        UPDATE FIELDS ( status )
        WITH VALUE #( FOR key IN keys ( %tky = key-%tky status = 'Driver Assigned' ) )
    REPORTED DATA(lt_reported).

    " Read the updated data back so the UI updates immediately
    READ ENTITIES OF ZI_Booking_22bm007 IN LOCAL MODE
      ENTITY Booking ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_bookings).

    result = VALUE #( FOR booking IN lt_bookings ( %tky = booking-%tky %param = booking ) ).
  ENDMETHOD.

  METHOD startTrip.
    " Update Status to 'Trip Started'
    MODIFY ENTITIES OF ZI_Booking_22bm007 IN LOCAL MODE
      ENTITY Booking
        UPDATE FIELDS ( status )
        WITH VALUE #( FOR key IN keys ( %tky = key-%tky status = 'Trip Started' ) )
    REPORTED DATA(lt_reported).

    READ ENTITIES OF ZI_Booking_22bm007 IN LOCAL MODE
      ENTITY Booking ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_bookings).

    result = VALUE #( FOR booking IN lt_bookings ( %tky = booking-%tky %param = booking ) ).
  ENDMETHOD.

  METHOD completeTrip.
    " Update Status to 'Completed'
    MODIFY ENTITIES OF ZI_Booking_22bm007 IN LOCAL MODE
      ENTITY Booking
        UPDATE FIELDS ( status )
        WITH VALUE #( FOR key IN keys ( %tky = key-%tky status = 'Completed' ) )
    REPORTED DATA(lt_reported).

    READ ENTITIES OF ZI_Booking_22bm007 IN LOCAL MODE
      ENTITY Booking ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_bookings).

    result = VALUE #( FOR booking IN lt_bookings ( %tky = booking-%tky %param = booking ) ).
  ENDMETHOD.
ENDCLASS.
