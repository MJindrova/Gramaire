# Group Broadcast Message
[Previous example](./language_broadcast_message.md) show how change language and style (`FontName` etc.) for all objects in all forms or toolbars. But how change style on some runned forms? Let's have two "red" forms and tow "blue" forms.


** Main program **
```
LOCAL m.loToolbar, m.loFormRed1, m.loFormBlue1, m.loFormRed2, m.loFormBlue2
_Screen.AddObject("Lang", "_Language")
_Screen.AddObject("BMS", "_BroadcastMessageServer")

m.loToolbar=CREATEOBJECT("_MyToolbar")
m.loToolbar.Dock(0)
m.loToolbar.Show()

m.loFormRed1=CREATEOBJECT("_MyFormBlue")
m.loFormRed1.Show()

m.loFormBlue1=CREATEOBJECT("_MyFormRed")
m.loFormBlue1.Move(m.loFormRed1.Left+m.loFormRed1.Width+30, m.loFormRed1.Top)
m.loFormBlue1.Show()

m.loFormRed2=CREATEOBJECT("_MyFormBlue")
m.loFormRed2.Move(m.loFormRed1.Left+m.loFormRed1.Width+30, m.loFormRed1.Top+m.loFormRed1.Height+60)
m.loFormRed2.Show()

m.loFormBlue2=CREATEOBJECT("_MyFormRed")
m.loFormBlue2.Move(m.loFormRed1.Left, m.loFormRed1.Top+m.loFormRed1.Height+60)
m.loFormBlue2.Show()

READ EVENTS

_Screen.RemoveObject("Lang")
_Screen.RemoveObject("BMS")
CLOSE ALL
CLEAR ALL
```


