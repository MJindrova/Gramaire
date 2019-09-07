# Style Broadcast Message - form
[Previous example](./style_broadcast_message.md) show how change style (`FontName` etc.) for all objects in form or toolbar. But form has `Font*` properties too.


** SetAll_Assing procedure**
Because `SetAll()` method change property for objects in container only, it's needed set a property separatly.
It's a simply - just modify `SetAll_Assing` procedure.
```
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
``` 



** Some form class **
And modify form class...
```
DEFINE CLASS form1 AS form
   DoCreate = .T.
   Caption = "Form1"
   Name = "Form1"

   *...
   
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

   *...

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
``` 

[Full example](./src/stylef_broadcast_message.prg)
