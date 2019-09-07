m.loForm=CREATEOBJECT("form1")
m.loForm.Show()
READ EVENTS


***************************************************************************
* SetAll + Assign 
* Hack for VFP 3.0/5.0
* or for control class or other container class with protected or hidden objects
***************************************************************************
PROCEDURE SetAll_Assing
   LPARAMETERS m.lcProperty, m.luValue, m.lcClass, m.loObjX
   LOCAL m.lii, m.loObjC
   
   m.loObjX=IIF(ISNULL(m.loObjX) OR TYPE("m.loObjX")<>"O", _Screen, m.loObjX)
   m.lcClass=IIF(EMPTY(m.lcClass), "", UPPER(ALLTRIM(m.lcClass)))
   
   #IF VAL(SUBS(VERSION(),LEN("Visual FoxPro ")+1,2))=5
    IF PEMSTATUS(m.loObjX, m.lcProperty, 5) AND (LEN(m.lcClass)=0 OR UPPER(m.loObjX.Class)==m.lcClass)
       =EVALUATE("m.loObjX."+m.lcProperty+"_ASSIGN(@m.luValue)")
    ENDIF

    FOR m.lii=1 TO m.loObjX.ControlCount
        m.loObjC=m.loObjX.Controls(m.lii)
        IF PEMSTATUS(m.loObjC, "Controls", 5)
           IF PEMSTATUS(m.loObjC, "SetAll_Assing", 5)
              =m.loObjC.SetAll_Assing(@m.lcProperty, @m.luValue, @m.lcClass)
           ELSE
              =SetAll_Assing(@m.lcProperty, @m.luValue, @m.lcClass, @m.loObjC)
           ENDIF
        ELSE
           IF PEMSTATUS(m.loObjC, m.lcProperty, 5) AND (LEN(m.lcClass)=0 OR UPPER(m.loObjC.Class)==m.lcClass)
              =EVALUATE("m.loObjC."+m.lcProperty+"_ASSIGN(@m.luValue)")
           ENDIF
        ENDIF
    NEXT
   #ELSE
    IF PEMSTATUS(m.loObjX, m.lcProperty, 5) AND (LEN(m.lcClass)=0 OR UPPER(m.loObjX.Class)==m.lcClass)
       STORE m.luValue TO ("m.loObjX."+m.lcProperty)
    ENDIF
    =IIF(EMPTY(m.lcClass), m.loObjX.SetAll(m.lcProperty, m.luValue), m.loObjX.SetAll(m.lcProperty, m.luValue, m.lcClass))
   #ENDIF
ENDPROC


***************************************************************************
* Base broadcast message class
***************************************************************************
DEFINE CLASS _BroadcastMessage AS CUSTOM
   Name="_BroadcastMessage"
   uType=.NULL.    && Broadcast message type   - can be string, date, datetime, boolean, number or object
   uResult=.NULL.  && Broadcast message result - can be string, date, datetime, boolean, number or object
ENDDEFINE


***************************************************************************
* Base broadcast message result class
***************************************************************************
DEFINE CLASS _BroadcastMessageResult AS CUSTOM
   Name="_BroadcastMessageResult"
   DIMENSION aList(1) && Objects List
   iList=0            && Objects Counter
   uFlag=.T.          && Base result flag - can be string, date, datetime, boolean, number or object

   * Add object (reference) to list
   PROCEDURE Add
      * 
      * _BroadcastMessageResult::Add()
      * 
      LPARAMETERS m.loObj
      This.iList=This.iList+1
      DIMENSION This.aList(This.iList, 1)
      This.aList(This.iList, 1)=m.loObj
   ENDPROC

   * Clear list
   PROCEDURE Clear
      * 
      * _BroadcastMessageResult::Clear()
      * 
      This.iList=0
      DIMENSION This.aList(1, 1)
      This.aList(1, 1)=.NULL.
   ENDPROC

   * Create message (string)
   PROCEDURE GetMessage
      * 
      * _BroadcastMessageResult::GetMessage()
      * 
   ENDPROC
ENDDEF