** Base broadcast message server class **
The big first step is transform `SetAll_Assing` procedure to  regular class.
```
DEFINE CLASS _BroadcastMessageServer AS CUSTOM
   Name="_BroadcastMessageServer"

   PROTECTED iLevel, cHiddenKey, lCatch
   
   iLevel=0
   cHiddenKey=SYS(2015)
   lCatch=.NULL.
   nError=0
   cMethod=""
   nLine=""
   cMessage=""


   PROCEDURE Error
      * 
      * _BroadcastMessageServer::Error()
      * 
      LPARAMETERS m.nError, m.cMethod, m.nLine

      This.nError=m.nError
      This.cMethod=m.cMethod
      This.nLine=m.nLine
      This.cMessage=MESSAGE()
      
      #IF VAL(SUBS(VERSION(),LEN("Visual FoxPro ")+1,2))>=8
       DEBUGOUT "##BMS "+This.nError, This.cMethod, This.nLine, This.cMessage
      #ELSE
       DEBUGOUT "##BMS "+LTRIM(STR(This.nError,11))+' '+LTRIM(STR(This.cMethod, This.nLine,11))+' '+This.cMessage
      #ENDIF    
      IF ISNULL(This.lCatch)
         LOCAL m.lcErr
         m.lcErr=ON("ERROR")
         &lcErr.
      ENDIF

      IF This.lCatch
         This.lCatch=.NULL.
         RETURN
      ENDIF
   ENDPROC
   

   PROCEDURE SetCatch
      * 
      * _BroadcastMessageServer::SetCatch()
      * 
      LPARAMETERS m.luCatch
      This.lCatch=m.luCatch
      IF This.lCatch
         STORE 0 TO This.nError, This.nLine
         STORE "" TO This.cMethod, This.cMessage
      ENDIF
   ENDPROC


   PROCEDURE SetAll_Assing_Controls
      * 
      * _BroadcastMessageServer::SetAll_Assing_Controls()
      * 
      LPARAMETERS m.lcProperty, m.luValue, m.lcClass, m.loObj
      
      IF NOT PEMSTATUS(m.loObj, "ControlCount", 5)
         RETURN
      ENDIF
      
      LOCAL m.lii, m.loObjC
      FOR m.lii=1 TO m.loObj.ControlCount
          m.loObjC=m.loObj.Controls(m.lii)
          
          IF PEMSTATUS(m.loObjC, "cHiddenKey", 5) AND COMPOBJ(This, m.loObjC)
             LOOP && Ignore Broadcast Message Server object
          ENDIF

          IF PEMSTATUS(m.loObjC, "Controls", 5)
             IF PEMSTATUS(m.loObjC, "SetAll_Assing", 5)
                =m.loObjC.SetAll_Assing(@m.lcProperty, @m.luValue, @m.lcClass)
             ELSE
                =This.SetAll_Assing(@m.lcProperty, @m.luValue, @m.lcClass, @m.loObjC)
             ENDIF
          ELSE
             IF PEMSTATUS(m.loObjC, m.lcProperty, 5) AND (LEN(m.lcClass)=0 OR UPPER(m.loObjC.Class)==m.lcClass)
                =EVALUATE("m.loObjC."+m.lcProperty+"_ASSIGN(@m.luValue)")
             ENDIF
          ENDIF
      NEXT
   ENDPROC

   ***************************************************************************
   * SetAll + Assign 
   * Hack for VFP 3.0/5.0
   * or for control class or other container class with protected or hidden objects
   ***************************************************************************
   PROCEDURE SetAll_Assing
      * 
      * _BroadcastMessageServer::SetAll_Assing()
      * 
      LPARAMETERS m.lcProperty, m.luValue, m.lcClass, m.loObj

      This.iLevel=This.iLevel+1

      m.loObj=IIF(ISNULL(m.loObj) OR TYPE("m.loObj")<>"O", _Screen, m.loObj)
      m.lcClass=IIF(EMPTY(m.lcClass), "", UPPER(ALLTRIM(m.lcClass)))
      
      #IF VAL(SUBS(VERSION(),LEN("Visual FoxPro ")+1,2))=5
       IF PEMSTATUS(m.loObj, m.lcProperty, 5) AND (LEN(m.lcClass)=0 OR UPPER(m.loObj.Class)==m.lcClass)
          =EVALUATE("m.loObj."+m.lcProperty+"_ASSIGN(@m.luValue)")
       ENDIF

       =This.SetAll_Assing_Controls(@m.lcProperty, @m.luValue, @m.lcClass, @m.loObj)
      #ELSE
       IF PEMSTATUS(m.loObj, m.lcProperty, 5) AND (LEN(m.lcClass)=0 OR UPPER(m.loObj.Class)==m.lcClass)
          STORE m.luValue TO ("m.loObj."+m.lcProperty)
       ENDIF

       IF PEMSTATUS(m.loObj, "SetAll", 5)
          This.SetCatch(.T.)
          =IIF(EMPTY(m.lcClass), m.loObj.SetAll(m.lcProperty, m.luValue), m.loObj.SetAll(m.lcProperty, m.luValue, m.lcClass))
*!*           IF This.nError>0
*!*              DEBUGOUT m.loObj.Class+" "+m.loObj.Name
*!*           ENDIF
       ENDIF
      #ENDIF
      This.iLevel=This.iLevel-1
   ENDPROC


   PROCEDURE Send
      * 
      * _BroadcastMessageServer::Send()
      * 
      LPARAMETERS m.loBM, m.loInstance

      m.loInstance=IIF(ISNULL(m.loInstance) OR TYPE("m.loInstance")<>"O", _Screen, m.loInstance)

      PRIVATE m.poBM
      m.poBM=m.loBM

      * Send variable name, it's safety then object reference - don't cause Cx00000005 (sometimes)
      * Object reference is very unstable in VFP 7.0 (SP1)

      IF NOT (PEMSTATUS(m.loInstance, "FormCount", 5) AND UPPER(m.loInstance.Name)="SCREEN")
         * It's a form or toolbar or some object
         IF EMPTY(m.loBM.cGroup) OR NOT EMPTY(m.loBM.cGroup) AND PEMSTATUS(m.loInstance, "cGroup", 5) AND m.loInstance.cGroup==m.loBM.cGroup
            =This.SetAll_Assing("uBroadcastMessage", "m.poBM", m.loBM.cDestinationClass, m.loInstance)
         ENDIF
         RETURN
      ENDIF

      * It's a screen
      =This.SetAll_Assing("uBroadcastMessage", "m.poBM", m.loBM.cDestinationClass, m.loInstance) && call SetAll for objects on _Screen
      * Walks forms and toolbars
      FOR m.lii=1 TO m.loInstance.FormCount
          IF EMPTY(m.loBM.cGroup) OR NOT EMPTY(m.loBM.cGroup) AND PEMSTATUS(m.loInstance.Forms(m.lii), "cGroup", 5) AND m.loInstance.Forms(m.lii).cGroup==m.loBM.cGroup
             =This.SetAll_Assing("uBroadcastMessage", "m.poBM", m.loBM.cDestinationClass, m.loInstance.Forms(m.lii))
          ENDIF
      NEXT

      RELEASE m.poBM
   ENDPROC
ENDDEFINE
``` 

** Base broadcast message class **
New `cGroup` property differentiate forms.
```
DEFINE CLASS _BroadcastMessage AS CUSTOM
   *...

   cDestinationClass="" && Destination class - equal to cClass parameter for SetAll() method
   cGroup=""            && Group identifier

   *...
ENDDEF
``` 


