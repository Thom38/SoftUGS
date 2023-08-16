; =============================================================
; ==                                                         ==
; == Routines pour la gestion des des messages affich�s      ==
; ==                                                         ==
; ==   - Encodeur -> Choix du message � �diter               ==
; ==   - Menu     -> Validation du choix du message � �diter ==
; ==   - StandBy  -> Retour au menu pr�c�dent                ==
; ==                                                         ==
; =============================================================

MenuMessages:

WaitMenuMessages:
		sbis	PinMenu,SwitchMenu					; Avant de passer � la suite,
		rjmp	WaitMenuMessages					; On attend le relachement du bouton de menu

; OK, on a l�ch� le bouton

		ldi		Work,0								; D�but de premi�re ligne
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuMessagesSetup*2)
		ldi		ZL,LOW(MenuMessagesSetup*2)
		call	DisplayAfficheChaine

		ldi		Work,0x40							; on se place
		call	DisplayPlaceCurseur					; sur la seconde ligne de l'afficheur
		ldi		ZH,HIGH(MenuMessageWelcome*2)
		ldi		ZL,LOW(MenuMessageWelcome*2)
		call	DisplayAfficheChaine				; affiche le "message" de l'encodeur 
		call	DisplayArrow						; et les fl�ches de l'encodeur

		clr		MenuReg1

LoopLevelM0:

		call 	LectureEncodeur						; Lecture de l'encodeur
		sbrs	StatReg1,FlagIncremente				; doit-on incr�menter
		sbrc	StatReg1,FlagDecremente				; ou d�cr�menter ?
		rjmp	ChangeMessageMenu					; l'un des deux...

		sbis	PinSwitchMC,SwitchMC				; Un appui sur le bouton d'annulation pour sortir ?
		rjmp	ExitMessageMenu						; Oui, alors on y va

		sbic	PinMenu,SwitchMenu					; Un appui sur Menu ?
		rjmp 	LoopLevelM0							; Non, on boucle

		call	Attendre							; On attend un peu...
		sbic	PinMenu,SwitchMenu					; Menu  toujours appuy� ?
		rjmp 	LoopLevelM0							; Non, on boucle

		rjmp	WhatMessageMenuToEnter				; sinon on entre dans le menu de config qu'il faut
			
ChangeMessageMenu:

		sbrc	StatReg1,FlagIncremente				; regarde dans quel sens allait l'encodeur
		rjmp	IncMessMenuReg1						; Vers le haut ?
		sbrc	StatReg1,FlagDecremente				; 
		rjmp	DecMessMenuReg1						; vers le bas ?
		rjmp	LoopLevelD0							; Aucun des deux, alors cassos

IncMessMenuReg1:									; Incr�mentation du num�ro de menu
		mov		Work,MenuReg1						; transfert dans un registre imm�diat
		cpi		Work,2								; c'est le dernier menu ?
		brne	DoIncMessMR1						; non, alors on peut incr�menter sans pb

		clr		MenuReg1							; sinon, on le repasse � 0		
		rjmp	AfficheMenuMess0					; et on va afficher la chaine qu'il faut
DoIncMessMR1:
		inc		MenuReg1							; On incr�mente le registre
		rjmp	AfficheMenuMess0					; et on va afficher la chaine qu'il faut

DecMessMenuReg1:									; D�cr�mentation du num�ro de menu
		mov		Work,MenuReg1						; transfert dans un registre imm�diat
		cpi		Work,0								; c'est le dernier menu ?
		brne	DoDecMessMR1						; non, alors on peut d�cr�menter sans pb

		ldi		Work,2
		mov		MenuReg1,Work						; sinon, on le repasse � 2		
		rjmp	AfficheMenuMess0					; et on va afficher la chaine qu'il faut
DoDecMessMR1:
		dec		MenuReg1							; On d�cr�mente le registre

AfficheMenuMess0:									; affiche le menu correspondant au contenu de MenuReg1 (entre 0 et 2)

		cbr		StatReg1,EXP2(FlagIncremente)		; On commence par remettre � 0 les flags de l'encodeur
		cbr		StatReg1,EXP2(FlagDecremente)

		ldi		Work,0x40							; On se place en d�but de seconde ligne
		call	DisplayPlaceCurseur

		mov		Work,MenuReg1						; On met le registre dans un registre imm�diat

