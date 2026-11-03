CLASS zcl_sd_grreport_action DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    CONSTANTS:
      gc_status_new         TYPE zelm_sd_grreportstat VALUE 'N',
      gc_status_posted      TYPE zelm_sd_grreportstat VALUE 'P',
      gc_status_error       TYPE zelm_sd_grreportstat VALUE 'E',
      gc_reason_default     TYPE zelm_sd_grreportrsn  VALUE '101',
      gc_gm_code_gr         TYPE c LENGTH 2           VALUE '01',
      gc_gm_status_complete TYPE c LENGTH 1           VALUE 'C',
      gc_report_prefix      TYPE c LENGTH 2           VALUE 'GR'.

    TYPES:
      gts_gr_report TYPE STRUCTURE FOR READ RESULT zi_sd_grreport,
      gtt_gr_report TYPE TABLE FOR READ RESULT zi_sd_grreport,

      BEGIN OF gts_delivery_hdr,
        inbound_delivery   TYPE zi_sd_grreport-InboundDelivery,
        bill_of_lading     TYPE zi_sd_grreport-ReferenceDocument,
        overall_gm_status  TYPE c LENGTH 1,
      END OF gts_delivery_hdr,
      gtt_delivery_hdr TYPE STANDARD TABLE OF gts_delivery_hdr WITH EMPTY KEY,

      BEGIN OF gts_post_result,
        gr_uuid                TYPE sysuuid_x16,
        status                 TYPE zelm_sd_grreportstat,
        material_document      TYPE zi_sd_grreport-MaterialDocument,
        material_document_year TYPE zi_sd_grreport-MaterialDocumentYear,
        message                TYPE zi_sd_grreport-Message,
      END OF gts_post_result,
      gtt_post_result TYPE STANDARD TABLE OF gts_post_result WITH EMPTY KEY.

    METHODS constructor
      IMPORTING
        it_entities TYPE gtt_gr_report OPTIONAL.

    METHODS get_next_report_no
      RETURNING
        VALUE(rv_report_no) TYPE zi_sd_grreport-ReportNo.

    METHODS read_delivery_headers
      RETURNING
        VALUE(rt_headers) TYPE gtt_delivery_hdr.

    METHODS post_goods_receipt
      RETURNING
        VALUE(rt_results) TYPE gtt_post_result.

  PRIVATE SECTION.
    DATA gt_entities TYPE gtt_gr_report.
ENDCLASS.



CLASS zcl_sd_grreport_action IMPLEMENTATION.

  METHOD constructor.
    gt_entities = it_entities.
  ENDMETHOD.


  METHOD get_next_report_no.
    DATA lv_max_no TYPE zi_sd_grreport-ReportNo.
    DATA lv_num    TYPE n LENGTH 8.

    SELECT FROM zsdtgrr
      FIELDS MAX( report_no )
      INTO @lv_max_no
      PRIVILEGED ACCESS.

    IF lv_max_no IS INITIAL OR strlen( lv_max_no ) < 3.
      lv_num = 1.
    ELSE.
      lv_num = lv_max_no+2(8) + 1.
    ENDIF.

    rv_report_no = |{ gc_report_prefix }{ lv_num }|.
  ENDMETHOD.


  METHOD read_delivery_headers.
    DATA lt_deliveries TYPE RANGE OF I_InboundDelivery-InboundDelivery.

    LOOP AT gt_entities ASSIGNING FIELD-SYMBOL(<ls_entity>)
      WHERE InboundDelivery IS NOT INITIAL.
      APPEND VALUE #(
        sign   = 'I'
        option = 'EQ'
        low    = <ls_entity>-InboundDelivery
      ) TO lt_deliveries.
    ENDLOOP.

    IF lt_deliveries IS INITIAL.
      RETURN.
    ENDIF.

    SORT lt_deliveries BY low.
    DELETE ADJACENT DUPLICATES FROM lt_deliveries COMPARING low.

    SELECT FROM I_InboundDelivery
      FIELDS InboundDelivery            AS inbound_delivery,
             BillOfLading               AS bill_of_lading,
             OverallGoodsMovementStatus AS overall_gm_status
      WHERE InboundDelivery IN @lt_deliveries
      INTO CORRESPONDING FIELDS OF TABLE @rt_headers
      PRIVILEGED ACCESS.
  ENDMETHOD.


  METHOD post_goods_receipt.
    DATA lt_headers TYPE gtt_delivery_hdr.
    DATA ls_result  TYPE gts_post_result.

    lt_headers = read_delivery_headers( ).

    LOOP AT gt_entities ASSIGNING FIELD-SYMBOL(<ls_entity>).
      CLEAR ls_result.
      ls_result-gr_uuid = <ls_entity>-GrUuid.

      READ TABLE lt_headers INTO DATA(ls_hdr)
        WITH KEY inbound_delivery = <ls_entity>-InboundDelivery.
      IF sy-subrc <> 0.
        ls_result-status  = gc_status_error.
        ls_result-message = |Inbound Delivery { <ls_entity>-InboundDelivery } not found.|.
        APPEND ls_result TO rt_results.
        CONTINUE.
      ENDIF.

      IF ls_hdr-overall_gm_status = gc_gm_status_complete.
        ls_result-status  = gc_status_error.
        ls_result-message = |Inbound Delivery { <ls_entity>-InboundDelivery } is already completely posted.|.
        APPEND ls_result TO rt_results.
        CONTINUE.
      ENDIF.

      " VERIFY: Released Standard BO Action on I_InboundDeliveryTP or I_MaterialDocumentTP
      " Option A: Execute action PostGoodsMovement on I_InboundDeliveryTP
      MODIFY ENTITIES OF I_InboundDeliveryTP
        ENTITY InboundDelivery
        EXECUTE PostGoodsMovement
        FROM VALUE #( (
          %key-InboundDelivery = <ls_entity>-InboundDelivery
        ) )
        FAILED DATA(ls_ibd_failed)
        REPORTED DATA(ls_ibd_reported).

      IF ls_ibd_failed IS NOT INITIAL.
        ls_result-status  = gc_status_error.
        ls_result-message = |Failed to post Goods Receipt for Inbound Delivery { <ls_entity>-InboundDelivery }.|.
        LOOP AT ls_ibd_reported-inbounddelivery ASSIGNING FIELD-SYMBOL(<ls_rep>).
          IF <ls_rep>-%msg IS BOUND.
            ls_result-message = <ls_rep>-%msg->if_message~get_text( ).
            EXIT.
          ENDIF.
        ENDLOOP.
        APPEND ls_result TO rt_results.
        CONTINUE.
      ENDIF.

      " VERIFY: Retrieve posted Material Document from I_MaterialDocumentItem_2
      SELECT SINGLE FROM I_MaterialDocumentItem_2
        FIELDS MaterialDocument,
               MaterialDocumentYear
        WHERE DeliveryDocument = @<ls_entity>-InboundDelivery
        INTO ( @ls_result-material_document, @ls_result-material_document_year )
        PRIVILEGED ACCESS.

      IF ls_result-material_document_year IS INITIAL.
        ls_result-material_document_year = <ls_entity>-PostingDate(4).
      ENDIF.

      ls_result-status  = gc_status_posted.
      ls_result-message = |Goods Receipt posted successfully for { <ls_entity>-InboundDelivery }.|.
      APPEND ls_result TO rt_results.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.