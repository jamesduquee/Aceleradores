CLASS zcl_bsj_insert_order_types DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    " This interface allows the class to be executed directly in Eclipse (ADT)
    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.

CLASS zcl_bsj_insert_order_types IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.
    DATA: lt_order_types TYPE STANDARD TABLE OF zbsj_order_types.

    " 1. Clear existing data to prevent duplicate key errors if you run this multiple times
    DELETE FROM zbsj_order_types.

    " 2. Populate the internal table with your 5 specific order types
    " (The client field is handled automatically by the ABAP framework)
    lt_order_types = VALUE #(
      ( order_type = 'OR' description = 'Standard Sales Order' )
      ( order_type = 'RE' description = 'Return Order' )
      ( order_type = 'CR' description = 'Credit Memo' )
      ( order_type = 'DR' description = 'Debit Memo' )
      ( order_type = 'RO' description = 'Rush Order' )
    ).

    " 3. Insert the data into the database table
    INSERT zbsj_order_types FROM TABLE @lt_order_types.

    " 4. Output a success message to the console
    IF sy-subrc = 0.
      out->write( 'Order types successfully inserted into ZBSJ_ORDER_TYPE!' ).
    ELSE.
      out->write( 'Failed to insert data.' ).
    ENDIF.

  ENDMETHOD.

ENDCLASS.