TestMenuMessWelcome:

		cpi		Work,0								; C'est 0 ?
		brne	TestMenuMessBye						; Nan...

		ldi		ZH,HIGH(MenuMessageWelcome*2)		; Oui, c'est 0
		ldi		ZL,LOW(MenuMessageWelcome*2)
		call	DisplayAfficheChaine				; Affiche la premi�re chaine de setup
		call	DisplayArrow						; et les fl�ches de l'encodeur
		rjmp	LoopLevelM0							; et on continue la boucle

TestMenuMessBye:

		cpi		Work,1								; C'est 1 ?
		brne	TestMenuMessMute					; Nan...

		ldi		ZH,HIGH(MenuMessageBye*2)			; Oui, c'est 1
		ldi		ZL,LOW(MenuMessageBye*2)
		call	DisplayAfficheChaine				; Affiche la premi�re chaine de setup
		call	DisplayArrow						; et les fl�ches de l'encodeur
		rjmp	LoopLevelM0							; et on continue la boucle

TestMenuMessMute:

		ldi		ZH,HIGH(MenuMessageMute*2)			; Ici, c'est obligatoirement 2
		ldi		ZL,LOW(MenuMessageMute*2)
		call	DisplayAfficheChaine				; Affiche la premi�re chaine de setup
		call	DisplayArrow						; et les fl�ches de l'encodeur
		rjmp	LoopLevelM0							; et on continue la boucle

WhatMessageMenuToEnter:

		mov		Work,MenuReg1						; Transfert en imm�diat
		cpi		Work,0								; si c'est 0
		breq	EnterMenuMessageWelcome				; on va triturer le message d'accueil
		cpi		Work,1								; si c'est 1
		breq	EnterMenuMessageBye					; on va triturer le message de bye
		cpi		Work,2								; si c'est 2
		breq	EnterMenuMessageMute				; on va triturer le message de mute

EnterMenuMessageWelcome:							; Le message d'accueil

		call 	Attendre							; On attend un peu
		sbic	PinMenu,SwitchMenu					; Un vrai appui sur le bouton de menu ?
		rjmp	TestMenuMessWelcome					; Sinon,on revient au bon endroit

		ldi		Work,0								; Valeur � 0 -> Welcome
		mov		MenuReg1,Work
		call	MenuEditeMessage					; On y va

		ldi		Work,0								; Pour le retour -> D�but de premi�re ligne
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuMessagesSetup*2)
		ldi		ZL,LOW(MenuMessagesSetup*2)
		call	DisplayAfficheChaine

		ldi		Work,0x40							; on se place
		call	DisplayPlaceCurseur					; sur la seconde ligne de l'afficheur

		clr		Work
		mov		MenuReg1,Work						; On remet la bonne valeur dans MenuReg1
		rjmp	TestMenuMessWelcome					; et on revient au bon endroit

EnterMenuMessageBye:								; Le message de fin

		call 	Attendre							; On attend un peu
		sbic	PinMenu,SwitchMenu					; Un vrai appui sur le bouton de menu ?
		rjmp	TestMenuMessBye						; Sinon,on revient au bon endroit

		ldi		Work,1								; Valeur � 1 -> ByeBye
		mov		MenuReg1,Work
		call	MenuEditeMessage					; On y va

		ldi		Work,0								; Pour le retour -> D�but de premi�re ligne
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuMessagesSetup*2)
		ldi		ZL,LOW(MenuMessagesSetup*2)
		call	DisplayAfficheChaine

		ldi		Work,0x40							; on se place
		call	DisplayPlaceCurseur					; sur la seconde ligne de l'afficheur

		ldi		Work,1
		mov		MenuReg1,Work						; On remet la bonne valeur dans MenuReg1
		rjmp	TestMenuMessBye						; et on revient au bon endroit

