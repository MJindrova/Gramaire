loForm=CREATEOBJECT("form1")
loForm.Show()
READ EVENTS


**************************************************
*-- Form:         form1 (g:\clients\xfrx\test\customer\broadcast.scx)
*-- ParentClass:  form
*-- BaseClass:    form
*-- Time Stamp:   06/21/18 02:31:03 PM
*

DEFINE CLASS _BM_MustBeFill AS CUSTOM
  Name="_BM_MustBeFill"
  DIMENSION aList(1)
  iList=0
  
  PROCEDURE Add()
     LPARAMETERS loObj
     This.iList=This.iList+1
     DIMENSION This.aList(This.iList,5)
     This.aList(This.iList,1)=loObj
  ENDPROC

  PROCEDURE GetMessage()
    LOCAL m.lii, m.lcMessage
    m.lcMessage=""
    FOR m.lii=1 TO This.iList
        m.lcMessage=m.lcMessage+This.aList(m.lii,1).Name+" is empty."+CHR(13)+CHR(10)
    NEXT
    RETURN m.lcMessage
  ENDPROC
  
ENDDEF


DEFINE CLASS _BroadcastMessage AS CUSTOM
  Name="_BroadcastMessage"
  Type=.NULL.

  Result=.NULL.
  
ENDDEF

DEFINE CLASS _mytextbox AS textbox
  name="_mytextbox"

  uBroadcastMessage=.NULL.

  lMustBeFill=.F. 
  
  PROCEDURE uBroadcastMessage_ASSIGN
     LPARAMETERS luValue
     
     LOCAL loBM
     loBM=EVALUATE(luValue) && get BroadcastMessage object
     DO CASE
        CASE ISNULL(loBM.Type) && ignore it
        
        CASE loBM.Type=="MUSTBEFILL" AND EMPTY(This.Value) AND This.lMustBeFill
             IF ISNULL(loBM.Result)
                loBM.Result=CREATEOBJECT("_BM_MustBeFill")
             ENDIF
             loBM.Result.Add(This)
      
     ENDCASE
     
  ENDPROC
ENDDEF

DEFINE CLASS _myform AS form
  Name="_myform"
  
ENDDEF

DEFINE CLASS form1 AS _myform


 DoCreate = .T.
 Caption = "Form1"
 Name = "Form1"


 ADD OBJECT text1 AS _mytextbox WITH ;
  Height = 23, ;
  Left = 36, ;
  Top = 48, ;
  Width = 100, ;
  lMustBeFill =.t.,;
  Name = "Text1"


 ADD OBJECT text2 AS _mytextbox WITH ;
  Height = 23, ;
  Left = 48, ;
  Top = 96, ;
  Width = 100, ;
  lMustBeFill =.t.,;
  Name = "Text2"


 ADD OBJECT text3 AS _mytextbox WITH ;
  Height = 23, ;
  Left = 48, ;
  Top = 144, ;
  Width = 100, ;
  Name = "Text3"


 ADD OBJECT cmdvalid AS commandbutton WITH ;
  Top = 132, ;
  Left = 252, ;
  Height = 27, ;
  Width = 84, ;
  Caption = "Valid data", ;
  Name = "cmdValid"
  
  PROCEDURE cmdvalid.Click
     PRIVATE poBM
     poBM =CREATEOBJECT("_BroadcastMessage")
     poBM.Type="MUSTBEFILL"

     Thisform.SetAll("uBroadcastMessage","poBM") && send variable name, it's safety then object reference
     IF NOT ISNULL(poBM.Result)
        MESSAGEBOX(poBM.Result.GetMessage()) 
     ENDIF
     
     RELEASE poBM
     CLEAR EVENTS
  ENDPROC


ENDDEFINE
*
*-- EndDefine: form1
**************************************************
