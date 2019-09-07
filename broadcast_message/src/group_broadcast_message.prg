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

***************************************************************************
* Base broadcast message server class
***************************************************************************
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


***************************************************************************
* Base broadcast message class
***************************************************************************
DEFINE CLASS _BroadcastMessage AS CUSTOM
   Name="_BroadcastMessage"
   uType=.NULL.         && Broadcast message type   - can be string, date, datetime, boolean, number or object
   uResult=.NULL.       && Broadcast message result - can be string, date, datetime, boolean, number or object
   cDestinationClass="" && Destination class - equal to cClass parameter for SetAll() method
   cGroup=""            && Group identifier
   
   PROCEDURE Set
      * 
      * _BroadcastMessage::Set()
      * 
      LPARAMETERS m.loObj 
   ENDPROC
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
      LPARAMETERS m.loObj, m.lcKey
      This.iList=This.iList+1
      DIMENSION This.aList(This.iList, 2)
      This.aList(This.iList, 1)=m.loObj
      This.aList(This.iList, 2)=m.lcKey
   ENDPROC

   * Clear list
   PROCEDURE Clear
      * 
      * _BroadcastMessageResult::Clear()
      * 
      This.iList=0
      DIMENSION This.aList(1, 2)
      This.aList=.NULL.
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

  PROCEDURE Set
     * 
     * _BM_Style::Set()
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

DEFINE CLASS _BM_LANGUAGE AS _BroadcastMessage
   Name="_BM_LANGUAGE"
   uType="LANGUAGE"
   cLang=""
   
   PROCEDURE Set
      * 
      * _BM_LANGUAGE::Set()
      * 
      LPARAMETERS m.loObj 

      LOCAL m.lcClass, m.lii, m.lcString, m.liFCHS
      m.lcClass=UPPER(m.loObj.BaseClass)

      IF PEMSTATUS(m.loObj, "cLang", 5)
         m.loObj.cLang=This.cLang
      ENDIF

      * Set FontcharSet for objects
      IF PEMSTATUS(m.loObj, "FontCharset", 5)
         m.liFCHS=_Screen.Lang.GetFontCharset(This.cLang)
         IF FONTMETRIC(14, m.loObj.FontName, 10)=m.liFCHS
            m.loObj.FontCharset=m.liFCHS
         ENDIF

         * Set FontcharSet for tooltips
         #IF VAL(SUBS(VERSION(),LEN("Visual FoxPro ")+1,2))>=9
          IF VAL(SYS(3007))<>m.loObj.FontCharset
             =SYS(3007, m.loObj.FontCharset)
          ENDIF
         #ENDIF
      ENDIF

      IF PEMSTATUS(m.loObj, "aStringID", 5)
         FOR m.lii=1 TO ALEN(m.loObj.aStringID, 1)
             m.lcString=_Screen.Lang.GetString(This.cLang, m.loObj.aStringID(m.lii, 2))
             IF NOT EMPTY(m.loObj.aStringID(m.lii, 3)) AND ATC("m.lcString",m.loObj.aStringID(m.lii, 3))>0 && call callback function with parameter
                STORE EVALUATE("m.loObj."+m.loObj.aStringID(m.lii, 3)) TO ("m.loObj."+m.loObj.aStringID(m.lii, 1))
             ELSE   
                STORE m.lcString TO ("m.loObj."+m.loObj.aStringID(m.lii, 1))
                IF NOT EMPTY(m.loObj.aStringID(m.lii, 3)) && call callback function
                   =EVALUATE("m.loObj."+m.loObj.aStringID(m.lii, 3)+"()")
                ENDIF
             ENDIF
         NEXT
      ENDIF

   ENDPROC

ENDDEFINE


DEFINE CLASS _BM_DEFAULT_TEXT AS _BroadcastMessage
   Name="_BM_DEFAULT_TEXT"
   uType="DEFAULT_TEXT"
   
ENDDEFINE