EnterMenuMessageMute:								; Le message de Mute

		call 	Attendre							; On attend un peu
		sbic	PinMenu,SwitchMenu					; Un vrai appui sur le bouton de menu ?
		rjmp	TestMenuMessMute					; Sinon,on revient au bon endroit

		ldi		Work,2								; Valeur � 2 -> Mute
		mov		MenuReg1,Work
		call	MenuEditeMessage					; On y va

		ldi		Work,0								; Pour le retour -> D�but de premi�re ligne
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuMessagesSetup*2)
		ldi		ZL,LOW(MenuMessagesSetup*2)
		call	DisplayAfficheChaine

		ldi		Work,0x40							; on se place
		call	DisplayPlaceCurseur					; sur la seconde ligne de l'afficheur

		ldi		Work,2
		mov		MenuReg1,Work						; On remet la bonne valeur dans MenuReg1
		rjmp	TestMenuMessMute					; et on revient au bon endroit

ExitMessageMenu:
		call 	Attendre							; On attend pour le d�bounce
		sbic	PinSwitchMC,SwitchMC				; C'est un vrai appui sur le bouton d'annulation pour sortir ?
		rjmp	LoopLevelM0							; Non, fausse arlette et on replonge dans la boucle

WaitBeforeExitMessageMenu:
		sbis	PinSwitchMC,SwitchMC				; Petit test habituel pour ne pas effectuer
		rjmp	WaitBeforeExitMessageMenu			; des sorties de menu en cascade

		ret											; on se casse de ce menu

; ===========================================================
; ==                                                       ==
; == Edition du libell�                                    ==
; ==                                                       ==
; ==    - L'encodeur change de position de caract�re       ==
; ==      ou apr�s un appui sur "menu", change le code     ==
; ==      ASCII du caract�re                               ==
; ==                                                       ==
; ==    - Appui court sur le bouton "Menu" :               ==
; ==      Choix du caract�re � �diter                      ==
; ==      Validation du caract�re �dit�                    ==
; ==                                                       ==
; ==    - Appui long (> 1s) sur le bouton "Menu" :         ==
; ==      Validation du nouveau libell�                    ==
; ==                                                       ==
; ==    - Le bouton d'annulation :                         ==
; ==      En modification d'un caract�re, annulation de    ==
; ==      la saisie courante du caract�re                  ==
; ==      Sinon, annulation de l'�dition du libell�        ==
; ==      et retour au libell� d'origine                   ==
; ==                                                       ==
; ===========================================================

MenuEditeMessage:

WaitMenuEntreeLibelle:
		sbis	PinMenu,SwitchMenu					; Avant de passer � la suite,
		rjmp	WaitMenuEntreeLibelle				; On attend le relachement du bouton de menu

; -- Bouton rel�ch�, on continue
; -- On affiche d'abord le message, 
; -- Puis on recopie en RAM le libell� � �diter contenu en EEPROM

		ldi		Work,0								; Curseur au d�but de l'afficheur
		call	DisplayPlaceCurseur

		mov		Work3,MenuReg1						; Passage dans un registre imm�diat		

		cpi		Work3,0								; Message de bienvenue ?
		brne	TesteBye							; nan, alors c'est le byebye ?
	
		ldi		Work,EE_Welcome_Hi					; Adresse du message en EEPROM
		out		EEARH,Work							; 	Adresse Haute
		ldi		Work,EE_Welcome_Lo					; 	et adresse basse
		out		EEARL,Work
		rjmp	MenuCopyMessage

TesteBye:
		cpi		Work3,1								; Message d'adieu ?
		brne	TesteMute							; nan, alors c'est le mute 
	
		ldi		Work,EE_Bye_Hi						; Adresse en EEPROM
		out		EEARH,Work					
		ldi		Work,EE_Bye_Lo						; du message...
		out		EEARL,Work
		rjmp	MenuCopyMessage

TesteMute:											; C'est donc le message de Mute
		ldi		Work,EE_Mute_Hi						; Adresse en EEPROM
		out		EEARH,Work					
		ldi		Work,EE_Mute_Lo						; du message...
		out		EEARL,Work
		rjmp	MenuCopyMessage

MenuCopyMessage:
		ldi		ZH,RAM_Message_H					; Adresse RAM o� stocker le message
		ldi		ZL,RAM_Message_L

		ldi		Count1,0							; 40 caract�res � lire

