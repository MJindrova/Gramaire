# Style Broadcast Message - all forms
[Previous example](./stylef_broadcast_message.md) show how change style (`FontName` etc.) for all objects in form or toolbar. But how change style on all runned forms?



**Main program**
```
m.loForm=CREATEOBJECT("form1")
m.loForm.Show()

m.loForm2=CREATEOBJECT("form1")
m.loForm2.Move(m.loForm.Left+m.loForm.Width+30, m.loForm.Top)
m.loForm2.Show()
READ EVENTS
```


**SetAll_Assing procedure**

It's a simply - just modify `SetAll_Assing` procedure...
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

**Some form class**

And modify form class...
```
DEFINE CLASS form1 AS form
   *...
   

   PROCEDURE cmdFirstStyle.Click
      PRIVATE m.poBM
      m.poBM =CREATEOBJECT("_BM_STYLE")
      m.poBM.FontBold=.T.

      * Send variable name, it's safety then object reference - don't cause Cx00000005 (sometimes)
      * Object reference is very unstable in VFP 7.0 (SP1)
      =SetAll_Assing("uBroadcastMessage", "m.poBM", , _Screen)
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
      =SetAll_Assing("uBroadcastMessage", "m.poBM", , _Screen)
      RELEASE m.poBM && Release broadcast message object
   ENDPROC

ENDDEFINE
``` 
               
[Full example](./src/styleallfforms_broadcast_message.prg)
