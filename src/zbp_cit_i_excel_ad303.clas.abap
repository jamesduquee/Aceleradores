CLASS zbp_cit_i_excel_ad303 DEFINITION PUBLIC ABSTRACT FINAL FOR BEHAVIOR OF zcit_i_excel_ad303.
PUBLIC SECTION.
    TYPES: BEGIN OF gty_exl_file,
             emp_id    TYPE string,
             dev_id    TYPE string,
             dev_desc  TYPE string,
             obj_type  TYPE string, " Maps to row-obj_type in Local Class
             obj_name  TYPE string, " Maps to row-obj_name in Local Class
             serial_no TYPE string,
           END OF gty_exl_file.
ENDCLASS.

CLASS zbp_cit_i_excel_ad303 IMPLEMENTATION.
ENDCLASS.
