CLASS lhc_ZBSJ_I_MATERIAL DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    " 1. Replaced zbsj_i_material with the alias 'Material'
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Material RESULT result.

    " 2. Replaced zbsj_i_material with the alias 'Material'
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Material RESULT result.

ENDCLASS.
CLASS lhc_ZBSJ_I_MATERIAL IMPLEMENTATION.

  METHOD get_global_authorizations.
    " %create MUST go here! (Because creating a record is a global action)
    IF requested_authorizations-%create EQ if_abap_behv=>mk-on.
      result-%create = if_abap_behv=>auth-allowed.
    ENDIF.
  ENDMETHOD.

  METHOD get_instance_authorizations.
    " %create CANNOT go here! Only %update and %delete (Because they apply to specific existing instances)
    LOOP AT keys INTO DATA(key).
      APPEND VALUE #(
        %tky    = key-%tky
        %update = if_abap_behv=>auth-allowed
        %delete = if_abap_behv=>auth-allowed
      ) TO result.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
