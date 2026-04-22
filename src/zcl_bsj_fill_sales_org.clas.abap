CLASS zcl_bsj_fill_sales_org DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
ENDCLASS.

CLASS zcl_bsj_fill_sales_org IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    DATA: lt_sales_org TYPE TABLE OF zbsj_sales_org,
          lt_company   TYPE TABLE OF zbsj_company.

    lt_company = VALUE #( is_active = abap_true
                        ( company_code = '1000' company_name = 'Alpine Ventures'    currency = 'EUR' country = 'DE' )
                        ( company_code = '1100' company_name = 'Blue Nile Export'   currency = 'EGP' country = 'EG' )
                        ( company_code = '1200' company_name = 'Cedar Logistics'    currency = 'CAD' country = 'CA' )
                        ( company_code = '1300' company_name = 'Delta Electronics'  currency = 'USD' country = 'US' )
                        ( company_code = '1400' company_name = 'Emerald Estates'    currency = 'GBP' country = 'GB' )
                        ( company_code = '1500' company_name = 'Fuji Tech Corp'     currency = 'JPY' country = 'JP' )
                        ( company_code = '2000' company_name = 'Global Maritime'    currency = 'SGD' country = 'SG' )
                        ( company_code = '2100' company_name = 'Horizon FinTech'    currency = 'AUD' country = 'AU' )
                        ( company_code = '2200' company_name = 'Indus Textiles'     currency = 'INR' country = 'IN' )
                        ( company_code = '2300' company_name = 'Jade Manufacturing' currency = 'CNY' country = 'CN' )
                        ( company_code = '2400' company_name = 'Kangaroo Retail'    currency = 'AUD' country = 'AU' )
                        ( company_code = '3000' company_name = 'Liberty Banking'    currency = 'USD' country = 'US' )
                        ( company_code = '3100' company_name = 'Maple Software'     currency = 'CAD' country = 'CA' )
                        ( company_code = '3200' company_name = 'Nordic Energy'      currency = 'NOK' country = 'NO' )
                        ( company_code = '3300' company_name = 'Oasis Hospitality'  currency = 'AED' country = 'AE' ) ).

    lt_sales_org = VALUE #( ( sales_org = '1000' company_code = '1000' description = 'Domestic HQ'         is_active = abap_true )
                            ( sales_org = '1001' company_code = '1100' description = 'Export Alpha'        is_active = abap_true )
                            ( sales_org = '1002' company_code = '1200' description = 'Intercompany'        is_active = abap_false )
                            ( sales_org = '2000' company_code = '2000' description = 'EMEA Central'        is_active = abap_true )
                            ( sales_org = '2001' company_code = '2100' description = 'Nordic Branch'       is_active = abap_true )
                            ( sales_org = '2002' company_code = '2200' description = 'Southern Hub'        is_active = abap_false )
                            ( sales_org = '3000' company_code = '3000' description = 'APAC Regional'       is_active = abap_true )
                            ( sales_org = '3001' company_code = '3100' description = 'ASEAN Sales'         is_active = abap_true )
                            ( sales_org = '3002' company_code = '3200' description = 'Oceania Retail'      is_active = abap_true )
                            ( sales_org = '1003' company_code = '1000' description = 'West Coast'          is_active = abap_true )
                            ( sales_org = '1004' company_code = '1000' description = 'East Coast'          is_active = abap_true )
                            ( sales_org = '1005' company_code = '1300' description = 'Service Dept'        is_active = abap_true )
                            ( sales_org = '1006' company_code = '1400' description = 'Training Org'        is_active = abap_false )
                            ( sales_org = '1007' company_code = '1500' description = 'Special Projects'    is_active = abap_true )
                            ( sales_org = '1008' company_code = '1000' description = 'Direct Consumer'     is_active = abap_true ) ).

    "Clear old data
    DELETE FROM: zbsj_sales_org,
                 zbsj_company.
    COMMIT WORK.

    INSERT zbsj_company FROM TABLE @lt_company.
    INSERT zbsj_sales_org FROM TABLE @lt_sales_org.

    out->write( 'Sales Organization data inserted successfully!' ).
  ENDMETHOD.
ENDCLASS.
