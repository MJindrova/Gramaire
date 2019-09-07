_Screen.AddObject("txt1", "_mytextbox")

PRIVATE m.loBM
m.loBM =CREATEOBJECT("_BroadcastMessage")
m.loBM.uType="MUSTBEFILL"

_Screen.SetAll("uBroadcastMessage", m.loBM)
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
_Screen.SetAll("Left", 0)

*Release broadcast message object
m.loBM=.NULL. && Cause method uBroadcastMessage_ASSIGN. WTF?!?
*RELEASE m.loBM && Cause method uBroadcastMessage_ASSIGN. WTF?!?
RETURN



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
* Some textbox class
***************************************************************************
DEFINE CLASS _mytextbox AS textbox
  Name="_mytextbox"

  * Property for sets broadcast message. This property will not be set never!!!
  uBroadcastMessage=.NULL. 
  
  lIsEmptyAllowed=.T. 
  
  PROCEDURE uBroadcastMessage_ASSIGN
     LPARAMETERS m.luValue
     ?TYPE("m.luValue"), ISNULL(m.luValue)
  ENDPROC

ENDDEF


