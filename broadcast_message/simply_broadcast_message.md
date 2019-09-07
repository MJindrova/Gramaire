# Simply Broadcast Message
This example shows how to get list of textboxes which are empty value.

** Base broadcast message class **
We need simply broadcast message class with two properties - `uType` and `uResult`. What `u` prefix, because the value type can be string, date, datetime, boolean, number or object.
```
DEFINE CLASS _BroadcastMessage AS CUSTOM
  Name="_BroadcastMessage"
  uType=.NULL.    && Broadcast message type
  uResult=.NULL.  && Broadcast message result
ENDDEFINE
``` 

** Base broadcast message result class **
And we need simply broadcast message result class. OK, not is siply clas, because it has three properties and three methods.
```
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
``` 


** Some result class **
And we create derived broadcast message result class. This class contains only one method which build string for message box.
```
DEFINE CLASS _BMR_MustBeFill AS _BroadcastMessageResult
   Name="_BMR_MustBeFill"

   * Get message text
   PROCEDURE GetMessage
      * 
      * _BMR_MustBeFill::GetMessage()
      * 
      LOCAL m.lii, m.lcMessage
      m.lcMessage=""
      FOR m.lii=1 TO This.iList
          m.lcMessage=m.lcMessage+This.aList(m.lii,1).Name+" is empty."+CHR(13)+CHR(10)
      NEXT
      RETURN m.lcMessage
   ENDPROC
  
ENDDEF
```


** Some textbox class **
Now create derived class from textbox. 
Property `uBroadcastMessage` is "virtual" and never be set. 
Property `lIsEmptyAllowed` is flag if vaule can be empty.
Method `uBroadcastMessage_ASSIGN` is for  assigment value to property. Executive code is in this method. 
```
DEFINE CLASS _mytextbox AS textbox
   Name="_mytextbox"

   * Property for seting broadcast message.
   uBroadcastMessage=.NULL. 
   
   * Flag if vaule can be empty
   lIsEmptyAllowed=.T.  
   
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
         
         * 'MUSTBEFILL' broadcast message type
         CASE m.loBM.uType=="MUSTBEFILL" 
              IF ISNULL(m.loBM.uResult)
                 * If result not define, create it
                 m.loBM.uResult=CREATEOBJECT("_BMR_MustBeFill")
              ENDIF
              IF NOT This.lIsEmptyAllowed AND EMPTY(This.Value) && Hmm, value is empty
                 m.loBM.uResult.Add(This) && Add object to result
                 m.loBM.uResult.uFlag=.F. && Set Flag
              ENDIF
       
      ENDCASE
   ENDPROC

ENDDEF
```


** Some form class **
And form which contains labels, textboxes and command button. 
Executive code is in event `Click()` on command button. 
This code create broadcast messsage object, set `uType` property and call `SetAll()` method in form.
```
DEFINE CLASS form1 AS form
   DoCreate = .T.
   Caption = "Form1"
   Name = "Form1"


   ADD OBJECT label1 AS label ;
       WITH Height = 23, Left = 10, Top = 50, Width = 90, ;
            Caption ="Text 1:"

   ADD OBJECT text1 AS _mytextbox ;
       WITH Height = 23, Left = 100, Top = 48, Width = 100, ;
            lIsEmptyAllowed =.F.


   ADD OBJECT label2 AS label;
       WITH Height = 23, Left = 10, Top = 98, Width = 90, ;
            Caption ="Text 2:"

   ADD OBJECT text2 AS _mytextbox;
       WITH Height = 23, Left = 100, Top = 96, Width = 100, ;
            lIsEmptyAllowed =.F.


   ADD OBJECT label3 AS label;
       WITH Height = 23, Left = 10, Top = 146, Width = 90, ;
            Caption ="Text 3:"

   ADD OBJECT text3 AS _mytextbox;
       WITH Height = 23, Left = 100, Top = 144, Width = 100, ;
            Name = "Text3"

   ADD OBJECT cnt4 AS container;
       WITH Height = 27, Left = 0, Top = 192, Width = 200, ;
            Name = "cnt4"

   ADD OBJECT cmdvalid AS commandbutton;
       WITH Top = 132, Left = 252, Height = 27,  Width = 84, ;
            Caption = "Valid data"

 
   PROCEDURE Destroy
      CLEAR EVENTS
   ENDPROC


   PROCEDURE cnt4.Init
      This.AddObject("label4", "label")
      WITH This.label4
      .Move(10, 4, 90, 21)
      .Caption ="Text 4:"
      .Visible=.T.
      ENDWITH

      This.AddObject("text4", "_mytextbox")
      WITH This.text4
      .Move(100, 2, 100, 23)
      .lIsEmptyAllowed =.F.
      .Visible=.T.
      ENDWITH
   ENDPROC

  
   PROCEDURE cmdvalid.Click
      PRIVATE m.poBM
      m.poBM =CREATEOBJECT("_BroadcastMessage")
      m.poBM.uType="MUSTBEFILL"

      * Send variable name, it's safety then object reference - don't cause Cx00000005 (sometimes)
      * Object reference is very unstable in VFP 7.0 (SP1)
      Thisform.SetAll("uBroadcastMessage", "m.poBM")
      
      * Check broadcast message result
      DO CASE
         CASE ISNULL(m.poBM.uResult) && Nothing object tested
              CLEAR EVENTS 
              
         CASE m.poBM.uResult.uFlag && All tested objects are right
              CLEAR EVENTS 

         OTHERWISE && Some object cause error
             =MESSAGEBOX(m.poBM.uResult.GetMessage()) 
             m.poBM.uResult.aList(1, 1).SetFocus() && Activate first object from list
             m.poBM.uResult.Clear() && Clear result
      ENDCASE
      RELEASE m.poBM && Release broadcast message object
   ENDPROC

ENDDEFINE
```

[Full example](./src/simply_broadcast_message.prg)
