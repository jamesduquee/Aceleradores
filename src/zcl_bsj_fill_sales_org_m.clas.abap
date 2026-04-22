CLASS zcl_bsj_fill_sales_org_m DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
ENDCLASS.

CLASS zcl_bsj_fill_sales_org_m IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    DATA: lt_sales_org TYPE TABLE OF zbsj_sales_org_m.

    lt_sales_org = VALUE #(
      ( sales_org = '1000' name = 'India Sales' )
      ( sales_org = '2000' name = 'USA Sales' )
      ( sales_org = '3000' name = 'Europe Sales' )
      ( sales_org = '4000' name = 'Asia Pacific Sales' )
      ( sales_org = '5000' name = 'Middle East Sales' )
      ( sales_org = '6000' name = 'Africa Sales' )
      ( sales_org = '7000' name = 'Australia Sales' )
      ( sales_org = '8000' name = 'South America Sales' )
      ( sales_org = '9000' name = 'Global Sales' )
    ).

    DELETE FROM zbsj_sales_org_m. "Clear old data
    INSERT zbsj_sales_org_m FROM TABLE @lt_sales_org.

    out->write( 'Sales Organization data inserted successfully!' ).
  ENDMETHOD.
ENDCLASS.
