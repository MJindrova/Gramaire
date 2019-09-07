# Broadcast Message

What is Broadcast Message? Hmm, it's a way, how send message to one or more recipients and process result.
 Recipient can be form, toolbar, textbox, label or `_Screen` object. 

How is realize it? It's a combination of calls `SetAll()` method and `_Assign` method.
 If you don't know what is `SetAll()` method, please read topic "SetAll Method" in VFP help (5.0. 6.0, 7.0, 8.0, 9.0).
 If you don't know what is `_Assign` method, please read topic "Access and Assign Methods" in VFP help (6.0, 7.0, 8.0, 9.0).

## How create it
It's a very simply. 

Define some class derived from textbox.
```
DEFINE CLASS _mytextbox AS textbox
  Name="_mytextbox"

  * Property for sets broadcast message. This property will not be set never!!!
  uBroadcastMessage=.NULL. 
  
  PROCEDURE uBroadcastMessage_ASSIGN
     LPARAMETERS m.luValue
     ?TYPE("m.luValue"), ISNULL(m.luValue), m.luValue
  ENDPROC

ENDDEF
``` 

Add textbox to `_Screen`.
```
_Screen.AddObject("txt1", "_mytextbox")
``` 

And call method `SetAll()` on `_Screen` object.
```
_Screen.SetAll("uBroadcastMessage", _Screen.Caption)
``` 

Result will be.
```
Microsoft Visual FoxPro
``` 


## Examples
1. [Simply Broadcast Message](./simply_broadcast_message.md)
2. [Style Broadcast Message](./style_broadcast_message.md)
3. [Style Broadcast Message - form](./stylef_broadcast_message.md)
4. [Style Broadcast Message - all forms](./styleallforms_broadcast_message.md)
5. [Language Broadcast Message](./language_broadcast_message.md)
6. [Group Broadcast Message](./group_broadcast_message.md)