BoucleMenuCopyMessage:
		out		EEARL,Work							; Adresse � atteindre en EEPROM
	    sbi		EECR,EERE							; Pr�pare l'EEPROM � la lecture
		in		Char,EEDR							; lit la valeur en EEPROM et la met dans le registre Work

		st		Z+,Char								; et stocke la valeur en RAM, avec incr�mentation automatique de l'adresse

		inc		Work								; Incr�mente l'adresse en EEPROM
		inc		Count1								; Incr�mente le compteur de caract�res
		cpi		Count1,(2*DisplaySize)+2			; C'est le dernier caract�re des 2 lignes (2 fois la taille du Display plus 1 octet de terminaison de cha�ne ?)
		brne	BoucleMenuCopyMessage				; nan, alors on boucle

		clr 	Work								; On remet l'adresse haute de l'EEPROM
		out		EEARH,Work							; � sa valeur initiale

		ldi		ZH,RAM_Message_H					; On affiche le message
		ldi		ZL,RAM_Message_L					; stock� � l'emplacement d'�dition
		call	DisplayAfficheChaineRAM

; -- Normalement l'affichage est bon et n'a pas chang�
; -- On fait juste appara�tre le curseur

		ldi		Work,0								; On replace le curseur
		call	DisplayPlaceCurseur					; au d�but du libell�
		call	DisplayCursorBlock					; On affiche le curseur en bloc
													; et on est pr�t pour l'�dition
		clr		MenuReg2							; Registre qui va servir � conna�tre le num�ro du caract�re

; -- Boucle pour l'�dition --

LoopMessage:

		call 	LectureEncodeur						; Lecture de l'encodeur
		sbrs	StatReg1,FlagIncremente				; doit-on incr�menter
		sbrc	StatReg1,FlagDecremente				; ou d�cr�menter ?
		rjmp	ChangeMessCurrentLetter				; l'un des deux en tout cas...

		sbis	PinSwitchMC,SwitchMC				; Un appui sur le bouton d'annulation pour sortir sans sauver ?
		rjmp	ExitMenuEntreeMessNoSave			; 	- Oui, alors on y va

		sbic	PinMenu,SwitchMenu					; Un appui sur Menu ?
		rjmp 	LoopMessage							; Non, on boucle

		clr		Work								; Sinon on va lancer le timer pour savoir si on a un appui long
		out		TCCR1B,Work							; Arr�te le timer aucazou
		sbr		StatReg2,EXP2(FlagWait)				

		ldi     Work,UneSecHi						; Et c'est parti pour 1 s
		out     TCNT1H,Work							
		ldi		Work,UneSecLo
		out     TCNT1L,Work
		ldi     Work,TimerDiv		        		; On d�marre le Timer avec CK/1024
		out     TCCR1B,Work                     	; et il va compter pendant � peu 1 seconde avant l'overflow

; -- Maintenant on va boucler en attendant le rel�chement du bouton Menu

WaitMenuMess:
		sbrs	StatReg2,FlagWait					; Le flag d"attente est pass� � z�ro ?
		rjmp	ExitMenuEntreeMess					; 	- oui -> On sauve d'office
		sbis	PinMenu,SwitchMenu					; 	- non, mais menu toujours appuy� ?
		rjmp 	WaitMenuMess						; Oui, on boucle
													; On a rel�ch� le bouton menu
		sbrc	StatReg2,FlagWait					; Le flag de wait est-il revenu � 0 (La seconde est �coul�e) ?
		rjmp 	EditMessCurrentChar	 				; 	- Nan, pas de timeout, alors on change le caract�re � �diter
		rjmp	ExitMenuEntreeMess					;   - Oui, alors on va sauver le nouveau message

; -- On veut �diter le caract�re s�lectionn� (Appui court sur Menu)

