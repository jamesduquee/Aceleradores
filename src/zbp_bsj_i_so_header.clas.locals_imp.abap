CLASS lhc_SalesOrder DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR SalesOrder RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR SalesOrder RESULT result.

    METHODS RecalcTotalPrice FOR MODIFY
      IMPORTING keys FOR ACTION SalesOrder~RecalcTotalPrice.

    METHODS calculateTotalPrice FOR DETERMINE ON MODIFY
      IMPORTING keys FOR SalesOrder~calculateTotalPrice.

    METHODS CreateMaterial FOR MODIFY
      IMPORTING keys FOR ACTION SalesOrder~CreateMaterial RESULT result.
    METHODS createNewCustomer FOR MODIFY
      IMPORTING keys FOR ACTION SalesOrder~createNewCustomer RESULT result.
    METHODS validateSalesOrg FOR VALIDATE ON SAVE
      IMPORTING keys FOR SalesOrder~validateSalesOrg.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR SalesOrder RESULT result.

    METHODS setDelivered FOR MODIFY
      IMPORTING keys FOR ACTION SalesOrder~setDelivered RESULT result.

    METHODS setPaid FOR MODIFY
      IMPORTING keys FOR ACTION SalesOrder~setPaid RESULT result.
    METHODS setInitialStatus FOR DETERMINE ON MODIFY
      IMPORTING keys FOR SalesOrder~setInitialStatus.
    METHODS setBilled FOR MODIFY
      IMPORTING keys FOR ACTION SalesOrder~setBilled RESULT result.
    METHODS setNotBilled FOR MODIFY
      IMPORTING keys FOR ACTION SalesOrder~setNotBilled RESULT result.

    METHODS setNotDelivered FOR MODIFY
      IMPORTING keys FOR ACTION SalesOrder~setNotDelivered RESULT result.

    METHODS setNotPaid FOR MODIFY
      IMPORTING keys FOR ACTION SalesOrder~setNotPaid RESULT result.
    METHODS calculateOverallStatus FOR DETERMINE ON MODIFY
      IMPORTING keys FOR SalesOrder~calculateOverallStatus.
    METHODS validateDates FOR VALIDATE ON SAVE
      IMPORTING keys FOR SalesOrder~validateDates.
    METHODS earlynumbering_cba_Item FOR NUMBERING
      IMPORTING entities FOR CREATE SalesOrder\_Item.

ENDCLASS.

CLASS lhc_SalesOrderItem DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS calculateTotalPrice FOR DETERMINE ON MODIFY
      IMPORTING keys FOR SalesOrderItem~calculateTotalPrice.
    METHODS determineMaterialDefaults FOR DETERMINE ON MODIFY
      IMPORTING keys FOR SalesOrderItem~determineMaterialDefaults.
    METHODS setInitialItemStatus FOR DETERMINE ON MODIFY
      IMPORTING keys FOR SalesOrderItem~setInitialItemStatus.
    METHODS setInitialUom FOR DETERMINE ON MODIFY
      IMPORTING keys FOR SalesOrderItem~setInitialUom.
    METHODS setInitialQuantity FOR DETERMINE ON MODIFY
      IMPORTING keys FOR SalesOrderItem~setInitialQuantity.

ENDCLASS.