***************************************************************************
* Some broadcast message class
***************************************************************************
DEFINE CLASS _BM_Style AS _BroadcastMessage
   Name="_BM_Style"
   uType="STYLE"
   
   FontName="Tahoma"
   FontSize=10
   FontBold=.F.
   FontItalic=.F.
   FontStrikethru=.F.
   FontUnderline=.F.

  PROCEDURE SetStyle
     * 
     * _BM_Style::SetStyle()
     * 
     LPARAMETERS m.loObj
     IF PEMSTATUS(m.loObj, "FontName", 5)
        m.loObj.FontName=This.FontName
     ENDIF
     IF PEMSTATUS(m.loObj, "FontSize", 5)
        m.loObj.FontSize=This.FontSize
     ENDIF
     IF PEMSTATUS(m.loObj, "FontBold", 5)
        m.loObj.FontBold=This.FontBold
     ENDIF
     IF PEMSTATUS(m.loObj, "FontItalic", 5)
        m.loObj.FontItalic=This.FontItalic
     ENDIF
     IF PEMSTATUS(m.loObj, "FontStrikethru", 5)
        m.loObj.FontStrikethru=This.FontStrikethru
     ENDIF
     IF PEMSTATUS(m.loObj, "FontUnderline", 5)
        m.loObj.FontUnderline=This.FontUnderline
     ENDIF
  ENDPROC
  
ENDDEF


***************************************************************************
* Some textbox class
***************************************************************************
DEFINE CLASS _mytextbox AS textbox
   Name="_mytextbox"

   * Property for seting broadcast message. This property will not be set never!!!
   uBroadcastMessage=.NULL. 
   
   PROCEDURE uBroadcastMessage_ASSIGN && See to help on "Access and Assign Methods"
      * 
      * _mytextbox::uBroadcastMessage_ASSIGN()
      * 
      LPARAMETERS m.luValue
      
      IF EMPTY(m.luValue) OR ISNULL(m.luValue) OR TYPE(m.luValue)<>"O"
         RETURN
      ENDIF
      
      LOCAL m.loBM
      m.loBM=EVALUATE(m.luValue) && Get broadcast message (object)
      DO CASE
         * Unknown broadcast message type - ignore it
         CASE ISNULL(m.loBM) OR NOT PEMSTATUS(m.loBM, "uType", 5) OR ISNULL(m.loBM.uType)
         
         * 'STYLE' broadcast message type
         CASE m.loBM.uType=="STYLE" 
              m.loBM.SetStyle(This)
       
      ENDCASE
   ENDPROC

ENDDEF


***************************************************************************
* Some label class
***************************************************************************
DEFINE CLASS _mylabel AS label
   Name="_mylabel"

   * Property for seting broadcast message. This property will not be set never!!!
   uBroadcastMessage=.NULL. 
   
   
   PROCEDURE uBroadcastMessage_ASSIGN && See to help on "Access and Assign Methods"
      * 
      * _mylabel::uBroadcastMessage_ASSIGN()
      * 
      LPARAMETERS m.luValue
      
      IF EMPTY(m.luValue) OR ISNULL(m.luValue) OR TYPE(m.luValue)<>"O"
         RETURN
      ENDIF
      
      LOCAL m.loBM
      m.loBM=EVALUATE(m.luValue) && Get broadcast message (object)
      DO CASE
         * Unknown broadcast message type - ignore it
         CASE ISNULL(m.loBM) OR NOT PEMSTATUS(m.loBM, "uType", 5) OR ISNULL(m.loBM.uType)
         
         * 'STYLE' broadcast message type
         CASE m.loBM.uType=="STYLE" 
              m.loBM.SetStyle(This)
       
      ENDCASE
   ENDPROC

ENDDEF

***************************************************************************
* Some command button class
***************************************************************************
DEFINE CLASS _mycommandbutton AS commandbutton
   Name="_mycommandbutton"

   * Property for seting broadcast message. This property will not be set never!!!
   uBroadcastMessage=.NULL. 
   
   
   PROCEDURE uBroadcastMessage_ASSIGN && See to help on "Access and Assign Methods"
      * 
      * _commandbutton::uBroadcastMessage_ASSIGN()
      * 
      LPARAMETERS m.luValue
      
      IF EMPTY(m.luValue) OR ISNULL(m.luValue) OR TYPE(m.luValue)<>"O"
         RETURN
      ENDIF
      
      LOCAL m.loBM
      m.loBM=EVALUATE(m.luValue) && Get broadcast message (object)
      DO CASE
         * Unknown broadcast message type - ignore it
         CASE ISNULL(m.loBM) OR NOT PEMSTATUS(m.loBM, "uType", 5) OR ISNULL(m.loBM.uType)
         
         * 'STYLE' broadcast message type
         CASE m.loBM.uType=="STYLE" 
              m.loBM.SetStyle(This)
       
      ENDCASE
   ENDPROC

