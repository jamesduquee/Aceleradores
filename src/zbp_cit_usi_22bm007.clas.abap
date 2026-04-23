CLASS zbp_cit_usi_22bm007 DEFINITION
  PUBLIC
  ABSTRACT
  FINAL
  FOR BEHAVIOR OF zcit_usi_22bm007.

  PUBLIC SECTION.
    " This type must match the columns in your Excel template
    TYPES: BEGIN OF gty_exl_file,
             emp_id    TYPE string,
             dev_id    TYPE string,
             dev_desc  TYPE string,
             obj_type  TYPE string,
             obj_name  TYPE string,
             serial_no TYPE string,
           END OF gty_exl_file.

  PROTECTED SECTION. " Critical: Fixes 'Source code incomplete'
  PRIVATE SECTION.   " Critical: Fixes 'Source code incomplete'
ENDCLASS.

CLASS zbp_cit_usi_22bm007 IMPLEMENTATION.
ENDCLASS.
