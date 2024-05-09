*&---------------------------------------------------------------------*
*& Report Z30715_OOALV
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT z30715_ooalv.

TABLES:makt.
*INCLUDE ooalv_top .
TYPES:BEGIN OF ty_data,
        box         TYPE c LENGTH 1,
        field_color TYPE lvc_t_scol.
        INCLUDE TYPE makt .
TYPES: END OF ty_data .

DATA: gt_makt TYPE TABLE OF ty_data,
      gs_makt TYPE ty_data.

* alv display
DATA: gs_alv TYPE REF TO cl_gui_alv_grid .  " alv 对象 用于表单输出
DATA: gs_parent TYPE REF TO cl_gui_custom_container ." cl_gui_container . " 用于定义容器
DATA: gt_fieldcat TYPE lvc_t_fcat . "列结构
*DATA: gs_fieldcat LIKE LINE OF gt_fieldcat . "列结构 - 工作区d
DATA: gs_fieldcat TYPE lvc_s_fcat . "列结构 - 工作区d

DATA: gs_layout TYPE lvc_s_layo . "表单格式

DATA gv_pos TYPE n LENGTH 2.

DATA ok_code TYPE sy-ucomm .

*定义宏
CLEAR:gv_pos.
DEFINE add_fieldcat.
  gv_pos = gv_pos + 1.
gs_fieldcat-col_pos = gv_pos .
gs_fieldcat-fieldname = &1 .
gs_fieldcat-scrtext_m = &2 .
gs_fieldcat-outputlen = &3 .

APPEND gs_fieldcat TO gt_fieldcat .
 CLEAR gs_fieldcat .
END-OF-DEFINITION .

"定义屏幕选择
SELECT-OPTIONS s_matnr FOR makt-matnr .

START-OF-SELECTION .

  PERFORM get_data .

END-OF-SELECTION .

  IF gt_makt IS NOT INITIAL.
    CALL SCREEN 0100.
*    PERFORM frm_display .
*    CALL SCREEN 0100.
  ELSE.
    MESSAGE '没有数据' TYPE 'E' .
  ENDIF.
*&---------------------------------------------------------------------*
*& Form get_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM get_data .

  SELECT * FROM makt INTO CORRESPONDING FIELDS OF TABLE gt_makt ." WHERE matnr = s_matnr .

ENDFORM.
*&---------------------------------------------------------------------*
*& Form frm_display
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM frm_display .

  PERFORM frm_layout .
  PERFORM frm_fieldcat .
  PERFORM display_alv .


ENDFORM.
*&---------------------------------------------------------------------*
*& Form frm_fieldcat
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM frm_fieldcat .
  add_fieldcat:
    'MATNR'   '物料编号'              '10',
    'SPRAS'   '语言代码'              '10',
    'MAKTX'   '物料描述'              '20',
    'MAKTG'   '匹配码的大写物料描述'  '40' .


ENDFORM.
*&---------------------------------------------------------------------*
*& Form display_alv
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM display_alv .
  "实例化
  "gs_parent实例化 - 实例化容器
  CREATE OBJECT gs_parent
    EXPORTING
      container_name = 'GC_CON'.    "界面中的 constructor control控件名称


  CREATE OBJECT gs_alv  " 将ALV 植入到容器中
    EXPORTING
      i_parent = gs_parent. "'X'.      "必输项

  "调用方法输出
  CALL METHOD gs_alv->set_table_for_first_display
*    EXPORTING
*      i_buffer_active               =
*      i_bypassing_buffer            =
*      i_consistency_check           =
*      i_structure_name              =
*      is_variant                    =
*      i_save                        =
*      i_default                     = 'X'
*      is_layout                     = gs_layout
*      is_print                      =
*      it_special_groups             =
*      it_toolbar_excluding          =
*      it_hyperlink                  =
*      it_alv_graphics               =
*      it_except_qinfo               =
*      ir_salv_adapter               =
    CHANGING
      it_outtab                     = gt_makt  "传出数据的表格
      it_fieldcatalog               = gt_fieldcat  "表单列格式
*     it_sort                       =
*     it_filter                     =
    EXCEPTIONS
      invalid_parameter_combination = 1
      program_error                 = 2
      too_many_lines                = 3
      OTHERS                        = 4.
  IF sy-subrc <> 0.
*   Implement suitable error handling here
  ENDIF.

ENDFORM.
**************************** BEFORE OUTPUT 定义 begin ****************************
*&---------------------------------------------------------------------*
*& Module INIT_ALV OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE init_alv OUTPUT.
  IF gs_alv IS INITIAL.
    PERFORM frm_display . "ALV 展示
  ELSE.
    PERFORM refresh_alv .  "刷新
  ENDIF.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module STATUS_0100 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_0100 OUTPUT.    "屏幕按钮
  SET PF-STATUS '0100'.      "创建按钮 (绿 BACK ，黄 EXIT ，红 CANCEL )
  SET TITLEBAR '0100'.       "创建抬头
ENDMODULE.
**************************** BEFORE OUTPUT 定义 end ****************************

****************************  AFTER INPUT 定义 begin ****************************
*&---------------------------------------------------------------------*
*&      Module  EXIT  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE exit INPUT.  "定义按钮功能

  LEAVE PROGRAM .

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0100 INPUT.
  CASE ok_code .     "定义按钮功能
    WHEN 'BACK' .
      LEAVE TO SCREEN 0 .
    WHEN 'EXIT' OR 'CANCEL' .
      LEAVE PROGRAM .
  ENDCASE .

ENDMODULE.
****************************  AFTER INPUT 定义 end ****************************

*&---------------------------------------------------------------------*
*& Form refresh_alv
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM refresh_alv .   "刷新

  DATA gs_stable TYPE lvc_s_stbl .
  gs_stable-col = 'X' .
  gs_stable-row = 'X' .

  CALL METHOD gs_alv->refresh_table_display
    EXPORTING
      is_stable = gs_stable
*     i_soft_refresh =
    EXCEPTIONS
      finished  = 1
      OTHERS    = 2.
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form frm_layout
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM frm_layout .
  gs_layout-col_opt = 'X' .
  gs_layout-zebra = 'X' .
  gs_layout-box_fname = 'X' .    "左侧选择按钮

  gs_layout-ctab_fname = 'FIELD_COLOR' .     "字段颜色

ENDFORM.