CLASS lhc_SalesOrder IMPLEMENTATION.

  METHOD get_global_authorizations.
    IF requested_authorizations-%create = if_abap_behv=>mk-on.
      result-%create = if_abap_behv=>auth-allowed.
    ENDIF.
    IF requested_authorizations-%update = if_abap_behv=>mk-on.
      result-%update = if_abap_behv=>auth-allowed.
    ENDIF.
    IF requested_authorizations-%delete = if_abap_behv=>mk-on.
      result-%delete = if_abap_behv=>auth-allowed.
    ENDIF.
    IF requested_authorizations-%action-Edit = if_abap_behv=>mk-on.
      result-%action-Edit = if_abap_behv=>auth-allowed.
    ENDIF.
  ENDMETHOD.

  METHOD get_instance_authorizations.
    LOOP AT keys INTO DATA(key).
      APPEND VALUE #(
        %tky          = key-%tky
        %update       = if_abap_behv=>auth-allowed
        %delete       = if_abap_behv=>auth-allowed
        %action-Edit  = if_abap_behv=>auth-allowed
      ) TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD RecalcTotalPrice.
    DATA: headers_for_update TYPE TABLE FOR UPDATE zbsj_i_so_header,
          items_for_update   TYPE TABLE FOR UPDATE zbsj_i_so_header\\SalesOrderItem.
    " 1. Read Header Data
    READ ENTITIES OF zbsj_i_so_header IN LOCAL MODE
      ENTITY SalesOrder
        FIELDS ( GrossAmount NetAmount TaxAmount )
        WITH CORRESPONDING #( keys )
      RESULT DATA(headers).

    CHECK headers IS NOT INITIAL.

    " 2. Read Items using the LINK table (Crucial for Draft mode!)
    READ ENTITIES OF zbsj_i_so_header IN LOCAL MODE
      ENTITY SalesOrder BY \_Item
        FIELDS ( Quantity GrossValue NetValue TaxValue  )
        WITH CORRESPONDING #( headers )
      LINK DATA(item_links) " <--- RAP standard mapping table
      RESULT DATA(items).

    " 3. Loop headers and calculate
    LOOP AT headers ASSIGNING FIELD-SYMBOL(<header>).

      " Safely inherit the exact data type of GrossAmount
      DATA(total_gross) = <header>-GrossAmount.
      DATA(total_net)   = <header>-NetAmount.
      DATA(total_tax)   = <header>-TaxAmount.
      CLEAR: total_gross, total_net, total_tax.




      LOOP AT item_links INTO DATA(item_link) USING KEY id WHERE source-%tky = <header>-%tky.
        TRY.
            DATA(item) = items[ KEY id %tky = item_link-target-%tky ].
            " ---> NEW: Handle empty quantities safely (default to 1 if blank to avoid multiplying by 0)
            DATA lv_quantity LIKE item-Quantity.
            lv_quantity = COND #( WHEN item-Quantity > 0 THEN item-Quantity ELSE 1 ).

            " ---> NEW: Multiply the item's Net and Tax by the Quantity
            " ---> NEW: Safely inherit the exact data type (with decimals) first
            DATA(multiplied_net) = item-NetValue.
            DATA(multiplied_tax) = item-TaxValue.

            " ---> NEW: Then perform the multiplication
            multiplied_net = item-NetValue * lv_quantity.
            multiplied_tax = item-TaxValue * lv_quantity.
            " ---> NEW: Calculate Item Gross Value (Net + Tax)
            DATA(calculated_item_gross) = item-GrossValue.
            calculated_item_gross = multiplied_net + multiplied_tax.

            " ---> NEW: Append the newly calculated GrossValue to the item update table
            APPEND VALUE #(
              %tky       = item-%tky
              GrossValue = calculated_item_gross
            ) TO items_for_update.

            " Accumulate all three amounts from the child items for the Header
            total_gross += calculated_item_gross. " Use the new calculated value!
            total_net   += multiplied_net.
            total_tax   += multiplied_tax.

          CATCH cx_sy_itab_line_not_found cx_sy_arithmetic_overflow.
        ENDTRY.
      ENDLOOP.


      " 5. Prepare the update structure
      APPEND VALUE #(
        %tky         = <header>-%tky
        GrossAmount  = total_gross
        NetAmount    = total_net
        TaxAmount    = total_tax
      ) TO headers_for_update.

    ENDLOOP.

    " 6. Update the Database/Draft
    MODIFY ENTITIES OF zbsj_i_so_header IN LOCAL MODE
      ENTITY SalesOrder
        UPDATE FIELDS ( GrossAmount NetAmount TaxAmount )
        WITH headers_for_update

       ENTITY SalesOrderItem          " <--- NEW: Updates the item GrossValue
        UPDATE FIELDS ( GrossValue )
        WITH items_for_update.
  ENDMETHOD.

  METHOD calculateTotalPrice.
    DATA unique_orders TYPE TABLE FOR ACTION IMPORT zbsj_i_so_header~RecalcTotalPrice.

    " DO NOT use READ ENTITIES here! Extract the SalesOrderId directly from the keys:
    LOOP AT keys INTO DATA(ls_item_key).
      APPEND VALUE #(
        SalesOrderId = ls_item_key-SalesOrderId
        %is_draft    = ls_item_key-%is_draft
      ) TO unique_orders.
    ENDLOOP.

    " Remove duplicates
    SORT unique_orders BY SalesOrderId %is_draft.
    DELETE ADJACENT DUPLICATES FROM unique_orders COMPARING SalesOrderId %is_draft.

    " Trigger the internal calculation action on the Header
    IF unique_orders IS NOT INITIAL.
      MODIFY ENTITIES OF zbsj_i_so_header IN LOCAL MODE
        ENTITY SalesOrder
          EXECUTE RecalcTotalPrice
          FROM unique_orders.
    ENDIF.
  ENDMETHOD.

  METHOD CreateMaterial.
    LOOP AT keys INTO DATA(key).

      " 2. Use EML to create an independent Material record
      MODIFY ENTITIES OF zbsj_i_material
        ENTITY Material
        CREATE FIELDS ( MaterialId MaterialName BaseUom UnitPrice Currency TaxCode )
        WITH VALUE #( (
            %cid         = '1'
            %is_draft    = if_abap_behv=>mk-off  " Create as active data
            MaterialId   = key-%param-MaterialId
            MaterialName = key-%param-MaterialName
            BaseUom      = key-%param-BaseUom
            UnitPrice    = key-%param-UnitPrice
            Currency     = key-%param-Currency
            TaxCode      = key-%param-TaxCode
        ) )
        FAILED DATA(failed_mat)
        REPORTED DATA(reported_mat).
    ENDLOOP.

    " 3. Read the current Sales Order to return it back to the UI (required for $self actions)
    READ ENTITIES OF zbsj_i_so_header IN LOCAL MODE
      ENTITY SalesOrder
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(sales_orders).

    result = VALUE #( FOR so IN sales_orders ( %tky = so-%tky %param = so ) ).
  ENDMETHOD.

  METHOD createNewCustomer.
    DATA customers_to_create TYPE TABLE FOR CREATE zbsj_i_customer.

    LOOP AT keys INTO DATA(key).
      APPEND VALUE #(
          %cid         = 'NEW_CUST_' && sy-tabix
          CustomerId   = key-%param-customer_id " Remove if ID is auto-generated
          CustomerName = key-%param-customer_name
          Phone        = key-%param-phone
          Email        = key-%param-email
          Address      = key-%param-address
          City         = key-%param-city
          Country      = key-%param-country
          CreditLimit  = key-%param-credit_limit
          Currency     = key-%param-currency
          IsActive     = key-%param-is_active
      ) TO customers_to_create.
    ENDLOOP.

    " 3. Call the Customer BO to physically create the record on the database
    MODIFY ENTITIES OF zbsj_i_customer
      ENTITY Customer
        CREATE FIELDS ( CustomerId CustomerName Phone Email Address City Country CreditLimit Currency IsActive )
        WITH customers_to_create
      MAPPED DATA(mapped_customer)
      FAILED DATA(failed_customer)
      REPORTED DATA(reported_customer).

    " 4. Read the current Sales Order to return it to the UI (required for result $self)
    READ ENTITIES OF zbsj_i_so_header IN LOCAL MODE
      ENTITY SalesOrder
        ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(sales_orders).


    result = VALUE #( FOR so IN sales_orders (
        %tky   = so-%tky
        %param = so
    ) ).
  ENDMETHOD.

  METHOD validateSalesOrg.
    " 1. Read the SalesOrg values entered by the user
    READ ENTITIES OF zbsj_i_so_header IN LOCAL MODE
      ENTITY SalesOrder
        FIELDS ( SalesOrg )
        WITH CORRESPONDING #( keys )
      RESULT DATA(sales_orders).

    " 2. Loop through the records to validate
    LOOP AT sales_orders INTO DATA(sales_order).

      " 3. Clear the state area so old duplicate messages are removed [6]
      APPEND VALUE #(
          %tky        = sales_order-%tky
          %state_area = 'VALIDATE_SALES_ORG'
      ) TO reported-salesorder.

      " Skip validation if the field is empty
      CHECK sales_order-SalesOrg IS NOT INITIAL.

      " 4. Check if the entered SalesOrg exists in the database table
      SELECT SINGLE @abap_true
        FROM zbsj_sales_org_m
        WHERE sales_org = @sales_order-SalesOrg
        INTO @DATA(exists).

      " 5. If it does not exist, return the failed key and the new message
      IF exists = abap_false.
        " Mark the instance as failed
        APPEND VALUE #( %tky = sales_order-%tky ) TO failed-salesorder.

        " Attach the specific message to the UI [7]
        APPEND VALUE #(
            %tky        = sales_order-%tky
            %state_area = 'VALIDATE_SALES_ORG'
            %msg        = new_message(
                            id       = 'ZBSJ_MSG_CLASS' " Your new Message Class [3]
                            number   = '001'            " Your Message Number [3]
                            severity = if_abap_behv_message=>severity-error
                            v1       = sales_order-SalesOrg " Passes the bad ID into the &1 placeholder [8]
                          )
            %element-SalesOrg = if_abap_behv=>mk-on " Highlights the specific field in red on the UI [9]
        ) TO reported-salesorder.
      ENDIF.

    ENDLOOP.
  ENDMETHOD.

  METHOD get_instance_features.
    " 1. Read the current status of the Sales Orders
    READ ENTITIES OF zbsj_i_so_header IN LOCAL MODE
      ENTITY SalesOrder
      FIELDS ( DeliveryStatus PaymentStatus BillingStatus )
      WITH CORRESPONDING #( keys )
      RESULT DATA(sales_orders).

    " 2. Enable or Disable the buttons based on the status
    result = VALUE #( FOR so IN sales_orders (
                        %tky                 = so-%tky

                        " Disable 'Mark as Delivered' if already Delivered ('D')
                        %action-setDelivered = COND #( WHEN so-DeliveryStatus = 'D'
                                                       THEN if_abap_behv=>fc-o-disabled
                                                       ELSE if_abap_behv=>fc-o-enabled )
                         %action-setNotDelivered = COND #( WHEN so-DeliveryStatus = 'N'
                                                       THEN if_abap_behv=>fc-o-disabled
                                                       ELSE if_abap_behv=>fc-o-enabled )


                        " Disable 'Mark as Paid' if already Paid ('P')
                        %action-setPaid      = COND #( WHEN so-PaymentStatus = 'P'
                                                       THEN if_abap_behv=>fc-o-disabled
                                                       ELSE if_abap_behv=>fc-o-enabled )
                        %action-setNotPaid      = COND #( WHEN so-PaymentStatus = 'N'
                                                       THEN if_abap_behv=>fc-o-disabled
                                                       ELSE if_abap_behv=>fc-o-enabled )

                        " Disable 'Mark as Billed' if already Billed ('B')
                        %action-setBilled    = COND #( WHEN so-BillingStatus = 'B'
                                                       THEN if_abap_behv=>fc-o-disabled
                                                       ELSE if_abap_behv=>fc-o-enabled )
                        %action-setNotBilled    = COND #( WHEN so-BillingStatus = 'N'
                                                       THEN if_abap_behv=>fc-o-disabled
                                                       ELSE if_abap_behv=>fc-o-enabled )
                    ) ).
  ENDMETHOD.

  METHOD setDelivered.
    " 1. Update the Header Status to Delivered ('D')
    MODIFY ENTITIES OF zbsj_i_so_header IN LOCAL MODE
      ENTITY SalesOrder
      UPDATE FIELDS ( DeliveryStatus DeliveryCriticality DeliveryStatusText )
      WITH VALUE #( FOR key IN keys (
                      %tky                = key-%tky
                      DeliveryStatus      = 'D'
                      DeliveryCriticality = 3
                      DeliveryStatusText  = 'Delivered'
                  ) ).

    " ==========================================================
    " 2. NEW: Read all associated Items for the selected Orders
    " ==========================================================
    READ ENTITIES OF zbsj_i_so_header IN LOCAL MODE
      ENTITY SalesOrder BY \_Item     " <--- Ensure this matches your association name
      FIELDS ( ItemStatus )
      WITH CORRESPONDING #( keys )
      RESULT DATA(items).

    " 3. NEW: Update the Item Status to Delivered ('D')
    IF items IS NOT INITIAL.
      MODIFY ENTITIES OF zbsj_i_so_header IN LOCAL MODE
        ENTITY SalesOrderItem
        UPDATE FIELDS ( ItemStatus ItemStatusText  )
        WITH VALUE #( FOR item IN items (
                        %tky       = item-%tky
                        ItemStatus = 'D'
                        ItemStatusText = 'Delivered'
                    ) ).
    ENDIF.
    " ==========================================================

    " 4. Read the updated record to pass back to the UI
    READ ENTITIES OF zbsj_i_so_header IN LOCAL MODE
      ENTITY SalesOrder
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(sales_orders).

    " 5. Return the updated instance
    result = VALUE #( FOR so IN sales_orders ( %tky = so-%tky %param = CORRESPONDING #( so ) ) ).
  ENDMETHOD.


  METHOD setPaid.
    " 1. Change Status, Text, and Color
    MODIFY ENTITIES OF zbsj_i_so_header IN LOCAL MODE
      ENTITY SalesOrder
      UPDATE FIELDS ( PaymentStatus PaymentCriticality PaymentStatusText )
      WITH VALUE #( FOR key IN keys (
                      %tky               = key-%tky
                      PaymentStatus      = 'P'
                      PaymentCriticality = 3
                      PaymentStatusText  = 'Paid'
                  ) ).

    " 2. Read the updated record to pass back to the UI
    READ ENTITIES OF zbsj_i_so_header IN LOCAL MODE
      ENTITY SalesOrder
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(sales_orders).

    " 3. Return the updated instance
    result = VALUE #( FOR so IN sales_orders ( %tky = so-%tky %param = CORRESPONDING #( so ) ) ).
  ENDMETHOD.
  METHOD setBilled.
    " 1. Change Status, Text, and Color for Billing
    MODIFY ENTITIES OF zbsj_i_so_header IN LOCAL MODE
      ENTITY SalesOrder
      UPDATE FIELDS ( BillingStatus BillingCriticality BillingStatusText )
      WITH VALUE #( FOR key IN keys (
                      %tky               = key-%tky
                      BillingStatus      = 'B'
                      BillingCriticality = 3
                      BillingStatusText  = 'Billed'
                  ) ).

    " 2. Read the updated record to pass back to the UI
    READ ENTITIES OF zbsj_i_so_header IN LOCAL MODE
      ENTITY SalesOrder
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(sales_orders).

    " 3. Return the updated instance
    result = VALUE #( FOR so IN sales_orders ( %tky = so-%tky %param = CORRESPONDING #( so ) ) ).
  ENDMETHOD.

  METHOD setInitialStatus.
    " 1. Read the newly created Sales Orders in local mode
    READ ENTITIES OF zbsj_i_so_header IN LOCAL MODE
      ENTITY SalesOrder
      FIELDS ( OverallStatus DeliveryStatus BillingStatus PaymentStatus )
      WITH CORRESPONDING #( keys )
      RESULT DATA(sales_orders).

    " 2. Automatically update statuses, texts, and colors if they are blank
    MODIFY ENTITIES OF zbsj_i_so_header IN LOCAL MODE
      ENTITY SalesOrder
      UPDATE FIELDS ( OverallStatus DeliveryStatus BillingStatus PaymentStatus
                      DeliveryCriticality DeliveryStatusText
                      PaymentCriticality PaymentStatusText
                      BillingCriticality BillingStatusText ) " <--- ONLY BILLING ADDED
      WITH VALUE #( FOR so IN sales_orders (
                      %tky                = so-%tky

                      " Status Codes
                      OverallStatus       = COND #( WHEN so-OverallStatus IS INITIAL THEN 'O' ELSE so-OverallStatus )
                      DeliveryStatus      = COND #( WHEN so-DeliveryStatus IS INITIAL THEN 'N' ELSE so-DeliveryStatus )
                      BillingStatus       = COND #( WHEN so-BillingStatus IS INITIAL THEN 'N' ELSE so-BillingStatus )
                      PaymentStatus       = COND #( WHEN so-PaymentStatus IS INITIAL THEN 'N' ELSE so-PaymentStatus )

                      " Explicitly set Draft Text and Colors
                      DeliveryCriticality = COND #( WHEN so-DeliveryStatus IS INITIAL THEN 1 ELSE so-DeliveryCriticality )
                      DeliveryStatusText  = COND #( WHEN so-DeliveryStatus IS INITIAL THEN 'Not Delivered' ELSE so-DeliveryStatusText )

                      PaymentCriticality  = COND #( WHEN so-PaymentStatus IS INITIAL THEN 1 ELSE so-PaymentCriticality )
                      PaymentStatusText   = COND #( WHEN so-PaymentStatus IS INITIAL THEN 'Unpaid' ELSE so-PaymentStatusText )

                      " --- ADDED BILLING ---
                      BillingCriticality  = COND #( WHEN so-BillingStatus IS INITIAL THEN 1 ELSE so-BillingCriticality )
                      BillingStatusText   = COND #( WHEN so-BillingStatus IS INITIAL THEN 'Not Billed' ELSE so-BillingStatusText )
                  ) ).
  ENDMETHOD.


  METHOD setNotBilled.
    MODIFY ENTITIES OF zbsj_i_so_header IN LOCAL MODE
      ENTITY SalesOrder
      UPDATE FIELDS ( BillingStatus BillingCriticality BillingStatusText )
      WITH VALUE #( FOR key IN keys ( %tky = key-%tky BillingStatus = 'N' BillingCriticality = 1 BillingStatusText = 'Not Billed' ) ).

    READ ENTITIES OF zbsj_i_so_header IN LOCAL MODE ENTITY SalesOrder ALL FIELDS WITH CORRESPONDING #( keys ) RESULT DATA(sales_orders).
    result = VALUE #( FOR so IN sales_orders ( %tky = so-%tky %param = CORRESPONDING #( so ) ) ).
  ENDMETHOD.

  METHOD setNotDelivered.
    " 1. Update the Header Status to Not Delivered ('N')
    MODIFY ENTITIES OF zbsj_i_so_header IN LOCAL MODE
      ENTITY SalesOrder
      UPDATE FIELDS ( DeliveryStatus DeliveryCriticality DeliveryStatusText )
      WITH VALUE #( FOR key IN keys (
                      %tky                = key-%tky
                      DeliveryStatus      = 'N'
                      DeliveryCriticality = 1
                      DeliveryStatusText  = 'Not Delivered'
                  ) ).

    " ==========================================================
    " 2. NEW: Read all associated Items for the selected Orders
    " ==========================================================
    READ ENTITIES OF zbsj_i_so_header IN LOCAL MODE
      ENTITY SalesOrder BY \_Item     " <--- Ensure this matches your association name
      FIELDS ( ItemStatus )
      WITH CORRESPONDING #( keys )
      RESULT DATA(items).

    " 3. NEW: Update the Item Status back to Open ('O')
    IF items IS NOT INITIAL.
      MODIFY ENTITIES OF zbsj_i_so_header IN LOCAL MODE
        ENTITY SalesOrderItem
        UPDATE FIELDS ( ItemStatus ItemStatusText  )
        WITH VALUE #( FOR item IN items (
                        %tky       = item-%tky
                        ItemStatus = 'O'
                         ItemStatusText = 'Open'
                    ) ).
    ENDIF.
    " ==========================================================

    " 4. Read the updated record to pass back to the UI
    READ ENTITIES OF zbsj_i_so_header IN LOCAL MODE
      ENTITY SalesOrder
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(sales_orders).

    result = VALUE #( FOR so IN sales_orders ( %tky = so-%tky %param = CORRESPONDING #( so ) ) ).
  ENDMETHOD.

  METHOD setNotPaid.
    MODIFY ENTITIES OF zbsj_i_so_header IN LOCAL MODE
      ENTITY SalesOrder
      UPDATE FIELDS ( PaymentStatus PaymentCriticality PaymentStatusText )
      WITH VALUE #( FOR key IN keys ( %tky = key-%tky PaymentStatus = 'N' PaymentCriticality = 1 PaymentStatusText = 'Unpaid' ) ).

    READ ENTITIES OF zbsj_i_so_header IN LOCAL MODE ENTITY SalesOrder ALL FIELDS WITH CORRESPONDING #( keys ) RESULT DATA(sales_orders).
    result = VALUE #( FOR so IN sales_orders ( %tky = so-%tky %param = CORRESPONDING #( so ) ) ).
  ENDMETHOD.


  METHOD calculateOverallStatus.
    " 1. Read the current state of the Delivery, Billing, and Payment statuses
    READ ENTITIES OF zbsj_i_so_header IN LOCAL MODE
      ENTITY SalesOrder
      FIELDS ( DeliveryStatus BillingStatus PaymentStatus )
      WITH CORRESPONDING #( keys )
      RESULT DATA(sales_orders).

    " 2. Prepare an internal table to hold our updates
    DATA update_tab TYPE TABLE FOR UPDATE zbsj_i_so_header.

    " ADDED: Explicitly declare the structure type so VALUE #( ) knows what to build
    DATA ls_update LIKE LINE OF update_tab.

    " 3. Evaluate the logic for each order
    LOOP AT sales_orders INTO DATA(so).
      " REMOVED DATA() inline declaration here:
      ls_update = VALUE #( %tky = so-%tky ).

      IF so-DeliveryStatus = 'N' AND so-BillingStatus = 'N' AND so-PaymentStatus = 'N'.
        " Not Delivered + Not Billed + Unpaid -> Open
        ls_update-OverallStatus      = 'O'.
        ls_update-OverallStatusText  = 'Open'.
        ls_update-OverallCriticality = 2.

      ELSEIF so-DeliveryStatus = 'D' AND so-BillingStatus = 'B' AND so-PaymentStatus = 'P'.
        " Delivered + Billed + Paid -> Completed
        ls_update-OverallStatus      = 'C'.
        ls_update-OverallStatusText  = 'Completed'.
        ls_update-OverallCriticality = 3.

      ELSE.
        " Any other mixed combination (e.g., Delivered but Unpaid) -> In Process
        ls_update-OverallStatus      = 'P'.
        ls_update-OverallStatusText  = 'In Process'.
        ls_update-OverallCriticality = 2.
      ENDIF.

      APPEND ls_update TO update_tab.
    ENDLOOP.

    " 4. Apply the changes to the Overall Status fields
    IF update_tab IS NOT INITIAL.
      MODIFY ENTITIES OF zbsj_i_so_header IN LOCAL MODE
        ENTITY SalesOrder
        UPDATE FIELDS ( OverallStatus OverallCriticality OverallStatusText )
        WITH update_tab.
    ENDIF.
  ENDMETHOD.

  METHOD validateDates.
    " 1. Read the necessary date fields from the transactional buffer
    READ ENTITIES OF zbsj_i_so_header IN LOCAL MODE
      ENTITY SalesOrder
        FIELDS ( ReqDeliveryDate OrderDate )
        WITH CORRESPONDING #( keys )
      RESULT DATA(sales_orders).

    " 2. Loop through the records to validate
    LOOP AT sales_orders INTO DATA(order).

      " Clear previous state messages for this validation to avoid duplicates
      APPEND VALUE #( %tky        = order-%tky
                      %state_area = 'VALIDATE_DATES' ) TO reported-salesorder.

      " RULE 1: Delivery Date cannot be in the past
      IF order-ReqDeliveryDate < cl_abap_context_info=>get_system_date( )
         AND order-ReqDeliveryDate IS NOT INITIAL.

        " Mark the instance as failed
        APPEND VALUE #( %tky = order-%tky ) TO failed-salesorder.

        " Report the error to the UI and highlight the Delivery Date field
        APPEND VALUE #( %tky                     = order-%tky
                        %state_area              = 'VALIDATE_DATES'
                        " Note: Replace with your actual Message Class
                        %msg                     = new_message_with_text( severity = if_abap_behv_message=>severity-error text = 'Delivery Date cannot be in the past' )
                        %element-ReqDeliveryDate = if_abap_behv=>mk-on
                      ) TO reported-salesorder.
      ENDIF.

      " RULE 2: Delivery Date must be on or after the Order Date
      IF order-ReqDeliveryDate < order-OrderDate
         AND order-OrderDate IS NOT INITIAL
         AND order-ReqDeliveryDate IS NOT INITIAL.

        APPEND VALUE #( %tky = order-%tky ) TO failed-salesorder.

        " Report the error and highlight BOTH fields on the UI
        APPEND VALUE #( %tky                     = order-%tky
                        %state_area              = 'VALIDATE_DATES'
                        " Note: Replace with your actual Message Class
                        %msg                     = new_message_with_text( severity = if_abap_behv_message=>severity-error text = 'Delivery Date cannot be before Order Date' )
                        %element-OrderDate       = if_abap_behv=>mk-on
                        %element-ReqDeliveryDate = if_abap_behv=>mk-on
                      ) TO reported-salesorder.
      ENDIF.

    ENDLOOP.
  ENDMETHOD.

  METHOD earlynumbering_cba_item.
    " 1. FIX: Declare as Integer 'i' to prevent type conflicts in the REDUCE loops
    DATA max_item_no TYPE i.

    " Read existing items for the incoming Sales Orders
    READ ENTITIES OF ZBSJ_I_SO_HEADER IN LOCAL MODE
      ENTITY SalesOrder BY \_Item
        FROM CORRESPONDING #( entities )
        LINK DATA(existing_items).

    " Loop over all incoming Sales Orders
    LOOP AT entities ASSIGNING FIELD-SYMBOL(<sales_order>) GROUP BY <sales_order>-SalesOrderId.

      " 2. FIX: Added 'COND i' to explicitly cast the return type to Integer
      max_item_no = REDUCE #( INIT max = 0
                              FOR item IN existing_items USING KEY entity
                              WHERE ( source-SalesOrderId = <sales_order>-SalesOrderId )
                              NEXT max = COND i( WHEN item-target-ItemNo > max
                                                 THEN item-target-ItemNo
                                                 ELSE max ) ).

      " 3. FIX: Added 'COND i' to explicitly cast the return type to Integer
      max_item_no = REDUCE #( INIT max = max_item_no
                              FOR entity IN entities USING KEY entity
                              WHERE ( SalesOrderId = <sales_order>-SalesOrderId )
                              FOR target IN entity-%target
                              NEXT max = COND i( WHEN target-ItemNo > max
                                                 THEN target-ItemNo
                                                 ELSE max ) ).

      " Assign new Item Numbers to items that do not have one yet
      LOOP AT <sales_order>-%target ASSIGNING FIELD-SYMBOL(<item_wo_number>).
        " Map the incoming entity to the MAPPED structure
        APPEND CORRESPONDING #( <item_wo_number> ) TO mapped-salesorderitem ASSIGNING FIELD-SYMBOL(<mapped_item>).

        IF <item_wo_number>-ItemNo IS INITIAL.
          max_item_no += 1.
          " ABAP will automatically format the integer back to a padded string (e.g., '0010', '0020')
          <mapped_item>-ItemNo = max_item_no.
        ENDIF.
      ENDLOOP.

    ENDLOOP.
  ENDMETHOD.