***************************************************************************
* Some result class
***************************************************************************
DEFINE CLASS _BMR_VALIDATEDATA AS _BroadcastMessageResult
   Name="_BMR_VALIDATEDATA"

   * Get message text
   PROCEDURE GetMessage
      * 
      * _BMR_ValidateData::GetMessage()
      * 
      LOCAL m.lii, m.lcMessage
      m.lcMessage=""
      FOR m.lii=1 TO This.iList
          DO CASE
             CASE This.aList(m.lii, 2)=="EMPTYVALUE"
                  m.lcMessage=m.lcMessage+STRTRAN(This.aList(m.lii, 1).cValueMustbeFill, "%NAME%", This.aList(m.lii, 1).Name)+CHR(13)+CHR(10)
          ENDCASE
      NEXT
      RETURN m.lcMessage
   ENDPROC
  
ENDDEF


***************************************************************************
* Some language class
***************************************************************************
DEFINE CLASS _Language AS CUSTOM
   Name="_Language"
   cAlias=""
   lIsCzechAllowed=.F.

   PROCEDURE Init
      * 
      * _Language::Init()
      * 
     
      This.CollateTest()
      
      This.cAlias=SYS(2015)    
      CREATE CURSOR (This.cAlias) (LANG C(20), ID I, TEXT  M NOCPTRANS)
      SELECT (This.cAlias)
      INDEX ON LANG+STR(ID, 11) TAG ILANG
      
      * EN-US
      INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("en-us", -1, "Unknown string ID (%ID%)")
      INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("en-us", 1, "First Name:")
      INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("en-us", 2, "Second Name:")
      INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("en-us", 3, "Sure Name:")
      INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("en-us", 4, "Street:")

      INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("en-us", 5, "First Name")
      INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("en-us", 6, "Second Name")
      INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("en-us", 7, "Sure Name")
      INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("en-us", 8, "Street")
      
      INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("en-us", 9, "US English")
      INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("en-us", 10, "Czech")
      INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("en-us", 12, "German")
      INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("en-us", 11, "Language:")

      INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("en-us", 20, "My Toolbar")
      INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("en-us", 21, "My Form (%COLOR%)")
      INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("en-us", 22, "Blue")
      INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("en-us", 23, "Red")
      INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("en-us", 30, "Form:")
      INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("en-us", 31, "Style:")

      INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("en-us", 100, "Validate Data")
      INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("en-us", 101, [Field "%NAME%" can't be empty.])
      INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("en-us", 102, "...")

      INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("en-us", 200, "Customer first name")
      INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("en-us", 201, "Customer second name")
      INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("en-us", 202, "Customer sure name")
      INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("en-us", 203, "Customer street")

      * CS-CZ
      IF This.lIsCzechAllowed
         INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("cs-cz", -1, "Nezn�m� ID (%ID%) �et�zce")
         INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("cs-cz", 1, "Rodn� jm�no:")
         INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("cs-cz", 2, "Druh� rodn� jm�no:")
         INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("cs-cz", 3, "P��jmen�:")
         INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("cs-cz", 4, "Ulice:")

         INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("cs-cz", 5, "Rodn� jm�no")
         INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("cs-cz", 6, "Druh� rodn� jm�no")
         INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("cs-cz", 7, "P��jmen�")
         INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("cs-cz", 8, "Ulice")
         
         INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("cs-cz", 9, "Angli�tina")
         INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("cs-cz", 10, "�e�tina")
         INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("cs-cz", 12, "N�m�ina")
         INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("cs-cz", 11, "Jazyk:")

         INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("cs-cz", 20, "M�j panel n�stroj�")
         INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("cs-cz", 21, "M�j formul�� (%COLOR%)")
         INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("cs-cz", 22, "Modr�")
         INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("cs-cz", 23, "�erven�")
         INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("cs-cz", 30, "Formul��:")
         INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("cs-cz", 31, "Styl:")

         INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("cs-cz", 100, "Zkontrolovat �daje")
         INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("cs-cz", 101, [Pole "%NAME%" mus� m�t vypln�nou hodnotu.])
         INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("cs-cz", 102, "...")

         INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("cs-cz", 200, "Rodn� jm�no z�kazn�ka")
         INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("cs-cz", 201, "Druh� rodn� jm�no z�kazn�ka")
         INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("cs-cz", 202, "P��jmen� z�kazn�ka")
         INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("cs-cz", 203, "Ulice z�kazn�ka")
      ENDIF
      
      INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("de-de", -1, "Unbekannte Zeichenfolgen-ID (% ID%)")
      INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("de-de", 1, "Vorname:")
      INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("de-de", 2, "Zweitname:")
      INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("de-de", 3, "Sicherer Name:")
      INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("de-de", 4, "Stra�e:")

      INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("de-de", 5, "Vorname")
      INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("de-de", 6, "Zweitname")
      INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("de-de", 7, "Sicherer Name")
      INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("de-de", 8, "Stra�e")
      
      INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("de-de", 9, "Amerikanisches Englisch")
      INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("de-de", 10, "Tschechisch")
      INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("de-de", 12, "Deutsche")
      INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("de-de", 11, "Sprache:")

      INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("de-de", 20, "Meine Symbolleiste")
      INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("de-de", 21, "Meine Form (%COLOR%)")
      INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("de-de", 22, "Blaues")
      INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("de-de", 23, "Rot")
      INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("de-de", 30, "Form:")
      INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("de-de", 31, "Stil:")

      INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("de-de", 100, "Daten validieren")
      INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("de-de", 101, [Das Feld "%NAME%" darf nicht leer sein.])
      INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("de-de", 102, "...")

      INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("de-de", 200, "Vorname des Kunden")
      INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("de-de", 201, "Nachname des Kunden")
      INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("de-de", 202, "Kundensicherer Name")
      INSERT INTO (This.cAlias) (LANG, ID, TEXT) VALUES ("de-de", 203, "Kundenstra�e")
   ENDPROC


   PROCEDURE Destroy
      * 
      * _Language::Destroy()
      *
      USE IN (SELECT(This.cAlias))
   ENDPROC


   PROCEDURE GetFontCharset
      * 
      * _Language::GetFontCharset()
      *
      LPARAMETERS m.lcLang, m.liID

      DO CASE
         CASE m.lcLang=="en-us"
              RETURN 0

         CASE m.lcLang=="de-de"
              RETURN 0

         CASE m.lcLang=="cs-cz"
              RETURN 238
              
      ENDCASE
   ENDPROC
   
   
   PROCEDURE GetString
      * 
      * _Language::GetString()
      * 
      LPARAMETERS m.lcLang, m.liID

      IF m.liID=0 && Empty string
         RETURN ""
      ENDIF
      IF SEEK(PADR(m.lcLang, 20)+STR(m.liID, 11), This.cAlias)
         RETURN EVALUATE(This.cAlias+".TEXT")
      ENDIF
      =SEEK(PADR(m.lcLang, 20)+STR(-1, 11), This.cAlias)
      RETURN STRTRAN(EVALUATE(This.cAlias+".TEXT"), "%ID%", STR(m.liID, 11))
   ENDPROC


   PROCEDURE CollateTest
      * 
      * _Language::CollateTest()
      * 

      LOCAL m.lcCOLLATE, m.lcErr, m.llErr
      m.lcCOLLATE=SET("COLLATE")
      m.lcErr=ON("ERROR")

      ON ERROR m.llErr=.T.
      SET COLLATE TO "CZECH"
      IF NOT EMPTY(m.lcErr)
         ON ERROR &lcErr.
      ELSE
         ON ERROR
      ENDIF
      
      IF NOT m.llErr 
         This.lIsCzechAllowed=.T.
      ENDIF

      SET COLLATE TO (m.lcCOLLATE)
   ENDPROC
ENDDEF


***************************************************************************
* Some textbox class
***************************************************************************
DEFINE CLASS _mytextbox AS TEXTBOX
   Name="_mytextbox"

   * Flag if vaule can be empty
   lIsEmptyAllowed=.T.  

   * Property for seting broadcast message. This property will not be set never!!!
   uBroadcastMessage=.NULL. 

   cDefaultText=.NULL.
   lIsDefaultText=.F.
   iDefaultTextFCBak=.F.
   cDefaultTextSCBak=""
   cValueMustbeFill=.NULL.
   
   * String id for localization 
   DIMENSION aStringID[3, 3]
   aStringID[1, 1]="cDefaultText"    && Property
   aStringID[1, 2]=0                 && String ID 
   aStringID[1, 3]="SetDefaultText"  && Callback function

   aStringID[2, 1]="cValueMustbeFill"  && Property
   aStringID[2, 2]=101                 && String ID 
   aStringID[2, 3]=""    && Callback function

   aStringID[3, 1]="ToolTipText"  && Property
   aStringID[3, 2]=0              && String ID 
   aStringID[3, 3]=""    && Callback function

   cLang="en-us"
   
   PROCEDURE KeyPress
      * 
      * _mytextbox::KeyPress()
      * 
      
      LPARAMETERS m.nKeyCode, m.nShiftAltCtrl

      IF NOT INLIST(m.nKeyCode, 22, 1, 6, 18, 3, 5, 24, 4,19,  9) AND This.lIsDefaultText
         This.ClearDefaultText()
      ENDIF
   ENDPROC


   PROCEDURE LostFocus
      * 
      * _mytextbox::LostFocus()
      * 
      
      IF NOT This.lIsDefaultText
         This.SetDefaultText()
      ENDIF
   ENDPROC


   PROCEDURE ClearDefaultText
      * 
      * _mytextbox::ClearDefaultText()
      * 
      
      This.Value=''
      This.ForeColor=This.iDefaultTextFCBak
      This.ControlSource=This.cDefaultTextSCBak
      This.lIsDefaultText=.F.
   ENDPROC


   PROCEDURE SetDefaultText
      * 
      * _mytextbox::SetDefaultText()
      * 
      
      IF ISNULL(This.cDefaultText)
         This.cDefaultText=_Screen.Lang.GetString(This.cLang, This.aStringID(1, 2))
      ENDIF

      IF This.lIsDefaultText
         This.Value=This.cDefaultText
      ENDIF
         
      IF ISNULL(This.Value) AND NOT This.lIsDefaultText
         This.Value=This.cDefaultText
         This.iDefaultTextFCBak=This.ForeColor
         This.cDefaultTextSCBak=This.ControlSource
         This.ForeColor=RGB(192, 192, 192)
         This.lIsDefaultText=.T.
      ENDIF
   ENDPROC
   
   
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
              m.loBM.Set(This)
         
         * 'LANGUAGE' broadcast message type
         CASE m.loBM.uType=="LANGUAGE" 
              m.loBM.Set(This)

         * 'DEFAULT_TEXT' broadcast message type
         CASE m.loBM.uType=="DEFAULT_TEXT"
              This.SetDefaultText()

         * 'VALIDATEDATA' broadcast message type
         CASE m.loBM.uType=="VALIDATEDATA" 
              IF ISNULL(m.loBM.uResult)
                 * If result not define, create it
                 m.loBM.uResult=CREATEOBJECT("_BMR_VALIDATEDATA")
              ENDIF
              IF NOT This.lIsEmptyAllowed AND (EMPTY(This.Value) OR This.lIsDefaultText) && Hmm, value is empty
                 m.loBM.uResult.Add(This, "EMPTYVALUE") && Add object to result
                 m.loBM.uResult.uFlag=.F. && Set Flag
              ENDIF

       
      ENDCASE
   ENDPROC

ENDDEF


***************************************************************************
* Some label class
***************************************************************************
DEFINE CLASS _mylabel AS LABEL
   Name="_mylabel"

   BackStyle=0
   
   * Property for seting broadcast message. This property will not be set never!!!
   uBroadcastMessage=.NULL. 

   * String id for localization 
   DIMENSION aStringID[1 ,3]
   aStringID[1 ,1]="Caption" && Property
   aStringID[1 ,2]=0         && String ID
   cLang="en-us"
   
   
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
              m.loBM.Set(This)

         * 'LANGUAGE' broadcast message type
         CASE m.loBM.uType=="LANGUAGE" 
              m.loBM.Set(This)
       
      ENDCASE
   ENDPROC

ENDDEF



***************************************************************************
* Some combobox class
***************************************************************************
DEFINE CLASS _mycombobox AS COMBOBOX
   Name="_mycombobox"

   * Property for seting broadcast message. This property will not be set never!!!
   uBroadcastMessage=.NULL. 

   * String id for localization 
   DIMENSION aStringID[1, 3]
   aStringID[1, 2]=0 && String ID
   cLang="en-us"
   
   
   PROCEDURE uBroadcastMessage_ASSIGN && See to help on "Access and Assign Methods"
      * 
      * _mycombobox::uBroadcastMessage_ASSIGN()
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
              m.loBM.Set(This)

         * 'LANGUAGE' broadcast message type
         CASE m.loBM.uType=="LANGUAGE" 
              m.loBM.Set(This)
       
      ENDCASE
   ENDPROC

ENDDEF


DEFINE CLASS _mylngcombobox AS _mycombobox
   Name="_mylngcombobox"

   BoundColumn=2
   BoundTo=.T.
   ColumnCount=2
   ColumnLines=.F.
   ColumnWidths='150,0'
   Style=2
   
   DIMENSION aStringID[3, 3]

   PROCEDURE Init
      * 
      * _mylngcombobox:init
      *

      LOCAL m.lii
      m.lii=1
      This.aStringID(m.lii, 1)="ListItem(9, 1)"
      This.aStringID(m.lii, 2)=9
      IF _Screen.Lang.lIsCzechAllowed
         m.lii=m.lii+1
         This.aStringID(m.lii, 1)="ListItem(10, 1)"
         This.aStringID(m.lii, 2)=10   
      ENDIF
      m.lii=m.lii+1
      This.aStringID(m.lii, 1)="ListItem(12, 1)"
      This.aStringID(m.lii, 2)=12
      DIMENSION This.aStringID(m.lii, ALEN(This.aStringID, 2))

      =This.AddListItem(_Screen.Lang.GetString("en-us", 9), 9, 1) AND;
       This.AddListItem("en-us", 9, 2)
       
      IF _Screen.Lang.lIsCzechAllowed
         =This.AddListItem(_Screen.Lang.GetString("en-us", 10), 10, 1) AND;
          This.AddListItem("cs-cz", 10, 2)
      ENDIF
              
      =This.AddListItem(_Screen.Lang.GetString("en-us", 12), 12, 1) AND;
       This.AddListItem("de-de", 12, 2)
      This.Value="en-us"
   ENDPROC


   PROCEDURE InteractiveChange
      * 
      * _mylngcombobox:InteractiveChange
      *
      
      This.SendBM_LANGUAGE()
   ENDPROC


   PROCEDURE ProgrammaticChange
      * 
      * _mylngcombobox:ProgrammaticChange
      *
      
      This.SendBM_LANGUAGE()
   ENDPROC


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


***************************************************************************
* Some command button class
***************************************************************************
DEFINE CLASS _mycommandbutton AS COMMANDBUTTON
   Name="_mycommandbutton"

   * String id for localization 
   DIMENSION aStringID[1, 3]
   aStringID[1, 1]="Caption" && Property
   aStringID[1, 2]=0         && String ID
   cLang="en-us"

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
              m.loBM.Set(This)

         * 'LANGUAGE' broadcast message type
         CASE m.loBM.uType=="LANGUAGE" 
              m.loBM.Set(This)
       
      ENDCASE
   ENDPROC

ENDDEF

DEFINE CLASS _mystylecommandbutton AS _mycommandbutton
   Name="_mystylecommandbutton"
   Caption="..."
   
   aStringID[1, 2]=102         && String ID
   
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


   PROCEDURE Parse
      * 
      * _mystylecommandbutton::Parse()
      * 
      LPARAMETERS m.lcData, m.lcFont, m.liSize, m.lcStyle
      LOCAL m.lii
      m.lii=AT(",", m.lcData)
      m.liSize=10
      m.lcStyle=''
      IF m.lii=0
         m.lcFont=m.lcData
      ELSE
         m.lcFont=LEFT(m.lcData, m.lii-1)
         m.lcData=SUBSTR(m.lcData, m.lii+1)
         m.lii=AT(",", m.lcData)
         IF m.lii>0
            m.liSize=VAL(LEFT(m.lcData, m.lii-1))
            m.lcStyle=SUBSTR(m.lcData, m.lii+1)
         ENDIF
      ENDIF
   ENDPROC

ENDDEF

***************************************************************************
* Some toolbar class
***************************************************************************
DEFINE CLASS _MyToolbar AS TOOLBAR
   DoCreate = .T.
   Caption = "My Toolbar"
   Name = "_MyToolbar"

   * String id for localization 
   DIMENSION aStringID[1, 3]
   aStringID[1, 1]="Caption" && Property
   aStringID[1, 2]=20        && String ID
   cLang="en-us"

   ADD OBJECT cntLanguage AS CONTAINER;
       WITH Height = 27, Width = 242, BackStyle=0

   ADD OBJECT cntStyle AS CONTAINER;
       WITH Height = 27, Width = 460, BackStyle=0

   * Property for seting broadcast message. This property will not be set never!!!
   uBroadcastMessage=.NULL. 
   
   
   PROCEDURE uBroadcastMessage_ASSIGN && See to help on "Access and Assign Methods"
      * 
      * _MyToolbar::uBroadcastMessage_ASSIGN()
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
         
         * 'LANGUAGE' broadcast message type
         CASE m.loBM.uType=="LANGUAGE" 
              m.loBM.Set(This)
       
      ENDCASE
   ENDPROC


   PROCEDURE cntLanguage.Init
      * 
      * _MyToolbar.cntLanguage::Init()
      * 
   
      This.AddObject("lblLanguage", "_mylabel")
      WITH This.lblLanguage
      .Move(10, 4, 80, 21)
      .Caption ="Language:"
      .aStringID[1, 2]=11
      .Visible=.T.
      ENDWITH

      This.AddObject("cboLanguage", "_mylngcombobox")
      WITH This.cboLanguage
      .Move(90, 2, 150, 23)
      .Visible=.T.
      ENDWITH
   ENDPROC


   PROCEDURE cntStyle.Init
      * 
      * _MyToolbar.cntStyle::Init()
      * 

      This.AddObject("lblLanguage", "_mylabel")
      WITH This.lblLanguage
      .Move(10, 4, 60, 21)
      .Caption ="Form:"
      .aStringID[1, 2]=30
      .Visible=.T.
      ENDWITH

      This.AddObject("cboGroup", "_mycombobox")
      WITH This.cboGroup
      .Move(75, 2, 80, 23)
      .Visible=.T.
      .BoundColumn=2
      .BoundTo=.T.
      .ColumnCount=2
      .ColumnLines=.F.
      .ColumnWidths='60,0'
      .Style=2

      DIMENSION .aStringID(2, ALEN(.aStringID, 2))
      .aStringID(1, 1)="ListItem(22, 1)"
      .aStringID(1, 2)=22
      .aStringID(2, 1)="ListItem(23, 1)"
      .aStringID(2, 2)=23

      =.AddListItem(_Screen.Lang.GetString("en-us", 22), 22, 1) AND;
       .AddListItem("Blue", 22, 2)
      =.AddListItem(_Screen.Lang.GetString("en-us", 23), 23, 1) AND;
       .AddListItem("Red", 23, 2)
      .Value="Red"

      ENDWITH

      This.AddObject("lblStyle", "_mylabel")
      WITH This.lblStyle
      .Move(160, 4, 60, 21)
      .Caption ="Style:"
      .aStringID[1, 2]=31
      .Visible=.T.
      ENDWITH

      This.AddObject("txtFont", "_mytextbox")
      WITH This.txtFont
      .Move(225, 2, 200, 23)
      .ReadOnly=.T.
      .Value="Arial,10,N"
      .Visible=.T.
      ENDWITH

      This.AddObject("cmdStyle", "_mystylecommandbutton")
      WITH This.cmdStyle
      .Move(430, 2, 23, 23)
      .Visible=.T.
      ENDWITH

   ENDPROC

ENDDEF


***************************************************************************
* Some form class
***************************************************************************
DEFINE CLASS _MyForm AS form
   DoCreate = .T.
   Caption = "Default Form Caption"
   Name = "_MyForm"
   KeyPreview=.T.
   ShowTips = .T.
   
   * String id for localization 
   DIMENSION aStringID[1, 3]
   aStringID[1, 1]="Caption"                        && Property
   aStringID[1, 2]=21                               && String ID
   aStringID[1, 3]="DynamicFormCaption(m.lcString)" && Callback function
   cLang="en-us"

   cGroup="" && Group form

   ADD OBJECT lblFirstName AS _mylabel ;
       WITH Height = 23, Left = 10, Top = 50, Width = 110, aStringID[1, 2]=1, ;
            Caption ="First Name:"

   ADD OBJECT txtFirstName AS _mytextbox ;
       WITH Height = 23, Left = 120, Top = 48, Width = 150, Value=.NULL., aStringID[1, 2]=5, aStringID[3, 2]=200, lIsEmptyAllowed=.F.


   ADD OBJECT lblSecondName AS _mylabel;
       WITH Height = 23, Left = 10, Top = 98, Width = 110, aStringID[1, 2]=2, ;
            Caption ="Second Name:"

   ADD OBJECT txtSecondName AS _mytextbox;
       WITH Height = 23, Left = 120, Top = 96, Width = 150, Value=.NULL., aStringID[1, 2]=6, aStringID[3, 2]=201


   ADD OBJECT lblSureName AS _mylabel;
       WITH Height = 23, Left = 10, Top = 146, Width = 110, aStringID[1, 2]=3, ;
            Caption ="Sure Name:"

   ADD OBJECT txtSureName AS _mytextbox;
       WITH Height = 23, Left = 120, Top = 144, Width = 150, Value=.NULL., aStringID[1, 2]=7, aStringID[3, 2]=202, lIsEmptyAllowed=.F.

   ADD OBJECT cntStreet AS container;
       WITH Height = 27, Left = 0, Top = 192, Width = 272, BackStyle=0

    ADD OBJECT cmdValidateData AS _mycommandbutton;
       WITH Top = 5, Left = 232, Height = 27,  Width = 130, aStringID[1, 2]=100, ;
            Caption = "Validate Data"

 
   * Property for seting broadcast message. This property will not be set never!!!
   uBroadcastMessage=.NULL. 
   
   
   PROCEDURE uBroadcastMessage_ASSIGN && See to help on "Access and Assign Methods"
      * 
      * _MyForm::uBroadcastMessage_ASSIGN()
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
         
         * 'LANGUAGE' broadcast message type
         CASE m.loBM.uType=="LANGUAGE" 
              m.loBM.Set(This)
       
      ENDCASE
   ENDPROC
 
 
   PROCEDURE Destroy
      * 
      * _MyForm::Destroy()
      * 
      CLEAR EVENTS
   ENDPROC


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

   
   PROCEDURE DynamicFormCaption
      * 
      * _MyForm::DynamicFormCaption()
      * 
      LPARAMETERS m.lcString

      IF This.BackColor=RGB(200, 200, 255)
         RETURN STRTRAN(m.lcString, "%COLOR%", _Screen.Lang.GetString(This.cLang, 22))
      ENDIF

      IF This.BackColor=RGB(255, 200, 200)
         RETURN STRTRAN(m.lcString, "%COLOR%", _Screen.Lang.GetString(This.cLang, 23))
      ENDIF
      RETURN STRTRAN(m.lcString, "%COLOR%", "")
   ENDPROC


   PROCEDURE cntStreet.Init
      * 
      * _MyForm.cntStreet::Init()
      * 
      This.AddObject("lblStreet", "_mylabel")
      WITH This.lblStreet
      .Move(10, 4, 110, 21)
      .Caption ="Street:"
      .aStringID[1, 2]=4
      .Visible=.T.
      ENDWITH

      This.AddObject("txtStreet", "_mytextbox")
      WITH This.txtStreet
      .Move(120, 2, 150, 23)
      .Value=.NULL.
      .aStringID[1, 2]=8
      .aStringID[3, 2]=203
      .Visible=.T.
      ENDWITH
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


DEFINE CLASS _MyFormBlue AS _MyForm
   Name="_MyFormBlue"
   BackColor=RGB(200, 200, 255)
   cGroup="Blue"
ENDDEFINE

DEFINE CLASS _MyFormRed AS _MyForm
   Name="_MyFormRed"
   BackColor=RGB(255, 200, 200)
   cGroup="Red"
ENDDEFINE

