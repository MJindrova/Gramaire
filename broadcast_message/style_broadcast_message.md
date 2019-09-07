# Style Broadcast Message
This example shows how set style of labels, textboxes and command buttons on form.

** Some broadcast message class **
First step is create broadcast message style class. Properties Font\* are use for setings.
```
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
``` 

** Some textbox class **
Second step is create derived textbox class. But in the case, `uBroadcastMessage_ASSIGN` method process `STYLE` message.
```
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
``` 

** Some label class **
Third step is create derived label class. `uBroadcastMessage_ASSIGN` method is equal to method for derived textbox class.
```
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
``` 

** Some command button class **
Fourth step is create derived command button class. `uBroadcastMessage_ASSIGN` method is equal to method for derived textbox class.
```
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
``` 

** Some form class **
And last step is create form class. Command button "cmdFirstStyle" set font to "Tahoma Bold",10 and command button "cmdSecondStyle" set font to "Times New Romand Italic",11.
```
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
      #IF VAL(SUBS(VERSION(),LEN("Visual FoxPro ")+1,2))=5
       * Hack for VFP 5.0
       =SetAll_Assing("uBroadcastMessage", "m.poBM", , Thisform)
      #ELSE
       Thisform.SetAll("uBroadcastMessage", "m.poBM")
      #ENDIF
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
      #IF VAL(SUBS(VERSION(),LEN("Visual FoxPro ")+1,2))=5
       * Hack for VFP 5.0
       =SetAll_Assing("uBroadcastMessage", "m.poBM", , Thisform)
      #ELSE
       Thisform.SetAll("uBroadcastMessage", "m.poBM")
      #ENDIF
      RELEASE m.poBM && Release broadcast message object
   ENDPROC

ENDDEFINE
``` 

[Full example](./src/style_broadcast_message.prg)