** Some broadcast message class **
Hmm bug in `_BM_LANGUAGE::Set()`  method, a font may not contain glyphs for codepage.
```
DEFINE CLASS _BM_LANGUAGE AS _BroadcastMessage
   Name="_BM_LANGUAGE"
   uType="LANGUAGE"
   cLang=""
   
   PROCEDURE Set
      * 
      * _BM_LANGUAGE::Set()
      * 
      LPARAMETERS m.loObj 

      *...

      * Set FontcharSet for objects
      IF PEMSTATUS(m.loObj, "FontCharset", 5)
         m.liFCHS=_Screen.Lang.GetFontCharset(This.cLang)
         IF FONTMETRIC(14, m.loObj.FontName, 10)=m.liFCHS
            m.loObj.FontCharset=m.liFCHS
         ENDIF

         *...
      ENDIF
      *...

   ENDPROC

ENDDEFINE
``` 


** Some combobox class **
And change sendind broadcast message.
```
DEFINE CLASS _mycombobox AS COMBOBOX
   *...
   
   PROCEDURE SendBM_LANGUAGE
      * 
      * _mylngcombobox:SendBM_LANGUAGE
      *
      
      IF This.Value==This.cLang
         RETURN
      ENDIF
      
      LOCAL m.loBM
      m.loBM =CREATEOBJECT("_BM_LANGUAGE")
      m.loBM.cLang=This.Value
      =_Screen.BMS.Send(m.loBM)
      RELEASE m.loBM && Release broadcast message object
   ENDPROC

ENDDEF
```

** Some command button class **
```
DEFINE CLASS _mystylecommandbutton AS _mycommandbutton
   *...
   
   PROCEDURE Click
      * 
      * _mystylecommandbutton::Click()
      * 
      LOCAL m.lcFont, m.liSize, m.lcStyle
      This.Parse(ALLTRIM(This.Parent.txtFont.Value), @m.lcFont, @m.liSize, @m.lcStyle)
      #IF VAL(SUBS(VERSION(),LEN("Visual FoxPro ")+1,2))=5
       m.lcFont=GETFONT()
      #ELSE
       m.lcFont=GETFONT(m.lcFont, m.liSize, m.lcStyle)
      #ENDIF
      IF EMPTY(m.lcFont)
         RETURN
      ENDIF
      This.Parent.txtFont.Value=m.lcFont
      This.Parse(m.lcFont, @m.lcFont, @m.liSize, @m.lcStyle)

      LOCAL m.loBM
      m.loBM =CREATEOBJECT("_BM_STYLE")
      m.loBM.cGroup=This.Parent.cboGroup.Value
      *m.loBM.cDestinationClass="_mylabel" && only for objects base on _mylabel class
      m.loBM.FontName=m.lcFont
      m.loBM.FontSize=m.liSize
      m.loBM.FontItalic=ATC("I", m.lcStyle)>0
      m.loBM.FontBold=ATC("B", m.lcStyle)>0
      m.loBM.FontUnderline=ATC("_", m.lcStyle)>0
      m.loBM.FontStrikethru=ATC("-", m.lcStyle)>0
      =_Screen.BMS.Send(m.loBM)
      RELEASE m.loBM && Release broadcast message object
   ENDPROC

ENDDEF
```


** Some form class **
```
DEFINE CLASS _MyForm AS form


   PROCEDURE Init
      * 
      * _MyForm::Init()
      * 
      LOCAL m.loBM
      m.loBM =CREATEOBJECT("_BM_DEFAULT_TEXT")
      =_Screen.BMS.Send(m.loBM, Thisform)

      m.loBM =CREATEOBJECT("_BM_LANGUAGE")
      m.loBM.cLang=This.cLang
      =_Screen.BMS.Send(m.loBM, Thisform)
      RELEASE m.loBM && Release broadcast message object
   ENDPROC



   PROCEDURE cmdValidateData.Click
      * 
      * _MyForm.cmdValidateData::Click()
      * 
   
      LOCAL m.loBM
      m.loBM =CREATEOBJECT("_BroadcastMessage")
      m.loBM.uType="VALIDATEDATA"

      =_Screen.BMS.Send(m.loBM, Thisform)
      
      * Check broadcast message result
      DO CASE
         CASE ISNULL(m.loBM.uResult) && Nothing object tested
              CLEAR EVENTS 
              
         CASE m.loBM.uResult.uFlag && All tested objects are right
              CLEAR EVENTS 

         OTHERWISE && Some object cause error
             =MESSAGEBOX(m.loBM.uResult.GetMessage()) 
             m.loBM.uResult.aList(1, 1).SetFocus() && Activate first object from list
             m.loBM.uResult.Clear() && Clear result
      ENDCASE
      RELEASE m.loBM && Release broadcast message object
   ENDPROC

ENDDEFINE
``` 

[Full example](./src/language_broadcast_message.prg)
