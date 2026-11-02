CLASS lhc_grreport DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR GrReport RESULT result.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR GrReport RESULT result.

    METHODS setDefaultValues FOR DETERMINE ON MODIFY
      IMPORTING keys FOR GrReport~setDefaultValues.

    METHODS setDeliveryDefaults FOR DETERMINE ON MODIFY
      IMPORTING keys FOR GrReport~setDeliveryDefaults.

    METHODS setReportNo FOR DETERMINE ON SAVE
      IMPORTING keys FOR GrReport~setReportNo.

    METHODS validateInboundDelivery FOR VALIDATE ON SAVE
      IMPORTING keys FOR GrReport~validateInboundDelivery.

    METHODS validateDates FOR VALIDATE ON SAVE
      IMPORTING keys FOR GrReport~validateDates.

    METHODS PostGoodsReceipt FOR MODIFY
      IMPORTING keys FOR ACTION GrReport~PostGoodsReceipt RESULT result.

ENDCLASS.


CLASS lhc_grreport IMPLEMENTATION.

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
    IF requested_authorizations-%action-PostGoodsReceipt = if_abap_behv=>mk-on.
      result-%action-PostGoodsReceipt = if_abap_behv=>auth-allowed.
    ENDIF.
    IF requested_authorizations-%action-Edit = if_abap_behv=>mk-on.
      result-%action-Edit = if_abap_behv=>auth-allowed.
    ENDIF.
  ENDMETHOD.


  METHOD get_instance_features.
    READ ENTITIES OF zi_sd_grreport IN LOCAL MODE
      ENTITY GrReport
      FIELDS ( Status )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_entities)
      FAILED failed.

    result = VALUE #(
      FOR ls_entity IN lt_entities
      LET lv_is_posted = xsdbool( ls_entity-Status = zcl_sd_grreport_action=>gc_status_posted )
          lv_is_draft  = xsdbool( ls_entity-%is_draft = if_abap_behv=>mk-on )
      IN (
        %tky                     = ls_entity-%tky
        %update                  = COND #( WHEN lv_is_posted = abap_true
                                           THEN if_abap_behv=>fc-o-disabled
                                           ELSE if_abap_behv=>fc-o-enabled )
        %delete                  = COND #( WHEN lv_is_posted = abap_true
                                           THEN if_abap_behv=>fc-o-disabled
                                           ELSE if_abap_behv=>fc-o-enabled )
        %action-Edit             = COND #( WHEN lv_is_posted = abap_true
                                           THEN if_abap_behv=>fc-o-disabled
                                           ELSE if_abap_behv=>fc-o-enabled )
        %action-PostGoodsReceipt = COND #( WHEN lv_is_posted = abap_true OR lv_is_draft = abap_true
                                           THEN if_abap_behv=>fc-o-disabled
                                           ELSE if_abap_behv=>fc-o-enabled )
        %field-InboundDelivery   = COND #( WHEN lv_is_posted = abap_true
                                           THEN if_abap_behv=>fc-f-read_only
                                           ELSE if_abap_behv=>fc-f-mandatory )
        %field-DocumentDate      = COND #( WHEN lv_is_posted = abap_true
                                           THEN if_abap_behv=>fc-f-read_only
                                           ELSE if_abap_behv=>fc-f-mandatory )
        %field-PostingDate       = COND #( WHEN lv_is_posted = abap_true
                                           THEN if_abap_behv=>fc-f-read_only
                                           ELSE if_abap_behv=>fc-f-mandatory )
        %field-ReferenceDocument = COND #( WHEN lv_is_posted = abap_true
                                           THEN if_abap_behv=>fc-f-read_only
                                           ELSE if_abap_behv=>fc-f-unrestricted )
        %field-ReasonCode        = COND #( WHEN lv_is_posted = abap_true
                                           THEN if_abap_behv=>fc-f-read_only
                                           ELSE if_abap_behv=>fc-f-unrestricted )
      )
    ).
  ENDMETHOD.


  METHOD setDefaultValues.
    READ ENTITIES OF zi_sd_grreport IN LOCAL MODE
      ENTITY GrReport
      FIELDS ( Status DocumentDate PostingDate ReasonCode )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_entities).

    DELETE lt_entities WHERE Status IS NOT INITIAL.
    IF lt_entities IS INITIAL.
      RETURN.
    ENDIF.

    DATA(lv_today) = cl_abap_context_info=>get_system_date( ).

    MODIFY ENTITIES OF zi_sd_grreport IN LOCAL MODE
      ENTITY GrReport
      UPDATE FIELDS ( Status DocumentDate PostingDate ReasonCode )
      WITH VALUE #(
        FOR ls_entity IN lt_entities (
          %tky         = ls_entity-%tky
          Status       = zcl_sd_grreport_action=>gc_status_new
          DocumentDate = COND #( WHEN ls_entity-DocumentDate IS INITIAL THEN lv_today ELSE ls_entity-DocumentDate )
          PostingDate  = COND #( WHEN ls_entity-PostingDate  IS INITIAL THEN lv_today ELSE ls_entity-PostingDate )
          ReasonCode   = COND #( WHEN ls_entity-ReasonCode   IS INITIAL
                                 THEN zcl_sd_grreport_action=>gc_reason_default
                                 ELSE ls_entity-ReasonCode )
        )
      )
      REPORTED DATA(ls_reported).
  ENDMETHOD.


  METHOD setDeliveryDefaults.
    READ ENTITIES OF zi_sd_grreport IN LOCAL MODE
      ENTITY GrReport
      ALL FIELDS
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_entities).

    IF lt_entities IS INITIAL.
      RETURN.
    ENDIF.

    DATA(lo_action) = NEW zcl_sd_grreport_action( it_entities = lt_entities ).
    DATA(lt_headers) = lo_action->read_delivery_headers( ).

    DATA lt_update TYPE TABLE FOR UPDATE zi_sd_grreport.

    LOOP AT lt_entities ASSIGNING FIELD-SYMBOL(<ls_entity>)
      WHERE InboundDelivery IS NOT INITIAL
        AND ReferenceDocument IS INITIAL.
      READ TABLE lt_headers INTO DATA(ls_hdr)
        WITH KEY inbound_delivery = <ls_entity>-InboundDelivery.
      IF sy-subrc = 0 AND ls_hdr-bill_of_lading IS NOT INITIAL.
        APPEND VALUE #(
          %tky              = <ls_entity>-%tky
          ReferenceDocument = ls_hdr-bill_of_lading
        ) TO lt_update.
      ENDIF.
    ENDLOOP.

    IF lt_update IS NOT INITIAL.
      MODIFY ENTITIES OF zi_sd_grreport IN LOCAL MODE
        ENTITY GrReport
        UPDATE FIELDS ( ReferenceDocument )
        WITH lt_update
        REPORTED DATA(ls_reported).
    ENDIF.
  ENDMETHOD.


  METHOD setReportNo.
    READ ENTITIES OF zi_sd_grreport IN LOCAL MODE
      ENTITY GrReport
      FIELDS ( ReportNo )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_entities).

    DELETE lt_entities WHERE ReportNo IS NOT INITIAL.
    IF lt_entities IS INITIAL.
      RETURN.
    ENDIF.

    DATA(lo_action) = NEW zcl_sd_grreport_action( ).
    DATA(lv_next_no) = lo_action->get_next_report_no( ).
    DATA lv_num TYPE numc8.
    lv_num = lv_next_no+2(8).

    DATA lt_update TYPE TABLE FOR UPDATE zi_sd_grreport.

    LOOP AT lt_entities ASSIGNING FIELD-SYMBOL(<ls_entity>).
      APPEND VALUE #(
        %tky     = <ls_entity>-%tky
        ReportNo = |{ zcl_sd_grreport_action=>gc_report_prefix }{ lv_num }|
      ) TO lt_update.
      lv_num += 1.
    ENDLOOP.

    MODIFY ENTITIES OF zi_sd_grreport IN LOCAL MODE
      ENTITY GrReport
      UPDATE FIELDS ( ReportNo )
      WITH lt_update
      REPORTED DATA(ls_reported).
  ENDMETHOD.


  METHOD validateInboundDelivery.
    READ ENTITIES OF zi_sd_grreport IN LOCAL MODE
      ENTITY GrReport
      ALL FIELDS
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_entities).

    DATA(lo_action) = NEW zcl_sd_grreport_action( it_entities = lt_entities ).
    DATA(lt_headers) = lo_action->read_delivery_headers( ).

    LOOP AT lt_entities ASSIGNING FIELD-SYMBOL(<ls_entity>).
      APPEND VALUE #(
        %tky        = <ls_entity>-%tky
        %state_area = 'VALIDATE_IBD'
      ) TO reported-grreport.

      IF <ls_entity>-InboundDelivery IS INITIAL.
        APPEND VALUE #( %tky = <ls_entity>-%tky ) TO failed-grreport.
        APPEND VALUE #(
          %tky                     = <ls_entity>-%tky
          %state_area              = 'VALIDATE_IBD'
          %element-InboundDelivery = if_abap_behv=>mk-on
          %msg                     = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = 'Please select an Inbound Delivery before saving.'
          )
        ) TO reported-grreport.
        CONTINUE.
      ENDIF.

      READ TABLE lt_headers INTO DATA(ls_hdr)
        WITH KEY inbound_delivery = <ls_entity>-InboundDelivery.
      IF sy-subrc <> 0.
        APPEND VALUE #( %tky = <ls_entity>-%tky ) TO failed-grreport.
        APPEND VALUE #(
          %tky                     = <ls_entity>-%tky
          %state_area              = 'VALIDATE_IBD'
          %element-InboundDelivery = if_abap_behv=>mk-on
          %msg                     = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = |Inbound Delivery { <ls_entity>-InboundDelivery } does not exist.|
          )
        ) TO reported-grreport.
      ELSEIF ls_hdr-overall_gm_status = zcl_sd_grreport_action=>gc_gm_status_complete
         AND <ls_entity>-Status <> zcl_sd_grreport_action=>gc_status_posted.
        APPEND VALUE #( %tky = <ls_entity>-%tky ) TO failed-grreport.
        APPEND VALUE #(
          %tky                     = <ls_entity>-%tky
          %state_area              = 'VALIDATE_IBD'
          %element-InboundDelivery = if_abap_behv=>mk-on
          %msg                     = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = |Inbound Delivery { <ls_entity>-InboundDelivery } is already completely posted.|
          )
        ) TO reported-grreport.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD validateDates.
    READ ENTITIES OF zi_sd_grreport IN LOCAL MODE
      ENTITY GrReport
      FIELDS ( DocumentDate PostingDate )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_entities).

    LOOP AT lt_entities ASSIGNING FIELD-SYMBOL(<ls_entity>).
      APPEND VALUE #(
        %tky        = <ls_entity>-%tky
        %state_area = 'VALIDATE_DATES'
      ) TO reported-grreport.

      IF <ls_entity>-DocumentDate IS INITIAL.
        APPEND VALUE #( %tky = <ls_entity>-%tky ) TO failed-grreport.
        APPEND VALUE #(
          %tky                  = <ls_entity>-%tky
          %state_area           = 'VALIDATE_DATES'
          %element-DocumentDate = if_abap_behv=>mk-on
          %msg                  = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = 'Document Date is required.'
          )
        ) TO reported-grreport.
      ENDIF.

      IF <ls_entity>-PostingDate IS INITIAL.
        APPEND VALUE #( %tky = <ls_entity>-%tky ) TO failed-grreport.
        APPEND VALUE #(
          %tky                 = <ls_entity>-%tky
          %state_area          = 'VALIDATE_DATES'
          %element-PostingDate = if_abap_behv=>mk-on
          %msg                 = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = 'Posting Date is required.'
          )
        ) TO reported-grreport.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD PostGoodsReceipt.
    READ ENTITIES OF zi_sd_grreport IN LOCAL MODE
      ENTITY GrReport
      ALL FIELDS
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_entities).

    IF lt_entities IS INITIAL.
      RETURN.
    ENDIF.

    DATA(lo_action) = NEW zcl_sd_grreport_action( it_entities = lt_entities ).
    DATA(lt_post_results) = lo_action->post_goods_receipt( ).

    DATA lt_update TYPE TABLE FOR UPDATE zi_sd_grreport.

    LOOP AT lt_entities ASSIGNING FIELD-SYMBOL(<ls_entity>).
      READ TABLE lt_post_results INTO DATA(ls_post)
        WITH KEY gr_uuid = <ls_entity>-GrUuid.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      APPEND VALUE #(
        %tky                 = <ls_entity>-%tky
        Status               = ls_post-status
        MaterialDocument     = ls_post-material_document
        MaterialDocumentYear = ls_post-material_document_year
        Message              = ls_post-message
      ) TO lt_update.

      APPEND VALUE #(
        %tky = <ls_entity>-%tky
        %msg = new_message_with_text(
          severity = COND #( WHEN ls_post-status = zcl_sd_grreport_action=>gc_status_posted
                             THEN if_abap_behv_message=>severity-success
                             ELSE if_abap_behv_message=>severity-error )
          text     = CONV string( ls_post-message )
        )
      ) TO reported-grreport.
    ENDLOOP.

    IF lt_update IS NOT INITIAL.
      MODIFY ENTITIES OF zi_sd_grreport IN LOCAL MODE
        ENTITY GrReport
        UPDATE FIELDS ( Status MaterialDocument MaterialDocumentYear Message )
        WITH lt_update
        REPORTED DATA(ls_mod_reported).
    ENDIF.

    READ ENTITIES OF zi_sd_grreport IN LOCAL MODE
      ENTITY GrReport
      ALL FIELDS
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_updated_entities).

    result = VALUE #(
      FOR ls_updated IN lt_updated_entities (
        %tky   = ls_updated-%tky
        %param = ls_updated
      )
    ).
  ENDMETHOD.

ENDCLASS.