ENDCLASS.

CLASS lhc_SalesOrderItem IMPLEMENTATION.

  METHOD calculateTotalPrice.
    " 1. Read parent headers via association
    READ ENTITIES OF zbsj_i_so_header IN LOCAL MODE
      ENTITY SalesOrderItem BY \_Header
        FIELDS ( SalesOrderId )
        WITH CORRESPONDING #( keys )
      RESULT DATA(headers).

    " 2. Trigger action directly on parent headers (EML automatically handles duplicates)
    MODIFY ENTITIES OF zbsj_i_so_header IN LOCAL MODE
      ENTITY SalesOrder
        EXECUTE RecalcTotalPrice
        FROM CORRESPONDING #( headers ).
  ENDMETHOD.

  METHOD determineMaterialDefaults.
    READ ENTITIES OF zbsj_i_so_header IN LOCAL MODE
       ENTITY SalesOrderItem
         FIELDS ( MaterialId )
         WITH CORRESPONDING #( keys )
       RESULT DATA(items).

    DATA: items_for_update TYPE TABLE FOR UPDATE zbsj_i_so_item.

    " 2. Loop through the items to fetch master data
    LOOP AT items INTO DATA(item) WHERE MaterialId IS NOT INITIAL.

      " Read the Unit Price and UoM directly from your Material CDS view
      SELECT SINGLE BaseUom, UnitPrice
        FROM zbsj_i_material
        WHERE MaterialId = @item-MaterialId
        INTO @DATA(material_data).

      IF sy-subrc = 0.
        " 3. Prepare to update the Item's NetValue and UoM
        APPEND VALUE #(
          %tky     = item-%tky
          Uom      = material_data-BaseUom
          NetValue = material_data-UnitPrice
        ) TO items_for_update.
      ENDIF.
    ENDLOOP.

    " 4. Update the item in the draft/database
    IF items_for_update IS NOT INITIAL.
      MODIFY ENTITIES OF zbsj_i_so_header IN LOCAL MODE
        ENTITY SalesOrderItem
          UPDATE FIELDS ( Uom NetValue )
          WITH items_for_update.
    ENDIF.
  ENDMETHOD.

  METHOD setInitialItemStatus.

    READ ENTITIES OF zbsj_i_so_header IN LOCAL MODE
      ENTITY SalesOrderItem
        FIELDS ( ItemStatus )
        WITH CORRESPONDING #( keys )
      RESULT DATA(items).

    " idempotence status field
    DELETE items WHERE ItemStatus IS NOT INITIAL.
    CHECK items IS NOT INITIAL.

    " 3. Set the default status to 'O' (Open)
    MODIFY ENTITIES OF zbsj_i_so_header IN LOCAL MODE
     ENTITY SalesOrderItem
       " ---> Add ItemStatusText to the fields being updated
       UPDATE FIELDS ( ItemStatus ItemStatusText )
       WITH VALUE #( FOR item IN items (
                       %tky           = item-%tky
                       ItemStatus     = 'O'
                       ItemStatusText = 'Open'
                   ) )
   REPORTED DATA(update_reported).
  ENDMETHOD.
  METHOD setInitialUom.
    " 1. Read the newly created items
    READ ENTITIES OF zbsj_i_so_header IN LOCAL MODE
      ENTITY SalesOrderItem
        FIELDS ( Uom )
        WITH CORRESPONDING #( keys )
      RESULT DATA(items).

    " 2. Update the UOM to 'KG' ONLY if it is currently empty
    MODIFY ENTITIES OF zbsj_i_so_header IN LOCAL MODE
      ENTITY SalesOrderItem
        UPDATE FIELDS ( Uom )
        WITH VALUE #( FOR item IN items
                      WHERE ( Uom IS INITIAL ) " Idempotence check
                      ( %tky = item-%tky
                        Uom  = 'KG' ) ).
  ENDMETHOD.

  METHOD setInitialQuantity.
    " 1. Read the newly created items
    READ ENTITIES OF zbsj_i_so_header IN LOCAL MODE
      ENTITY SalesOrderItem
        FIELDS ( Quantity )
        WITH CORRESPONDING #( keys )
      RESULT DATA(items).

    " 2. Update the Quantity to 1 ONLY if it is currently empty (0)
    MODIFY ENTITIES OF zbsj_i_so_header IN LOCAL MODE
      ENTITY SalesOrderItem
        UPDATE FIELDS ( Quantity )
        WITH VALUE #( FOR item IN items
                      WHERE ( Quantity IS INITIAL ) " Idempotence check
                      ( %tky     = item-%tky
                        Quantity = 1 ) ).
  ENDMETHOD.

ENDCLASS.