EditMessCurrentChar:								; On veut �diter un caract�re particulier

		sbis	PinMenu,SwitchMenu					; petit test habituel pour ne pas effectuer
		rjmp	EditMessCurrentChar					; des sorties de menu en cascade (Bouton Menu rel�ch� ?)

		clr		Work
		out		TCCR1B,Work							; On arr�te le timer qu'est en train de tourner 
		cbr		StatReg2,EXP2(FlagWait)				; et on r�initialise le flag d'attente

		ldi		ZH,RAM_Message_H
 		ldi		ZL,RAM_Message_L 					; On se replace au d�but de la chaine en RAM
		add		ZL,MenuReg2							; Offset pour aller sur le bon caract�re
		ld		Char,Z								; On r�cup�re le code du caract�re

		ldi		ZH,RAM_Start						; On va stocker le carat�re �dit� en RAM
		ldi		ZL,RAM_TempChar						; pour le r�cup�rer en cas d'annulation
		st		Z,Char

		call	DisplayCursorOn						; Passe le curseur en soulign�, c'est plus lisible 

LoopMessChar:

		call 	LectureEncodeur						; Lecture de l'encodeur
		sbrs	StatReg1,FlagIncremente				; doit-on incr�menter
		sbrc	StatReg1,FlagDecremente				; ou d�cr�menter ?
		rjmp	ChangeMessLetter					; l'un des deux...

		sbis	PinSwitchMC,SwitchMC				; Un appui sur le bouton d'annulation pour sortir ?
		rjmp	ExitLoopMessChar					; 	- Oui, alors on y va

		sbic	PinMenu,SwitchMenu					; Un appui sur Menu ?
		rjmp 	LoopMessChar						; Non, on boucle

		call	Attendre							; On attend un peu...
		sbic	PinMenu,SwitchMenu					; Menu toujours appuy� ?
		rjmp 	LoopMessChar						; Non, on boucle

		rjmp 	SaveMessCurrentChar					; Change de caract�re � �diter

; -- Finalement, on ne change pas le caract�re �dit� (Appui sur Standby/On)

ExitLoopMessChar:									; On annule la modif du caract�re

		sbis	PinSwitchMC,SwitchMC				; Petite boucle
		rjmp	ExitLoopMessChar					; de debounce r�glementaire

		ldi		ZH,RAM_Start						; On va lire le carat�re �dit� en RAM
		ldi		ZL,RAM_TempChar						; pour le r�cup�rer 
		ld		Char,Z

		ldi		ZH,RAM_Message_H
 		ldi		ZL,RAM_Message_L 					; On se replace au d�but de la chaine en RAM
		add		ZL,MenuReg2							; Offset pour aller sur le bon caract�re
		st		Z,Char								; On remet le bon code du caract�re

		call	MessRelocateCursor
		call	DisplayWriteChar
		call	MessRelocateCursor

		call	DisplayCursorBlock					; On remet le curseeur en bloc

		rjmp	LoopMessage							; et on reboucle

; -- Sauvegarde du caract�re �dit� (Appui sur Menu) --

SaveMessCurrentChar:								; Pas vraiment de sauvegarde car tout est en RAM automatiquement

		sbis	PinMenu,SwitchMenu					; Petite boucle
		rjmp	SaveMessCurrentChar					; de debounce r�glementaire

		call	DisplayCursorBlock					; Repasse le curseur en bloc

		call 	MessRelocateCursor					; Replace le curseur � la bonne position

		rjmp	LoopMessage

; -- Change la position du curseur pour changer de caract�re dans le message --

ChangeMessCurrentLetter:

		sbrc	StatReg1,FlagIncremente				; regarde dans quel sens allait l'encodeur
		rjmp	IncMessCurrentLetter				; Vers le haut ?
		sbrc	StatReg1,FlagDecremente				; 
		rjmp	DecMessCurrentLetter				; vers le bas ?
		rjmp	LoopMessage							; Aucun des deux, alors cassos

IncMessCurrentLetter:
		ldi		Work,DisplaySize-1					; On est arriv�
		cp		MenuReg2,Work						; au dernier caract�re  de la ligne ?
		breq	GoToMessFirstCharLine2				; 	- Oui, alors on repasse au premier

		ldi		Work,2*DisplaySize
		cp		MenuReg2,Work
		breq	GoToMessFirstCharLine1

		inc		MenuReg2							; 	- Non, alors on incr�mente	
		rjmp	GotoMessNextLetter					; 	et on shifte le curseur

GoToMessFirstCharLine1:
		clr		MenuReg2							
		rjmp	GotoMessNextLetter					; 	et on shifte le curseur