ENDDEF

***************************************************************************
* Some form class
***************************************************************************
DEFINE CLASS form1 AS form
   DoCreate = .T.
   Caption = "Form1"
   Name = "Form1"

   ADD OBJECT label1 AS _mylabel ;
       WITH Height = 23, Left = 10, Top = 50, Width = 90, ;
            Caption ="Text 1:"

   ADD OBJECT text1 AS _mytextbox ;
       WITH Height = 23, Left = 100, Top = 48, Width = 100, Value="Text 1"


   ADD OBJECT label2 AS _mylabel;
       WITH Height = 23, Left = 10, Top = 98, Width = 90, ;
            Caption ="Text 2:"

   ADD OBJECT text2 AS _mytextbox;
       WITH Height = 23, Left = 100, Top = 96, Width = 100, Value="Text 2"


   ADD OBJECT label3 AS _mylabel;
       WITH Height = 23, Left = 10, Top = 146, Width = 90, ;
            Caption ="Text 3:"

   ADD OBJECT text3 AS _mytextbox;
       WITH Height = 23, Left = 100, Top = 144, Width = 100, Value="Text 3"

   ADD OBJECT cnt4 AS container;
       WITH Height = 27, Left = 0, Top = 192, Width = 200

   ADD OBJECT cmdFirstStyle AS _mycommandbutton;
       WITH Top = 132, Left = 252, Height = 27,  Width = 110, ;
            Caption = "First Style"

   ADD OBJECT cmdSecondStyle AS _mycommandbutton;
       WITH Top = 165, Left = 252, Height = 27,  Width = 110, ;
            Caption = "Second Style"
 
 
   * Property for seting broadcast message. This property will not be set never!!!
   uBroadcastMessage=.NULL. 
   
   
   PROCEDURE uBroadcastMessage_ASSIGN && See to help on "Access and Assign Methods"
      * 
      * form1::uBroadcastMessage_ASSIGN()
      * 
      LPARAMETERS m.luValue
      
      IF EMPTY(m.luValue) OR ISNULL(m.luValue) OR TYPE(m.luValue)<>"O"
         RETURN
      ENDIF
      
      LOCAL m.loBM
      m.loBM=EVALUATE(m.luValue) && Get broadcast message (object)
      DO CASE
         * Unknown broadcast message type - ignore it
         CASE ISNULL(m.loBM) OR NOT PEMSTATUS(m.loBM, "uType", 5) OR ISNULL(m.loBM.uType)
         
         * 'STYLE' broadcast message type
         CASE m.loBM.uType=="STYLE" 
              m.loBM.SetStyle(This)
              This.Cls()
              This.Print(DATETIME())
       
      ENDCASE
   ENDPROC
 
   PROCEDURE Destroy
      CLEAR EVENTS
   ENDPROC


   PROCEDURE cnt4.Init
      This.AddObject("label4", "_mylabel")
      WITH This.label4
      .Move(10, 4, 90, 21)
      .Caption ="Text 4:"
      .Visible=.T.
      ENDWITH

      This.AddObject("text4", "_mytextbox")
      WITH This.text4
      .Move(100, 2, 100, 23)
      .Value="Text 4"
      .Visible=.T.
      ENDWITH
   ENDPROC

  
   PROCEDURE cmdFirstStyle.Click
      PRIVATE m.poBM
      m.poBM =CREATEOBJECT("_BM_STYLE")
      m.poBM.FontBold=.T.

      * Send variable name, it's safety then object reference - don't cause Cx00000005 (sometimes)
      * Object reference is very unstable in VFP 7.0 (SP1)
      =SetAll_Assing("uBroadcastMessage", "m.poBM", , Thisform)
      RELEASE m.poBM && Release broadcast message object
   ENDPROC


   PROCEDURE cmdSecondStyle.Click
      PRIVATE m.poBM
      m.poBM =CREATEOBJECT("_BM_STYLE")
      m.poBM.FontName="Times New Roman"
      m.poBM.FontSize=11
      m.poBM.FontItalic=.T.

      * Send variable name, it's safety then object reference - don't cause Cx00000005 (sometimes)
      * Object reference is very unstable in VFP 7.0 (SP1)
      =SetAll_Assing("uBroadcastMessage", "m.poBM", , Thisform)
      RELEASE m.poBM && Release broadcast message object
   ENDPROC

ENDDEFINE

