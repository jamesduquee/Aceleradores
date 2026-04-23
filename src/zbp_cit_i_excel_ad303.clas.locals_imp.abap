CLASS lhc_User DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR User RESULT result.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR User RESULT result.
    METHODS uploadExcelData FOR MODIFY
      IMPORTING keys FOR ACTION User~uploadExcelData RESULT result.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR User RESULT result.
    METHODS fillselectedstatus FOR DETERMINE ON MODIFY
      IMPORTING keys FOR User~fillselectedstatus.
    METHODS fillfilestatus FOR DETERMINE ON MODIFY
      IMPORTING keys FOR User~fillfilestatus.
    METHODS downloadexcel FOR MODIFY
      IMPORTING keys FOR ACTION User~downloadexcel RESULT result.
ENDCLASS.

CLASS lhc_User IMPLEMENTATION.

  METHOD get_global_authorizations.
    IF requested_authorizations-%create = if_abap_behv=>mk-on.
      result-%create = if_abap_behv=>auth-allowed.
    ENDIF.
  ENDMETHOD.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD uploadExcelData.
    " 1. Read the Root to get the Attachment
    READ ENTITIES OF zcit_i_excel_ad303 IN LOCAL MODE
      ENTITY User ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_user).

    DATA(ls_user) = lt_user[ 1 ].
    CHECK ls_user-Attachment IS NOT INITIAL.

    " 2. Parse Excel
    DATA: lt_excel_temp TYPE STANDARD TABLE OF zbp_cit_i_excel_ad303=>gty_exl_file.
    DATA(lo_read_access) = xco_cp_xlsx=>document->for_file_content( ls_user-Attachment )->read_access( ).
    DATA(lo_worksheet)   = lo_read_access->get_workbook( )->worksheet->at_position( 1 ).

    lo_worksheet->select( xco_cp_xlsx_selection=>pattern_builder->simple_from_to( )->get_pattern( )
      )->row_stream( )->operation->write_to( REF #( lt_excel_temp )
      )->set_value_transformation( xco_cp_xlsx_read_access=>value_transformation->string_value
      )->if_xco_xlsx_ra_operation~execute( ).

    DELETE lt_excel_temp INDEX 1. " Remove Header

    " 3. Create Child Entries via Association
    " %cid = 'ROW_' && idx ensures every entry is unique, preventing dumps
    MODIFY ENTITIES OF zcit_i_excel_ad303 IN LOCAL MODE
      ENTITY User CREATE BY \_UserDev
      FIELDS ( EmpId DevId SerialNo ObjectType ObjectName )
      WITH VALUE #( ( %tky = ls_user-%tky
                      %target = VALUE #( FOR row IN lt_excel_temp INDEX INTO idx (
                                %cid = 'ROW_' && idx
                                EmpId      = ls_user-EmpId
                                DevId      = ls_user-DevId
                                SerialNo   = idx
                                ObjectType = row-obj_type
                                ObjectName = row-obj_name ) ) ) )
      ENTITY User UPDATE FIELDS ( FileStatus )
      WITH VALUE #( ( %tky = ls_user-%tky FileStatus = 'Excel Uploaded' ) ).

    " 4. Result for UI Reflection
    READ ENTITIES OF zcit_i_excel_ad303 IN LOCAL MODE
      ENTITY User ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_updated).

    result = VALUE #( FOR res IN lt_updated ( %tky = res-%tky %param = res ) ).

    reported-user = VALUE #( ( %tky = ls_user-%tky
                               %msg = new_message_with_text(
                                        severity = if_abap_behv_message=>severity-success
                                        text = 'Upload Successful.' ) ) ).
  ENDMETHOD.

  METHOD downloadexcel.
    DATA: lt_template TYPE STANDARD TABLE OF zbp_cit_i_excel_ad303=>gty_exl_file.
    DATA(lo_write_access) = xco_cp_xlsx=>document->empty( )->write_access( ).
    DATA(lo_worksheet)    = lo_write_access->get_workbook( )->worksheet->at_position( 1 ).

    lt_template = VALUE #( ( emp_id = 'User' dev_id = 'Dev' dev_desc = 'Desc'
                             obj_type = 'Type' obj_name = 'Name' ) ).

    DATA(lo_selection) = lo_worksheet->select( xco_cp_xlsx_selection=>pattern_builder->simple_from_to(
      )->from_column( xco_cp_xlsx=>coordinate->for_alphabetic_value( 'A' )
      )->to_column( xco_cp_xlsx=>coordinate->for_alphabetic_value( 'E' ) )->get_pattern( ) ).

    lo_selection->row_stream( )->operation->write_from( REF #( lt_template ) )->execute( ).

    DATA(lv_file) = lo_write_access->get_file_content( ).

    MODIFY ENTITIES OF zcit_i_excel_ad303 IN LOCAL MODE
      ENTITY User UPDATE FIELDS ( Attachment Filename Mimetype TemplateStatus FileStatus )
      WITH VALUE #( FOR key IN keys ( %tky = key-%tky
                                      Attachment = lv_file
                                      Filename = 'template.xlsx'
                                      Mimetype = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
                                      TemplateStatus = 'Present'
                                      FileStatus = 'File not Selected' ) ).

    READ ENTITIES OF zcit_i_excel_ad303 IN LOCAL MODE ENTITY User ALL FIELDS WITH CORRESPONDING #( keys ) RESULT DATA(lt_u).
    result = VALUE #( FOR u IN lt_u ( %tky = u-%tky %param = u ) ).
  ENDMETHOD.

  METHOD FillFileStatus.
    MODIFY ENTITIES OF zcit_i_excel_ad303 IN LOCAL MODE
      ENTITY User UPDATE FIELDS ( FileStatus TemplateStatus )
      WITH VALUE #( FOR key IN keys ( %tky = key-%tky FileStatus = 'File not Selected' TemplateStatus = 'Absent' ) ).
  ENDMETHOD.

  METHOD FillSelectedStatus.
    READ ENTITIES OF zcit_i_excel_ad303 IN LOCAL MODE ENTITY User FIELDS ( Attachment ) WITH CORRESPONDING #( keys ) RESULT DATA(lt_u).
    MODIFY ENTITIES OF zcit_i_excel_ad303 IN LOCAL MODE
      ENTITY User UPDATE FIELDS ( FileStatus )
      WITH VALUE #( FOR u IN lt_u ( %tky = u-%tky
                                    FileStatus = COND #( WHEN u-Attachment IS INITIAL THEN 'File not Selected' ELSE 'File Selected' ) ) ).
  ENDMETHOD.

  METHOD get_instance_features.
    READ ENTITIES OF zcit_i_excel_ad303 IN LOCAL MODE
      ENTITY User FIELDS ( Attachment ) WITH CORRESPONDING #( keys ) RESULT DATA(lt_u).

    result = VALUE #( FOR u IN lt_u ( %tky = u-%tky
             %action-uploadExcelData = COND #( WHEN u-Attachment IS NOT INITIAL THEN if_abap_behv=>fc-o-enabled ELSE if_abap_behv=>fc-o-disabled )
             %action-DownloadExcel   = if_abap_behv=>fc-o-enabled ) ).
  ENDMETHOD.

ENDCLASS.