GoToMessFirstCharLine2:
		ldi		Work,DisplaySize+1
		mov		MenuReg2,Work							
		rjmp	GotoMessNextLetter					; 	et on shifte le curseur

DecMessCurrentLetter:
		ldi		Work,0								; On est arriv�
		cp		MenuReg2,Work						; au premier caract�re ?
		breq	GoToMessLastCharLine2				; 	- Oui, alors on repasse au dernier

		ldi		Work,DisplaySize+1					; Si on est au d�but de la seconde ligne
		cp		MenuReg2,Work
		breq	GoToMessLastCharLine1

		dec		MenuReg2							; 	- Non, alors on d�cr�mente	
		rjmp	GotoMessNextLetter					; 	  et on shifte le curseur

GoToMessLastCharLine1:								; Dernier caract�re de la seconde ligne
		ldi		Work,DisplaySize-1
		mov		MenuReg2,Work							
		rjmp	GotoMessNextLetter					; 	et on shifte le curseur

GoToMessLastCharLine2:								; Dernier caract�re de la seconde ligne
		ldi		Work,2*DisplaySize
		mov		MenuReg2,Work							

GotoMessNextLetter:
		ldi		Work,DisplaySize+1
		cp		MenuReg2,Work
		brsh	MenuMessCharL2

		mov		Work,MenuReg2						; et d�calage pour aller � la bonne place
		rjmp	MenuMessLocChar

MenuMessCharL2:
		mov		Work,MenuReg2
		subi	Work,(DisplaySize+1)
		ldi		Work1,0x40
		add		Work,Work1

MenuMessLocChar:
		call	DisplayPlaceCurseur

		cbr		StatReg1,EXP2(FlagIncremente)		; Remet les flags de l'encodeur
		cbr		StatReg1,EXP2(FlagDecremente)		; � z�ro
		rjmp	LoopMessage							; Mission termin�e, on s'en va
		
; --- Change le code ascii du caract�re (0 � 255) ---

ChangeMessLetter:
		ldi		ZH,RAM_Message_H
 		ldi		ZL,RAM_Message_L 					; On se replace au d�but de la chaine en RAM
		add		ZL,MenuReg2							; et on se d�cale pour tomber sur le bon caract�re
		ld		Char,Z								; On r�cup�re le code du caract�re

		lds		Work,TCCR3B							; si le timer 3 ne tourne pas
		andi	Work,0b00000111						; on lance le clignotement de la LED On
		cpi		Work,0								; car on a modifi� la valeur qui �tait stock�e
		brne	MenuTesteMessLetter						
		call	LanceClignotementLED

MenuTesteMessLetter:
		sbrc	StatReg1,FlagIncremente				; regarde dans quel sens allait l'encodeur
		rjmp	IncMenuMessASCII					; Vers le haut ?
		sbrc	StatReg1,FlagDecremente				; 
		rjmp	DecMenuMessASCII					; vers le bas ?
		rjmp	LoopMessChar						; Aucun des deux, alors cassos

IncMenuMessASCII:									; Incr�mentation du num�ro de menu
		cpi		Char,CodeCharMax					; dernier caract�re autoris� ?
		brne	DoIncMenuMessASCII					; non, alors on peut incr�menter sans pb

		ldi		Char,CodeCharMin					; sinon, on le repasse au code Ascii Min		
		rjmp	MenuAfficheMessNewChar				; et on va afficher le nouveau caract�re

DoIncMenuMessASCII:
#if defined(CRYSTALFONTZ)
		inc		Char								; On incr�mente le registre
#else
		call	TestDisplayIncASCII					; Cherche les caract�res autoris�s
#endif
		rjmp	MenuAfficheMessNewChar

DecMenuMessASCII:									; D�cr�mentation du code ascii
		cpi		Char,CodeCharMin					; c'est le plus petit code ascii autoris� ?
		brne	DoDecMenuMessASCII					; non, alors on peut d�cr�menter sans pb

		ldi		Char,CodeCharMax					; sinon, on le repasse au code ascii max	
		rjmp	MenuAfficheMessNewChar					; et on va afficher la chaine qu'il faut

DoDecMenuMessASCII:
#if defined(CRYSTALFONTZ)
		dec		Char								; On d�cr�mente le registre
#else
		call	TestDisplayDecASCII					; Cherche les caract�res autoris�s
#endif

MenuAfficheMessNewChar:								; affiche nouveau caract�re et le stocke en RAM

		cbr		StatReg1,EXP2(FlagIncremente)		; On commence par remettre � 0 les flags de l'encodeur
		cbr		StatReg1,EXP2(FlagDecremente)

		ldi		ZH,RAM_Message_H
 		ldi		ZL,RAM_Message_L 					; On se replace au d�but de la chaine en RAM
		add		ZL,MenuReg2							; et on se d�cale pour pointer sur le bon
		st		Z,Char								; Stockage en RAM

		ldi		Work,DisplaySize+1
		cp		MenuReg2,Work
		brsh	MenuMessLocateCharL2

		mov		Work,MenuReg2						; et d�calage pour aller � la bonne place
		rjmp	MenuMessChangeChar

MenuMessLocateCharL2:
		mov		Work,MenuReg2
		subi	Work,(DisplaySize+1)
		ldi		Work1,0x40
		add		Work,Work1

MenuMessChangeChar:
		push	Work								; Sauvegarde la position du caract�re
		call	DisplayPlaceCurseur					; met le curseur en position
		call	DisplayWriteChar					; Ecrit le caract�re

		pop		Work								; et remet le curseur au bon endroit
		call	DisplayPlaceCurseur					; car normalement il avance automatiquement

		rjmp	LoopMessChar						; et on reboucle

; -- Sortie avec recopie en EEPROM du libell� modifi� qui est en RAM

ExitMenuEntreeMess:
		call	DisplayCursorOff					; On fait dispara�tre le curseur 
		call	ArreteClignotementLED				; Au cazo�, on rallume la LED de On/StandBy

		ldi		Work,SaveLong						; Fixe le temps d'affichage du prochain message
		call	AfficheSavingMessage				; Affiche le message de sauvegarde

; -- Sauvegarde du nouvel intitul� en EEPROM

		mov		Work3,MenuReg1						; De quel message s'agit-il
		
		cpi		Work3,0								; Welcome ?
		brne	MenuMessEEBye						; nan -> Teste encore
													; oui -> Positionne l'EEPROM
		ldi		Work,EE_Welcome_Hi					; Adresse en EEPROM
		out		EEARH,Work					
		ldi		Work,EE_Welcome_Lo					; du message...
		out		EEARL,Work
		rjmp	MenuMessEESave

MenuMessEEBye:
		cpi		Work3,1								; ByeBye ?
		brne	MenuMessEEMute						; nan -> Teste encore
													; oui -> Positionne l'EEPROM
		ldi		Work,EE_Bye_Hi						; Adresse en EEPROM
		out		EEARH,Work					
		ldi		Work,EE_Bye_Lo						; du message...
		out		EEARL,Work
		rjmp	MenuMessEESave

MenuMessEEMute:										; C'est alors forc�ment le mute...
		ldi		Work,EE_Mute_Hi						; Adresse en EEPROM
		out		EEARH,Work					
		ldi		Work,EE_Mute_Lo						; du message...
		out		EEARL,Work

MenuMessEESave:

		ldi		ZH,RAM_Message_H
 		ldi		ZL,RAM_Message_L 					; R�cup�re en RAM l'adresse de d�but du libell� qu'on vient d'�diter

		clr 	Count1								; 42 caract�res � r�cup�rer

MenuCopieMessEESave:								

		out		EEARL,Work							; Adresse � atteindre en EEPROM
		ld		Work2,Z+							; on r�cup�re le caract�re dans la RAM, tout en incr�mentant l'adresse RAM

		call	WriteEEProm							; On �crite en EEProm

		inc		Work								; Incr�mente l'adresse en EEPROM
		inc		Count1								; Incr�mente le compteur de caract�res

		cpi		Count1,2*(DisplaySize+1)			; teste si on a fini d'�crire tous les caract�res
		brne	MenuCopieMessEESave					; et boucle si on n'a pas tout �crit

		clr 	Work								; On remet l'adresse haute de l'EEPROM
		out		EEARH,Work							; � sa valeur initiale

; -- On sauvegarde aussi en RAM pour l'affichage

		ldi		ZH,RAM_Start

		mov		Work3,MenuReg1						; De quel message s'agit-il

		cpi		Work3,0								; Welcome ?
		brne	MenuMessRAMBye						; nan -> Teste encore
													; oui -> Positionne l'EEPROM
		ldi		Work,EE_Welcome_Hi					; Adresse en EEPROM
		out		EEARH,Work					
		ldi		Work,EE_Welcome_Lo					; du message...
		out		EEARL,Work
		ldi		ZL,RAM_Welcome_M
		rjmp	MenuMessRAMSave

MenuMessRAMBye:
		cpi		Work3,1								; ByeBye ?
		brne	MenuMessRAMMute						; nan -> Teste encore
													; oui -> Positionne l'EEPROM
		ldi		Work,EE_Bye_Hi						; Adresse en EEPROM
		out		EEARH,Work					
		ldi		Work,EE_Bye_Lo						; du message...
		out		EEARL,Work
		ldi		ZL,RAM_Bye_M
		rjmp	MenuMessRAMSave

MenuMessRAMMute:									; C'est alors forc�ment le mute...
		ldi		Work,EE_Mute_Hi						; Adresse en EEPROM
		out		EEARH,Work					
		ldi		Work,EE_Mute_Lo						; du message...
		out		EEARL,Work
		ldi		ZL,RAM_Mute_M

MenuMessRAMSave:
		clr 	Count1								; 42 caract�res � r�cup�rer
				
MenuCopieMessRAMSave:								
		call	ReadEEProm							; Va lire le contenu de l'EEPROM
													; et r�cup�re la donn�e dans Work2
		st		Z+,Work2							; puis stocke la valeur en RAM, avec incr�mentation automatique de l'adresse

		inc		Work								; Incr�mente l'adresse en EEPROM
		inc		Count1								; Incr�mente le compteur de caract�res

		cpi		Count1,2*(DisplaySize+1)			; teste si on a fini d'�crire tous les caract�res
		brne	MenuCopieMessRAMSave				; et boucle si on n'a pas tout �crit

		clr 	Work								; Sinon, on remet l'adresse haute de l'EEPROM
		out		EEARH,Work							; � sa valeur initiale

MenuMessWaitBeforeReturn:
		sbis	PinMenu,SwitchMenu					; Petite boucle
		rjmp	MenuMessWaitBeforeReturn			; pour �tre s�r qu'on a rel�ch� le bouton de menu

		ret											; et on se casse

ExitMenuEntreeMessNoSave:							; Point d'entr�e pour sortir sans sauver

		sbis	PinSwitchMC,SwitchMC				; On attend la fin d'un �ventuel appui sur le bouton d'annulation
		rjmp	ExitMenuEntreeMessNoSave			; sinon on boucle

		call	DisplayCursorOff					; On fait dispara�tre le curseur 
		call	ArreteClignotementLED				; Au cazo�, on rallume la LED de On/StandBy

		clr 	Work								; On remet l'adresse haute de l'EEPROM
		out		EEARH,Work							; � sa valeur initiale

		ret											; et on se casse de ce menu

; == Positionnement du curseur en fonction du num�ro du caract�re (de 0 � 2*DisplaySize-1)

MessRelocateCursor:
		ldi		Work,DisplaySize+1
		cp		MenuReg2,Work						; Est-on sur la seconde ligne ?
		brsh	MessRelocateTwo						; Oui, alors go

		mov		Work,MenuReg2						; Sur la premi�re ligne, rien � faire
		call	DisplayPlaceCurseur						; on place juste le curseur
		ret											; Bye

MessRelocateTwo:
		mov		Work,MenuReg2						; On fait un offset de DisplaySize sur le num�ro du caract�re
		subi	Work,(DisplaySize+1)
		ldi		Work1,0x40							; et on ajoute 0x40 pour passer sur la seconde ligne
		add		Work,Work1
		call	DisplayPlaceCurseur					; et on finit en pla�ant le curseur
		ret
				

