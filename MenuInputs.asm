; ================================================
; == Le menu pour le le param�trage des entr�es ==
; ================================================

MenuInputs :

WaitMenuInput:
		sbis	PinMenu,SwitchMenu					; Avant de passer � la suite,
		rjmp	WaitMenuInput						; On attend le relachement du bouton de menu

; OK, on a l�ch� le bouton

		ldi		Work,0								; on se place
		call	DisplayPlaceCurseur					; sur la premi�re ligne de l'afficheur
		ldi		ZH,HIGH(MenuInputSetupMessage*2)
		ldi		ZL,LOW(MenuInputSetupMessage*2)
		call	DisplayAfficheChaine				; Et on affiche le premier item du menu

		ldi		Work,0x40							; on se place
		call	DisplayPlaceCurseur					; sur la seconde ligne de l'afficheur
		ldi		ZH,HIGH(MenuInputNoMessage*2)
		ldi		ZL,LOW(MenuInputNoMessage*2)
		call	DisplayAfficheChaine				; affiche le "message" de l'encodeur 
		call	DisplayArrow						; et les fl�ches de l'encodeur

		ldi		Work,0x4B							; Se place � la position
		call	DisplayPlaceCurseur					; o� on �crit le num�ro de l'entr�e
		ldi		Char,'1'
		call	DisplayWriteChar

		clr		MenuReg1

LoopLevelI0:

		call 	LectureEncodeur						; Lecture de l'encodeur
		sbrs	StatReg1,FlagIncremente				; doit-on incr�menter
		sbrc	StatReg1,FlagDecremente				; ou d�cr�menter ?
		rjmp	ChangeInputMenu						; l'un des deux...

		sbis	PinSwitchMC,SwitchMC				; Un appui sur le bouton d'annulation pour sortir ?
		rjmp	ExitInputMenu						; Oui, alors on y va

		sbic	PinMenu,SwitchMenu					; Un appui sur Menu ?
		rjmp 	LoopLevelI0							; Non, on boucle

		call	Attendre							; On attend un peu...
		sbic	PinMenu,SwitchMenu					; Menu  toujours appuy� ?
		rjmp 	LoopLevelI0							; Non, on boucle

		rjmp	WhatInputMenuToEnter				; sinon on entre dans le menu de config qu'il faut
			
ChangeInputMenu:

		sbrc	StatReg1,FlagIncremente				; regarde dans quel sens allait l'encodeur
		rjmp	IncInpMenuReg1						; Vers le haut ?
		sbrc	StatReg1,FlagDecremente				; 
		rjmp	DecInpMenuReg1						; vers le bas ?
		rjmp	LoopLevelI0							; Aucun des deux, alors cassos

IncInpMenuReg1:										; Incr�mentation du num�ro de menu
		mov		Work,MenuReg1						; transfert dans un registre imm�diat
		cpi		Work,(MaxInput+IMM)					; c'est le dernier menu ?
		brne	DoIncInpMR1							; non, alors on peut incr�menter sans pb

		clr		MenuReg1							; sinon, on le repasse � 0		
		rjmp	AfficheMenuInp						; et on va afficher la chaine qu'il faut
DoIncInpMR1:
		inc		MenuReg1							; On incr�mente le registre
		rjmp	AfficheMenuInp						; et on va afficher la chaine qu'il faut

DecInpMenuReg1:										; D�cr�mentation du num�ro de menu
		mov		Work,MenuReg1						; transfert dans un registre imm�diat
		cpi		Work,0								; c'est le dernier menu ?
		brne	DoDecInpMR1							; non, alors on peut d�cr�menter sans pb

		ldi		Work,(MaxInput+IMM)
		mov		MenuReg1,Work						; sinon, on le repasse � MaxInput	
		rjmp	AfficheMenuInp						; et on va afficher la chaine qu'il faut
DoDecInpMR1:
		dec		MenuReg1							; On d�cr�mente le registre

AfficheMenuInp: 									; affiche le menu correspondant au contenu de MenuReg1 (entre 0 et 4)

		cbr		StatReg1,EXP2(FlagIncremente)		; On commence par remettre � 0 les flags de l'encodeur
		cbr		StatReg1,EXP2(FlagDecremente)

TestMenuInp:
		mov		Work,MenuReg1						; On met le registre dans un registre imm�diat

		cpi		Work,MaxInput						; On veut param�trer une des entr�es ?
		brlo	TestMenuInpNb						; Oui, alors on y va
		rjmp	TestMenuInpSup						; Non, alors on s'occupe des autres menus entr�e

TestMenuInpNb:

		ldi		Work,0x40							; on se place
		call	DisplayPlaceCurseur					; sur la seconde ligne de l'afficheur
		ldi		ZH,HIGH(MenuInputNoMessage*2)
		ldi		ZL,LOW(MenuInputNoMessage*2)
		call	DisplayAfficheChaine				; affiche le "message" de l'encodeur 
		call	DisplayArrow						; et les fl�ches de l'encodeur

		ldi		Work,0x4B							; Se place � la position
		call	DisplayPlaceCurseur					; o� on �crit le num�ro de l'entr�e
		mov		Char,MenuReg1
		subi	Char,-49
		call	DisplayWriteChar

		rjmp	LoopLevelI0							; et on continue la boucle

TestMenuInpSup:

		cbr		StatReg1,EXP2(FlagIncremente)		; On commence par remettre � 0 les flags de l'encodeur
		cbr		StatReg1,EXP2(FlagDecremente)

#if defined(BYPASS)
		cpi		Work,(MaxInput+IMM)					; Si c'est le dernier menu,			
		brne	TestMenuInpBypass					; c'est l'entr�e de Bypass qui est concern�e
#endif
		ldi		Work,0x40							; on se place
		call	DisplayPlaceCurseur					; sur la seconde ligne de l'afficheur
		ldi		ZH,HIGH(MenuInputPrefMessage*2)		; Ici, c'est obligatoirement le param�trage de l'entr�e pr�f�r�e
		ldi		ZL,LOW(MenuInputPrefMessage*2)
		call	DisplayAfficheChaine				; Affiche la premi�re chaine de setup
		call	DisplayArrow						; et les fl�ches de l'encodeur
		rjmp	LoopLevelI0							; et on continue la boucle

#if defined(BYPASS)

TestMenuInpBypass:
		ldi		Work,0x40							; on se place
		call	DisplayPlaceCurseur					; sur la seconde ligne de l'afficheur
		ldi		ZH,HIGH(MenuPrefInpBypassMessage*2)	; Message correspondant
		ldi		ZL,LOW(MenuPrefInpBypassMessage*2)
		call	DisplayAfficheChaine				; Affiche la premi�re chaine de setup
		call	DisplayArrow						; et les fl�ches de l'encodeur
		rjmp	LoopLevelI0							; et on continue la boucle
#endif

WhatInputMenuToEnter:

		mov		Work,MenuReg1						; Transfert en imm�diat
		cpi		Work,MaxInput						; si c'est une des entr�es
		brlo	EnterMenuInput						; on s'en occupe
		rjmp	EnterMenuInputSup					; sinon on les autres options

EnterMenuInput:										; on va triturer le menu de l'entr�e

		call 	Attendre							; On attend un peu
		sbic	PinMenu,SwitchMenu					; Un vrai appui sur le bouton de menu ?
		rjmp	TestMenuInp							; Sinon,on revient au bon endroit

		rcall	MenuEntree							; On y va

		ldi		Work,0								; Au retour, on se place
		call	DisplayPlaceCurseur					; sur la premi�re ligne de l'afficheur
		ldi		ZH,HIGH(MenuInputSetupMessage*2)
		ldi		ZL,LOW(MenuInputSetupMessage*2)
		call	DisplayAfficheChaine				; affiche le "message" de l'encodeur 

;		clr		Work
;		mov		MenuReg1,Work						; On remet la bonne valeur dans MenuReg1
		rjmp	TestMenuInp							; et on revient au bon endroit

EnterMenuInputSup:									; Autres options des entr�es
#if defined(BYPASS)
		cpi		Work,(MaxInput+IMM)					; Si c'est plus de MaxInput			
		brne	TestMenuInpPrefBypass				; c'est l'entr�e de Bypass qui est concern�e
#endif

EnterMenuPrefInput:									; sinon, on va triturer le menu de l'entr�e � l'allumage

		call 	Attendre							; On attend un peu
		sbic	PinMenu,SwitchMenu					; Un vrai appui sur le bouton de menu ?
		rjmp	TestMenuInpSup						; Sinon,on revient au bon endroit

		rcall	MenuStartInput						; On y va

		ldi		Work,0								; Au retour, on se place
		call	DisplayPlaceCurseur					; sur la premi�re ligne de l'afficheur
		ldi		ZH,HIGH(MenuInputSetupMessage*2)
		ldi		ZL,LOW(MenuInputSetupMessage*2)
		call	DisplayAfficheChaine				; affiche le "message" de l'encodeur 

		ldi		Work,(MaxInput+IMM)
		mov		MenuReg1,Work						; On remet la bonne valeur dans MenuReg1
		rjmp	TestMenuInpSup						; et on revient au bon endroit

#if defined(BYPASS)
TestMenuInpPrefBypass:								; c'est l'entr�e de Bypass qui est concern�e

		call 	Attendre							; On attend un peu
		sbic	PinMenu,SwitchMenu					; Un vrai appui sur le bouton de menu ?
		rjmp	TestMenuInpSup						; Sinon,on revient au bon endroit

		rcall	MenuBypassInput						; On y va

		ldi		Work,0								; Au retour, on se place
		call	DisplayPlaceCurseur					; sur la premi�re ligne de l'afficheur
		ldi		ZH,HIGH(MenuInputSetupMessage*2)
		ldi		ZL,LOW(MenuInputSetupMessage*2)
		call	DisplayAfficheChaine				; affiche le "message" de l'encodeur 

		ldi		Work,(MaxInput)
		mov		MenuReg1,Work						; On remet la bonne valeur dans MenuReg1
		rjmp	TestMenuInpSup						; et on revient au bon endroit

#endif

ExitInputMenu:
		call 	Attendre							; On attend pour le d�bounce
		sbic	PinSwitchMC,SwitchMC				; C'est un vrai appui sur le bouton d'annulation pour sortir ?
		rjmp	LoopLevelI0							; Non, fausse arlette et on replonge dans la boucle

WaitBeforeExitInputMenu:
		sbis	PinSwitchMC,SwitchMC				; petit test habituel pour ne pas effectuer
		rjmp	WaitBeforeExitInputMenu				; des sorties de menu en cascade

		ret											; on se casse de ce menu

; =========================================================
; == Le Menu de configuration pour une entr�e quelconque ==
; == Le num�ro de l'entr�e consid�r�e est dans MenuReg1  ==
; ==                                                     ==
; ==    - Navigation entre les param�tres par l'encodeur ==
; ==    - Entr�e dans un sous-menu par le bouton Menu    ==
; ==    - Remont�e au niveau sup�rieur par "StandBy/on"  ==
; =========================================================

MenuEntree:

WaitMenuEntree:
		sbis	PinMenu,SwitchMenu					; Avant de passer � la suite,
		rjmp	WaitMenuEntree						; On attend le relachement du bouton de menu

; Bouton rel�ch�, on continue

		ldi		Work,0								; on se place
		call	DisplayPlaceCurseur					; sur la premi�re ligne de l'afficheur
		ldi		ZH,HIGH(MenuInputNbParam*2)
		ldi		ZL,LOW(MenuInputNbParam*2)
		call	DisplayAfficheChaine				; affiche le "message" de l'encodeur 

		ldi		Work,9								; Le num�ro de l'entr�e
		call 	DisplayPlaceCurseur					; est affich� en 10�me position
		mov		Char,MenuReg1						; On passe le N� de l'entr�e
		subi	Char,-49							; en ASCII
		call	DisplayWriteChar					; et on l'affiche

		ldi		Work,0x40							; on se place
		call	DisplayPlaceCurseur					; sur la seconde ligne de l'afficheur
		ldi		ZH,HIGH(MenuInputName*2)
		ldi		ZL,LOW(MenuInputName*2)
		call	DisplayAfficheChaine				; Et on affiche le premier item du menu
		call	DisplayArrow

		clr 	MenuReg2

LoopLevelI1:
		call 	LectureEncodeur						; Lecture de l'encodeur
		sbrs	StatReg1,FlagIncremente				; doit-on incr�menter
		sbrc	StatReg1,FlagDecremente				; ou d�cr�menter ?
		rjmp	ChangeInputMenuL1					; l'un des deux...

		sbis	PinSwitchMC,SwitchMC				; Un appui sur le bouton d'annulation pour sortir ?
		rjmp	ExitEntreeMenu						; Oui, alors on y va

		sbic	PinMenu,SwitchMenu					; Un appui sur Menu ?
		rjmp 	LoopLevelI1							; Non, on boucle

		call	Attendre							; On attend un peu...
		sbic	PinMenu,SwitchMenu					; Menu  toujours appuy� ?
		rjmp 	LoopLevelI1							; Non, on boucle

		rjmp	WhatInputMenuToEnterL1				; sinon on entre dans le menu de config qu'il faut
			
ChangeInputMenuL1:
		sbrc	StatReg1,FlagIncremente				; regarde dans quel sens allait l'encodeur
		rjmp	IncInpMenuReg2						; Vers le haut ?
		sbrc	StatReg1,FlagDecremente				; 
		rjmp	DecInpMenuReg2						; vers le bas ?
		rjmp	LoopLevelI1							; Aucun des deux, alors cassos

IncInpMenuReg2:										; Incr�mentation du num�ro de menu
		mov		Work,MenuReg2						; transfert dans un registre imm�diat
		cpi		Work,4								; c'est le dernier menu ?
		brne	DoIncInpMR2							; non, alors on peut incr�menter sans pb

		clr		MenuReg2							; sinon, on le repasse � 0		
		rjmp	AfficheMenuInp1						; et on va afficher la chaine qu'il faut

DoIncInpMR2:
#ifndef	BYPASS
		mov		Work2,MenuReg1
		cpi		Work2,MaxInput-1					; On est sur l'entr�e suppl�mentaire ?
		brne	DoIncTestInpMR1
		cpi		Work,0								; Est-on (en l'absence de bypass) juste avant le menu de type RCA/XLR ?
		brne	DoIncTestInpMR1
		ldi		Work,2								; Sinon, on saute cet item de menu
		mov		MenuReg2,Work						; 
		rjmp	AfficheMenuInp1
#endif

DoIncTestInpMR1:
		cpi		Work,1								; Est-on juste avant le param�tre de volume + 6dB ? 
		brne	ReallyIncInpMR2						; Non, on incr�mente sans pb

		ldi		ZH,RAM_Start						; oui, alors...
		ldi		ZL,RAM_BalIn1						; On va v�rifier que l'entr�e en question est asym�trique
		add		ZL,MenuReg1							; Shifte pour pointer au bon endroit dans la RAM
		ld		Work2,Z								; et r�cup�re la valeur dans Work2
		cpi		Work2,0								; Si on n'a pas z�ro, on est asym�trique,
		brne	ReallyIncInpMR2						; et on peut passer au menu suivant

		ldi		Work,3								; Sinon, on saute cet item de menu
		mov		MenuReg2,Work						; 
		rjmp	AfficheMenuInp1

ReallyIncInpMR2:
		inc		MenuReg2							; On incr�mente le registre
		rjmp	AfficheMenuInp1						; et on va afficher la chaine qu'il faut

DecInpMenuReg2:										; D�cr�mentation du num�ro de menu
		mov		Work,MenuReg2						; transfert dans un registre imm�diat
		cpi		Work,0								; c'est le dernier menu ?
		brne	DoDecInpMR2							; non, alors on peut d�cr�menter sans pb

		ldi		Work,4
		mov		MenuReg2,Work						; sinon, on le repasse � 2		
		rjmp	AfficheMenuInp1						; et on va afficher la chaine qu'il faut

DoDecInpMR2:
#ifndef	BYPASS
		mov		Work2,MenuReg1
		cpi		Work2,MaxInput-1					; On est sur l'entr�e suppl�mentaire ?
		brne	DoDecTestInpMR1
		cpi		Work,2								; Est-on (en l'absence de bypass) juste avant le param�tre de volume + 6dB ?
		brne	DoDecTestInpMR1
		clr		MenuReg2						; 
		rjmp	AfficheMenuInp1
#endif

DoDecTestInpMR1:
		cpi		Work,3								; Est-on juste avant le param�tre de volume + 6dB ? 
		brne	ReallyDecInpMR2						; Non, on incr�mente sans pb

		
		ldi		ZH,RAM_Start						; oui, alors...
		ldi		ZL,RAM_BalIn1						; On va v�rifier que l'entr�e en question est asym�trique
		add		ZL,MenuReg1							; Shifte pour pointer au bon endroit dans la RAM
		ld		Work2,Z								; et r�cup�re la valeur dans Work2
		cpi		Work2,0								; Si on n'a pas z�ro, on est asym�trique, et on peut passer au menu suivant
		brne	ReallyDecInpMR2						; et on peut passer au menu suivant

		ldi		Work,1								; Sinon, on saute cet item de menu
		mov		MenuReg2,Work						; 
		rjmp	AfficheMenuInp1

ReallyDecInpMR2:
		dec		MenuReg2							; On d�cr�mente le registre

AfficheMenuInp1:									; affiche le menu correspondant au contenu de MenuReg1 (entre 0 et 4)

		cbr		StatReg1,EXP2(FlagIncremente)		; On commence par remettre � 0 les flags de l'encodeur
		cbr		StatReg1,EXP2(FlagDecremente)

		ldi		Work,0x40							; on se place
		call	DisplayPlaceCurseur					; sur la seconde ligne de l'afficheur
		mov		Work,MenuReg2						; On met le registre dans un registre imm�diat

TestMenuInputName:

		cpi		Work,0								; C'est 0 ?
		brne	TestMenuInputType					; Nan...

		ldi		ZH,HIGH(MenuInputName*2)
		ldi		ZL,LOW(MenuInputName*2)
		call	DisplayAfficheChaine				; Et on affiche le premier item du menu
		call	DisplayArrow

		rjmp	LoopLevelI1							; et on continue la boucle

TestMenuInputType:

		cpi		Work,1								; C'est 1 ?
		brne	TestMenuInput6dB					; Nan...

		ldi		ZH,HIGH(MenuInputType*2)			; Oui, c'est 1
		ldi		ZL,LOW(MenuInputType*2)
		call	DisplayAfficheChaine				; Affiche la premi�re chaine de setup
		call	DisplayArrow

		rjmp	LoopLevelI1							; et on continue la boucle

TestMenuInput6dB:

		cpi		Work,2								; C'est 2 ?
		brne	TestMenuInputVol					; Nan...

		ldi		ZH,HIGH(MenuInput6dB*2)				; Oui, c'est 2
		ldi		ZL,LOW(MenuInput6dB*2)
		call	DisplayAfficheChaine				; Affiche la premi�re chaine de setup
		call	DisplayArrow

		rjmp	LoopLevelI1							; et on continue la boucle

TestMenuInputVol:

		cpi		Work,3								; C'est 3 ?
		brne	TestMenuInputTrig					; Nan...

		ldi		ZH,HIGH(MenuInputVol*2)				; Yes, c'est Troie
		ldi		ZL,LOW(MenuInputVol*2)
		call	DisplayAfficheChaine				; Affiche la premi�re chaine de setup
		call	DisplayArrow

		rjmp	LoopLevelI1							; et on continue la boucle

TestMenuInputTrig:

		ldi		ZH,HIGH(MenuInputTrig*2)			; Ici, c'est obligatoirement 4
		ldi		ZL,LOW(MenuInputTrig*2)
		call	DisplayAfficheChaine				; Affiche la premi�re chaine de setup
		call	DisplayArrow

		rjmp	LoopLevelI1							; et on continue la boucle

WhatInputMenuToEnterL1:

		mov		Work,MenuReg2						; Transfert en imm�diat
		cpi		Work,0								; si c'est 0
		breq	GotoEnterMenuInputName				; on va triturer le nom de l'entr�e
		cpi		Work,1								; si c'est 1
		breq	GotoEnterMenuInputType				; on va triturer le type de l'entr�e 
		cpi		Work,2								; si c'est 2
		breq	GotoEnterMenuInput6dB				; on va triturer les 6dB de l'entr�e
		cpi		Work,3								; si c'est 3
		breq	GotoEnterMenuInputVol				; on va triturer le volume de l'entr�e
		cpi		Work,4								; si c'est 4
		breq	GotoEnterMenuInputTrig				; on va triturer le trigger de l'entr�e

GotoEnterMenuInputName:
		rjmp	EnterMenuInputName
GotoEnterMenuInputType:
		rjmp	EnterMenuInputType 
GotoEnterMenuInput6dB:
		rjmp	EnterMenuInput6dB 
GotoEnterMenuInputVol:
		rjmp	EnterMenuInputVol 
GotoEnterMenuInputTrig:
		rjmp	EnterMenuInputTrig 


EnterMenuInputName:									; on va triturer le nom de l'entr�e

		call 	Attendre							; On attend un peu
		sbic	PinMenu,SwitchMenu					; Un vrai appui sur le bouton de menu ?
		rjmp	TestMenuInputName					; Sinon,on revient au bon endroit

		rcall	MenuEntreeName						; On y va

		ldi		Work,0								; on se place
		call	DisplayPlaceCurseur					; sur la premi�re ligne de l'afficheur
		ldi		ZH,HIGH(MenuInputNbParam*2)
		ldi		ZL,LOW(MenuInputNbParam*2)
		call	DisplayAfficheChaine				; affiche le "message" de l'encodeur 

		ldi		Work,9								; Le num�ro de l'entr�e
		call 	DisplayPlaceCurseur						; est affich� en 10�me position
		mov		Char,MenuReg1						; On passe le N� de l'entr�e
		subi	Char,-49							; en ASCII
		call	DisplayWriteChar					; et on l'affiche

		ldi		Work,0x40							; Au retour, on se place
		call	DisplayPlaceCurseur					; sur la seconde ligne de l'afficheur

		clr		Work
		mov		MenuReg2,Work						; On remet la bonne valeur dans MenuReg2
		rjmp	TestMenuInputName					; et on revient au bon endroit

EnterMenuInputType:

		call 	Attendre							; On attend un peu
		sbic	PinMenu,SwitchMenu					; Un vrai appui sur le bouton de menu ?
		rjmp	TestMenuInputType					; Sinon,on revient au bon endroit

		rcall	MenuEntreeType						; On y va

		ldi		Work,0								; on se place
		call	DisplayPlaceCurseur					; sur la premi�re ligne de l'afficheur
		ldi		ZH,HIGH(MenuInputNbParam*2)
		ldi		ZL,LOW(MenuInputNbParam*2)
		call	DisplayAfficheChaine				; affiche le "message" de l'encodeur 

		ldi		Work,9								; Le num�ro de l'entr�e
		call 	DisplayPlaceCurseur					; est affich� en 10�me position
		mov		Char,MenuReg1						; On passe le N� de l'entr�e
		subi	Char,-49							; en ASCII
		call	DisplayWriteChar					; et on l'affiche

		ldi		Work,0x40							; Au retour, on se place
		call	DisplayPlaceCurseur						; sur la seconde ligne de l'afficheur

; -- On v�rifie que l'entr�e qu'on vient d'�diter n'est pas l'entr�e active
; -- auquel cas, il faut prendre en compte la modif pour qu'elle soit r�percut�e sur l'affichage

		call	MenuCheckActiveInput

		ldi		Work,1
		mov		MenuReg2,Work						; On remet la bonne valeur dans MenuReg2
		rjmp	TestMenuInputType					; et on revient au bon endroit

EnterMenuInput6dB:

		call 	Attendre							; On attend un peu
		sbic	PinMenu,SwitchMenu					; Un vrai appui sur le bouton de menu ?
		rjmp	TestMenuInputTrig					; Sinon,on revient au bon endroit

		rcall	MenuEntree6dB						; On y va

		ldi		Work,0								; on se place
		call	DisplayPlaceCurseur					; sur la premi�re ligne de l'afficheur
		ldi		ZH,HIGH(MenuInputNbParam*2)
		ldi		ZL,LOW(MenuInputNbParam*2)
		call	DisplayAfficheChaine				; affiche le "message" de l'encodeur 

		ldi		Work,9								; Le num�ro de l'entr�e
		call 	DisplayPlaceCurseur						; est affich� en 10�me position
		mov		Char,MenuReg1						; On passe le N� de l'entr�e
		subi	Char,-49							; en ASCII
		call	DisplayWriteChar					; et on l'affiche

		ldi		Work,0x40							; Au retour, on se place
		call	DisplayPlaceCurseur					; sur la seconde ligne de l'afficheur

; -- On v�rifie que l'entr�e qu'on vient d'�diter n'est pas l'entr�e active
; -- auquel cas, il faut prendre en compte la modif pour qu'elle soit r�percut�e sur l'affichage

		call	MenuCheckActiveInput6dB

		ldi		Work,2
		mov		MenuReg2,Work						; On remet la bonne valeur dans MenuReg2
		rjmp	TestMenuInput6dB					; et on revient au bon endroit

EnterMenuInputVol:

		call 	Attendre							; On attend un peu
		sbic	PinMenu,SwitchMenu					; Un vrai appui sur le bouton de menu ?
		rjmp	TestMenuInputTrig					; Sinon,on revient au bon endroit

		rcall	MenuEntreeVol						; On y va

		ldi		Work,0								; on se place
		call	DisplayPlaceCurseur					; sur la premi�re ligne de l'afficheur
		ldi		ZH,HIGH(MenuInputNbParam*2)
		ldi		ZL,LOW(MenuInputNbParam*2)
		call	DisplayAfficheChaine				; affiche le "message" de l'encodeur 

		ldi		Work,9								; Le num�ro de l'entr�e
		call 	DisplayPlaceCurseur						; est affich� en 10�me position
		mov		Char,MenuReg1						; On passe le N� de l'entr�e
		subi	Char,-49							; en ASCII
		call	DisplayWriteChar						; et on l'affiche

		ldi		Work,0x40							; Au retour, on se place
		call	DisplayPlaceCurseur					; sur la seconde ligne de l'afficheur

		ldi		Work,3
		mov		MenuReg2,Work						; On remet la bonne valeur dans MenuReg2
		rjmp	TestMenuInputVol					; et on revient au bon endroit

EnterMenuInputTrig:

		call 	Attendre							; On attend un peu
		sbic	PinMenu,SwitchMenu					; Un vrai appui sur le bouton de menu ?
		rjmp	TestMenuInputTrig					; Sinon,on revient au bon endroit

		rcall	MenuEntreeTrig						; On y va

		ldi		Work,0								; on se place
		call	DisplayPlaceCurseur					; sur la premi�re ligne de l'afficheur
		ldi		ZH,HIGH(MenuInputNbParam*2)
		ldi		ZL,LOW(MenuInputNbParam*2)
		call	DisplayAfficheChaine				; affiche le "message" de l'encodeur 

		ldi		Work,9								; Le num�ro de l'entr�e
		call 	DisplayPlaceCurseur						; est affich� en 10�me position
		mov		Char,MenuReg1						; On passe le N� de l'entr�e
		subi	Char,-49							; en ASCII
		call	DisplayWriteChar						; et on l'affiche

		ldi		Work,0x40							; Au retour, on se place
		call	DisplayPlaceCurseur					; sur la seconde ligne de l'afficheur

		ldi		Work,4
		mov		MenuReg2,Work						; On remet la bonne valeur dans MenuReg2
		rjmp	TestMenuInputTrig					; et on revient au bon endroit

ExitEntreeMenu:
		call 	Attendre							; On attend pour le d�bounce
		sbic	PinSwitchMC,SwitchMC				; C'est un vrai appui sur le bouton d'annulation pour sortir ?
		rjmp	LoopLevelI1							; Non, fausse arlette et on replonge dans la boucle

WaitBeforeExitEntreeMenu:
		sbis	PinSwitchMC,SwitchMC				; Petit test habituel pour ne pas effectuer
		rjmp	WaitBeforeExitEntreeMenu			; des sorties de menu en cascade

		ret											; on se casse de ce menu

; ========================================================
; == Edition du libell� l'entr�e  (12 caract�res)       ==
; == Le num�ro de l'entr�e consid�r�e est dans MenuReg1 ==
; ==                                                    ==
; ==    - L'encodeur change de position de caract�re    ==
; ==      ou apr�s un appui sur "menu", change le code  ==
; ==      ASCII du caract�re                            ==
; ==                                                    ==
; ==    - Appui court sur le bouton "Menu" :            ==
; ==      Choix du caract�re � �diter                   ==
; ==      Validation du caract�re �dit�                 ==
; ==                                                    ==
; ==    - Appui long sur le bouton "Menu" :             ==
; ==      Validation du nouveau libell�                 ==
; ==                                                    ==
; ==    - Le bouton de Standby/On :                     ==
; ==      En modification d'un caract�re, annulation de ==
; ==      la saisie courante du caract�re               ==
; ==      Sinon, annulation de l'�dition du libell�     ==
; ==      et retour au libell� d'origine                ==
; ==                                                    ==
; ========================================================

MenuEntreeName:

WaitMenuEntreeName:
		sbis	PinMenu,SwitchMenu					; Avant de passer � la suite,
		rjmp	WaitMenuEntreeName					; On attend le relachement du bouton de menu

; -- Bouton rel�ch�, on continue
; -- Normalement l'affichage est bon et n'a pas chang�
; -- On fait juste appara�tre le curseur

		ldi		Work,0								; on se place
		call	DisplayPlaceCurseur					; sur la premi�re ligne de l'afficheur
		ldi		ZH,HIGH(MenuInputNbName*2)
		ldi		ZL,LOW(MenuInputNbName*2)
		call	DisplayAfficheChaine				; affiche le "message" de l'encodeur 

		ldi		Work,0x0B							; Le num�ro de l'entr�e
		call 	DisplayPlaceCurseur						; est affich� en 10�me position
		mov		Char,MenuReg1						; On passe le N� de l'entr�e
		subi	Char,-49							; en ASCII
		call	DisplayWriteChar					; et on l'affiche

		ldi		Work,0x40							; on se place
		call	DisplayPlaceCurseur					; sur la seconde ligne de l'afficheur
		ldi		ZH,HIGH(MenuChangeInputName*2)
		ldi		ZL,LOW(MenuChangeInputName*2)
		call	DisplayAfficheChaine				; Et on affiche le premier item du menu
		call	DisplayArrow

		rcall	MenuAfficheNomEntree				; Affiche le nom de l'entr�e qui est en EEPROM

		ldi		Work,0x40+(DisplaySize-NameSize)/2	; On replace le curseur
		call	DisplayPlaceCurseur					; au d�but du libell�
		call	DisplayCursorBlock					; On affiche le curseur en bloc
													; et on est pr�t pour l'�dition
		clr		MenuReg2							; Registre qui va servir � conna�tre le num�ro du caract�re

; -- Boucle pour l'�dition --

LoopInpName:

		call 	LectureEncodeur						; Lecture de l'encodeur
		sbrs	StatReg1,FlagIncremente				; doit-on incr�menter
		sbrc	StatReg1,FlagDecremente				; ou d�cr�menter ?
		rjmp	ChangeCurrentLetter					; l'un des duex en tout cas...

		sbis	PinSwitchMC,SwitchMC				; Un appui sur le bouton d'annulation pour sortir ?
		rjmp	ExitMenuEntreeNameNoSave			; 	- Oui, alors on y va

		sbic	PinMenu,SwitchMenu					; Un appui sur Menu ?
		rjmp 	LoopInpName							; Non, on boucle

		clr		Work								; Sinon on va lancer le timer pour savoir si on a un appui long
		out		TCCR1B,Work							; Arr�te le timer aucazou
		sbr		StatReg2,EXP2(FlagWait)				

		ldi     Work,UneSecHi						; Et c'est parti pour 1 s
		out     TCNT1H,Work							
		ldi		Work,UneSecLo
		out     TCNT1L,Work
		ldi     Work,TimerDiv		        		; On d�marre le Timer avec CK/1024
		out     TCCR1B,Work                     	; et il va compter pendant � peu 1 seconde avant l'overflow

; Maintenant on va boucler en attendant le rel�chement du bouton Menu ou la fin de la seconde fatidique

WaitMenuLib:
		sbrs	StatReg2,FlagWait					; Le flag d"attente est pass� � z�ro ?
		rjmp	ExitMenuEntreeName					; 	- oui -> On sauve d'office
		sbis	PinMenu,SwitchMenu					; 	- non, mais menu toujours appuy� ?
		rjmp 	WaitMenuLib							; Oui, on boucle

		sbrc	StatReg2,FlagWait					; Le flag de wait est-il revenu � 0 (La seconde est �coul�e) ?
		rjmp 	EditCurrentChar		 				; 	- Nan, pas de timeout, alors on change le caract�re � �diter
		rjmp	ExitMenuEntreeName					;   - Oui, alors on va sauver le nouveau libell�

EditCurrentChar:									; On veut �diter un caract�re particulier

		sbis	PinMenu,SwitchMenu					; petit test habituel pour ne pas effectuer
		rjmp	EditCurrentChar						; des sorties de menu en cascade (Bouton Menu rel�ch� ?)

		clr		Work
		out		TCCR1B,Work							; On arr�te le timer 1
		cbr		StatReg2,EXP2(FlagWait)				; et on r�initialise le flag d'attente

		ldi		ZH,RAM_Start
 		ldi		ZL,RAM_TitreActif 					; On se replace au d�but de la chaine en RAM
		add		ZL,MenuReg2							; Offset pour aller sur le bon caract�re
		ld		Char,Z								; On r�cup�re le code du caract�re

		ldi		ZH,RAM_Start						; On va stocker le carat�re �dit� en RAM
		ldi		ZL,RAM_TempChar						; pour le r�cup�rer en cas d'annulation
		st		Z,Char

		call	DisplayCursorOn						; Passe le curseur en soulign�, c'est plus lisible 

LoopInpNameChar:

		call 	LectureEncodeur						; Lecture de l'encodeur
		sbrs	StatReg1,FlagIncremente				; doit-on incr�menter
		sbrc	StatReg1,FlagDecremente				; ou d�cr�menter ?
		rjmp	ChangeNameLetter					; l'un des deux...

		sbis	PinSwitchMC,SwitchMC				; Un appui sur le bouton d'annulation pour valider/sortir ?
		rjmp	ExitLoopNameChar					; 	- Oui, alors on y va

		sbic	PinMenu,SwitchMenu					; Un appui sur Menu ?
		rjmp 	LoopInpNameChar						; Non, on boucle

		call	Attendre							; On attend un peu...
		sbic	PinMenu,SwitchMenu					; Menu toujours appuy� ?
		rjmp 	LoopInpNameChar						; Non, on boucle

		rjmp 	SaveCurrentChar	 					; Change de caract�re � �diter

ExitLoopNameChar:									; On annule la modif du caract�re

		sbis	PinSwitchMC,SwitchMC				; Petite boucle
		rjmp	ExitLoopNameChar					; de debounce r�glementaire

		ldi		ZH,RAM_Start						; On va lire le carat�re �dit� en RAM
		ldi		ZL,RAM_TempChar						; pour le r�cup�rer 
		ld		Char,Z

		ldi		ZH,RAM_Start
 		ldi		ZL,RAM_TitreActif 					; On se replace au d�but de la chaine en RAM
		add		ZL,MenuReg2							; Offset pour aller sur le bon caract�re
		st		Z,Char								; On remet le bon code du caract�re

		ldi		Work,0x44							; Il faut aussi le r��crire sur l'afficheur
		add		Work,MenuReg2						; et on bon endroit
		call	DisplayPlaceCurseur
		call	DisplayWriteChar

		ldi		Work,0x44
		add		Work,MenuReg2						; et remet le curseur au bon endroit
		call	DisplayPlaceCurseur					; car normalement il avance automatiquement

		call	DisplayCursorBlock					; On remet le curseeur en bloc

		rjmp	LoopInpName							; et on reboucle

; -- Sauvegarde du caract�re �dit� --

SaveCurrentChar:									; Pas vraiment de sauvegarde car tout est en RAM automatiquement

		sbis	PinMenu,SwitchMenu					; Petite boucle
		rjmp	SaveCurrentChar						; de debounce r�glementaire

		call	DisplayCursorBlock					; Repasse le curseur en bloc

		ldi		Work,0x44
		add		Work,MenuReg2						; et remet le curseur au bon endroit
		call	DisplayPlaceCurseur					; car normalement il avance automatiquement

		rjmp	LoopInpName

; -- Change la position du curseur --

ChangeCurrentLetter:

		sbrc	StatReg1,FlagIncremente				; regarde dans quel sens allait l'encodeur
		rjmp	IncCurrentLetter					; Vers le haut ?
		sbrc	StatReg1,FlagDecremente				; 
		rjmp	DecCurrentLetter					; vers le bas ?
		rjmp	LoopInpName							; Aucun des deux, alors cassos

IncCurrentLetter:
		ldi		Work,NameSize-1						; On est arriv�
		cp		MenuReg2,Work						; au dernier caract�re ?
		breq	GoToFirstChar						; 	- Oui, alors on repasse au premier
		inc		MenuReg2							; 	- Non, alors on incr�mente	
		rjmp	GotoNextLetter						; 	et on shifte le curseur

GoToFirstChar:
		clr		MenuReg2							
		rjmp	GotoNextLetter						; 	et on shifte le curseur

DecCurrentLetter:
		ldi		Work,0								; On est arriv�
		cp		MenuReg2,Work						; au premier caract�re ?
		breq	GoToLastChar						; 	- Oui, alors on repasse au dernier
		dec		MenuReg2							; 	- Non, alors on d�cr�mente	
		rjmp	GotoNextLetter						; 	et on shifte le curseur

GoToLastChar:
		ldi		Work,NameSize-1
		mov		MenuReg2,Work							

GotoNextLetter:
		ldi		Work,0x44							; Premier caract�re du nom
		add		Work,MenuReg2						; et d�calage pour aller � la bonne place
		call	DisplayPlaceCurseur

		cbr		StatReg1,EXP2(FlagIncremente)		; Remet les flags de l'encodeur
		cbr		StatReg1,EXP2(FlagDecremente)		; � z�ro
		rjmp	LoopInpName							; Mission termin�e, on s'en va
		
; --- Change le code ascii du caract�re (0 � 255) ---

ChangeNameLetter:
		ldi		ZH,RAM_Start
 		ldi		ZL,RAM_TitreActif 					; On se replace au d�but de la chaine en RAM
		add		ZL,MenuReg2							; Offset pour aller sur le bon caract�re
		ld		Char,Z								; On r�cup�re le code du caract�re

		lds		Work,TCCR3B							; si le timer 3 ne tourne pas
		andi	Work,0b00000111						; on lance le clignotement de la LED On
		cpi		Work,0								; car on a modifi� la valeur qui �tait stock�e
		brne	MenuTesteLetter						
		rcall	LanceClignotementLED

MenuTesteLetter:
		sbrc	StatReg1,FlagIncremente				; regarde dans quel sens allait l'encodeur
		rjmp	IncMenuASCII						; Vers le haut ?
		sbrc	StatReg1,FlagDecremente				; 
		rjmp	DecMenuASCII						; vers le bas ?
		rjmp	LoopInpNameChar						; Aucun des deux, alors cassos

IncMenuASCII:										; Incr�mentation du num�ro de menu
		cpi		Char,CodeCharMax					; dernier caract�re autoris� ?
		brne	DoIncMenuASCII						; non, alors on peut incr�menter sans pb

		ldi		Char,CodeCharMin					; sinon, on le repasse au code Ascii Min		
		rjmp	MenuAfficheNewChar					; et on va afficher le nouveau caract�re

DoIncMenuASCII:
#if defined(CRYSTALFONTZ)
		inc		Char								; On incr�mente le registre
#else
		call	TestDisplayIncASCII					; Cherche les caract�res autoris�s
#endif
		rjmp	MenuAfficheNewChar
		
DecMenuASCII:										; D�cr�mentation du num�ro de menu
		cpi		Char,CodeCharMin					; c'est le plus petit code ascii autoris� ?
		brne	DoDecMenuASCII						; non, alors on peut d�cr�menter sans pb

		ldi		Char,CodeCharMax					; sinon, on le repasse au code ascii max	
		rjmp	MenuAfficheNewChar					; et on va afficher la chaine qu'il faut

DoDecMenuASCII:
#if defined(CRYSTALFONTZ)
		dec		Char								; On d�cr�mente le registre
#else
		call	TestDisplayDecASCII					; Cherche les caract�res autoris�s
#endif

MenuAfficheNewChar:									; affiche nouveau caract�re et le stocke en RAM

		cbr		StatReg1,EXP2(FlagIncremente)		; On commence par remettre � 0 les flags de l'encodeur
		cbr		StatReg1,EXP2(FlagDecremente)

		ldi		ZH,RAM_Start
 		ldi		ZL,RAM_TitreActif 					; On se replace au d�but de la chaine en RAM
		add		ZL,MenuReg2							; Offset pour aller sur le bon caract�re
		st		Z,Char								; Stockage en RAM

		ldi		Work,0x44
		add		Work,MenuReg2						; Met le curseur au bon endroit
		call	DisplayPlaceCurseur					; (D�but + num�ro du caract�re - icelui allant de 0 � 7)

		call	DisplayWriteChar					; Ecrit le caract�re

		ldi		Work,0x44
		add		Work,MenuReg2						; et remet le curseur au bon endroit
		call	DisplayPlaceCurseur					; car normalement il avance automatiquement

		rjmp	LoopInpNameChar						; et on reboucle

; -- Sortie avec recopie en EEPROM du libell� modifi� qui est en RAM

ExitMenuEntreeName:

		call	DisplayCursorOff					; On fait dispara�tre le curseur 
		call	ArreteClignotementLED				; Au cazo�, on rallume la LED de On/StandBy

		ldi		Work,SaveLong						; Fixe le temps d'affichage du prochain message
		call	AfficheSavingName					; Affiche le message de sauvegarde

; -- Sauvegarde du nouvel intitul� en EEPROM

		ldi		Work,EE_TitreIn1					; On se place au d�but de la zone des libell�s en EEPROM

		mov		Work1,MenuReg1						; Copie le num�ro de l'entr�e �dit�e
		lsl		Work1								; 
		lsl		Work1								; 4 Shifts left -> Multiplication par 16
		lsl		Work1
		lsl		Work1
		add		Work,Work1							; Auquel on ajoute l'adresse de d�part pour pointer sur le bon libell�

		ldi		ZH,RAM_Start
 		ldi		ZL,RAM_TitreActif 					; R�cup�re en RAM l'adresse de d�but du libell� qu'on vient d'�diter

		clr 	Count1								; 12 caract�res � r�cup�rer
				
MenuCopieLibellesSave:								
		ld		Work2,Z+							; on r�cup�re le caract�re dans la RAM, tout en incr�mentant l'adresse RAM
		call	WriteEEprom							; et on �crit
		inc		Work								; incr�mente l'adresse en EEPROM
		inc		Count1								; Incr�mente le compteur de caract�res

		cpi		Count1,NameSize						; teste si on a fini d'�crire tous les caract�res
		brne	MenuCopieLibellesSave				; et boucle si on n'a pas tout �crit


; -- On sauvegarde aussi en RAM pour l'affichage

		mov		Work1,MenuReg1						; Copie le num�ro de l'entr�e �dit�e
		lsl		Work1								; 
		lsl		Work1								; 4 Shifts left -> Multiplication par 16
		lsl		Work1
		lsl		Work1

		ldi		ZH,RAM_Start						
		ldi		Work,RAM_TitreIn1					; Adresse RAM du 1er libell�
		add		Work,Work1							; On se d�cale pour pointer sur le bon libell�

		ldi		Work1,RAM_TitreActif				; Adresse RAM du libell� �dit�

		clr		Count1								; Compteur de caract�res

MenuCopieLibellesSaveRAM:								

		mov		ZL,Work1							; Libell� �dit�
		ld		Char,Z								; lu en RAM
		mov		ZL,Work								; Libell� final
		st		Z,Char								; �crit en RAM
		inc		Work								; Caract�re suivant
		inc		Work1								; sur les deux positions de RAM
		inc		Count1								; Nombre de caract�res �crits
		cpi		Count1,NameSize						; Dernier caract�re ?
		brne	MenuCopieLibellesSaveRAM			; 	- nan -> Bouclage		

MenuInpLibWaitForRet:
		sbis	PinMenu,SwitchMenu					; petit test habituel pour ne pas effectuer
		rjmp	MenuInpLibWaitForRet				; des sorties de menu en cascade (Bouton Menu rel�ch� ?)

		ret											; On a fini

ExitMenuEntreeNameNoSave:
		sbis	PinSwitchMC,SwitchMC				; Attente d'un �ventuel rel�chement du bouton d'annulation...
		rjmp	ExitMenuEntreeNameNoSave

		call	DisplayCursorOff					; On fait dispara�tre le curseur 
		call	ArreteClignotementLED				; Au cazo�, on rallume la LED de On/StandBy

		ret											; et on se casse de ce menu

; =========================================================
; == Edition du type de l'entr�e (XLR/RCA)               ==
; == Le num�ro de l'entr�e consid�r�e est dans MenuReg1  ==
; ==                                                     ==
; ==    - L'encodeur commute entre XLR et RCA            ==
; ==    - Annulation par le bouton de menu               ==
; ==    - Et la sortie/sauvegarde par le bouton StandBy  ==
; =========================================================

MenuEntreeType:

WaitMenuEntreeType:
		sbis	PinMenu,SwitchMenu					; Avant de passer � la suite,
		rjmp	WaitMenuEntreeType					; On attend le relachement du bouton de menu

; Bouton rel�ch�, on continue

		ldi		Work,0								; Message de la premi�re ligne
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuInputTypeMessage*2)
		ldi		ZL,LOW(MenuInputTypeMessage*2)
		call	DisplayAfficheChaine

		ldi		Work,0x0B							; Cuseur en 10�me position
		call	DisplayPLaceCurseur
		mov		Char,MenuReg1						; affiche le N� de l'entr�e
		subi	Char,-49
		call	DisplayWriteChar

		ldi		ZH,RAM_Start
 		ldi		ZL,RAM_BalIn1 						; R�cup�re en RAM l'indicateur d'entr�e sym�trique
		add		ZL,MenuReg1							; Shifte pour pointer au bon endroit dans la RAM
		ld		Work2,Z								; et r�cup�re la valeur dans Work2

		mov		MenuReg2,Work2						; On transf�re la valeur dans MenuReg2

		call	MenuAfficheTypeEntree				; Affiche le type de l'entr�e	

LoopInpType:

		call 	LectureEncodeur						; Lecture de l'encodeur
		sbrs	StatReg1,FlagIncremente				; doit-on incr�menter
		sbrc	StatReg1,FlagDecremente				; ou d�cr�menter ?
		rjmp	ChangeInputType						; l'un des deux...

		sbis	PinSwitchMC,SwitchMC				; Un appui sur le bouton d'annulation pour sortir ?
		rjmp	ExitMenuEntreeTypeNoSave			; 	- Oui, alors on y va

		sbic	PinMenu,SwitchMenu					; Un appui sur Menu pour valider/sortir ?
		rjmp 	LoopInpType							; Non, on boucle

		call	Attendre							; On attend un peu...
		sbic	PinMenu,SwitchMenu					; Menu toujours appuy� ?
		rjmp 	LoopInpType							; Non, on boucle

		rjmp 	ExitMenuEntreeType					; Sortie avec sauvegarde

ChangeInputType:									; Comme on n'a que deux valeurs, le choix est facile...

		lds		Work,TCCR3B							; si le timer 3 ne tourne pas
		andi	Work,0b00000111						; on lance le clignotement de la LED On
		cpi		Work,0								; car on a modifi� la valeur qui �tait stock�e
		brne	MenuTesteType						
		call	LanceClignotementLED

MenuTesteType:
		cbr		StatReg1,EXP2(FlagIncremente)		; On commence par remettre � 0 les flags de l'encodeur
		cbr		StatReg1,EXP2(FlagDecremente)

		mov		Work,MenuReg2						; On transf�re l'ancienne valeur dans un registre imm�diat
		cpi		Work,0								; C'�tait No ?
		breq	MenuTypeUTB							; 	- Oui -> on change

		clr		MenuReg2							; 	- Non -> on change aussi
		rjmp	ActualiseMenuType

MenuTypeUTB:
		ldi		Work,1
		mov		MenuReg2,Work

ActualiseMenuType:
		rcall 	MenuAfficheTypeEntree				; On affiche la nouvelle valeur
		rjmp	LoopInpType							; et on reboucle		

ExitMenuEntreeType:									; On se sauve en sauvant
		sbis	PinMenu,SwitchMenu					; On attend le rel�chement du bouton de menu
		rjmp	ExitMenuEntreeType

		call	ArreteClignotementLED				; Au cazo�, on rallume la LED de On/StandBy

		ldi		Work,SaveLong						; Fixe le temps d'affichage du prochain message
		call	AfficheSaving						; Affiche le message de sauvegarde

		mov		Work2,MenuReg2						; valeur dans le registre de donn�e de l'EEPROM		
		ldi		Work,EE_BalIn1						; il faut juste la mettre en EEPROM
		add		Work,MenuReg1						; Translation pour pointer au bon endroit
		call	WriteEEprom							; et on �crit

		ldi		ZH,RAM_Start
 		ldi		ZL,RAM_BalIn1 						; R�cup�re en RAM l'indicateur de trigger sur l'entr�e
		add		ZL,MenuReg1							; Shifte pour pointer au bon endroit dans la RAM
		st		Z,Work2								; sauve en RAM

		clr		MenuReg2							; Dans tous les cas, on va annuler l'augmentation de volume de 6dB pour cette entr�e, qu'elle soit XLR ou RCA
		call	MenuModif6dBFromType				; Stockage en RAM en en EEPROM

		ret											; et c'est fini

ExitMenuEntreeTypeNoSave:
		sbis	PinSwitchMC,SwitchMC				; Petit test habituel pour ne pas effectuer
		rjmp	ExitMenuEntreeTypeNoSave			; des sorties de menu en cascade

		call	ArreteClignotementLED				; Au cazo�, on rallume la LED de On/StandBy

		ret											; on se casse de ce menu

; =========================================================
; == Activation du volume de +6dB pour une entr�e unbal  ==
; == Le num�ro de l'entr�e consid�r�e est dans MenuReg1  ==
; ==                                                     ==
; ==    - L'encodeur commute entre Yes et No             ==
; ==    - Annulation par le bouton de menu               ==
; ==    - Et la sortie/sauvegarde par le bouton StandBy  ==
; =========================================================

MenuEntree6dB:

WaitMenuEntree6dB:
		sbis	PinMenu,SwitchMenu					; Avant de passer � la suite,
		rjmp	WaitMenuEntree6dB					; On attend le relachement du bouton de menu

; Bouton rel�ch�, on continue

		ldi		Work,0								; Message de la premi�re ligne
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuInput6dBMessage*2)
		ldi		ZL,LOW(MenuInput6dBMessage*2)
		call	DisplayAfficheChaine

		ldi		Work,6								; Cuseur en 7�me position
		call	DisplayPLaceCurseur
		mov		Char,MenuReg1						; affiche le N� de l'entr�e
		subi	Char,-49
		call	DisplayWriteChar

		ldi		Work,0x40							; d�but de seconde ligne
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuEncodeurMessage*2)		; Chaine � afficher
		ldi		ZL,LOW(MenuEncodeurMessage*2)
		call	DisplayAfficheChaine
		call	DisplayArrow

		ldi		ZH,RAM_Start
 		ldi		ZL,RAM_In1_6dB 						; R�cup�re en RAM l'indicateur de 6dB sur l'entr�e
		add		ZL,MenuReg1							; Shifte pour pointer au bon endroit dans la RAM
		ld		Work2,Z								; et r�cup�re la valeur dans Work2

		mov		MenuReg2,Work2						; On transf�re la valeur dans MenuReg2

		rcall	MenuAffiche6dB						; et affiche la valeur

LoopInp6dB:

		call 	LectureEncodeur						; Lecture de l'encodeur
		sbrs	StatReg1,FlagIncremente				; doit-on incr�menter
		sbrc	StatReg1,FlagDecremente				; ou d�cr�menter ?
		rjmp	ChangeInput6dB						; l'un des deux...

		sbis	PinSwitchMC,SwitchMC				; Un appui sur le bouton d'annulation pour sortir ?
		rjmp	ExitMenuEntree6dBNoSave			; 	- Oui, alors on y va

		sbic	PinMenu,SwitchMenu					; Un appui sur Menu pour valider/sortir ?
		rjmp 	LoopInp6dB							; Non, on boucle

		call	Attendre							; On attend un peu...
		sbic	PinMenu,SwitchMenu					; Menu toujours appuy� ?
		rjmp 	LoopInp6dB							; Non, on boucle

		rjmp 	ExitMenuEntree6dB					; Sortie sans sauvegarde

ChangeInput6dB:										; Comme on n'a que deux valeurs, le choix est facile...

		lds		Work,TCCR3B							; si le timer 3 ne tourne pas
		andi	Work,0b00000111						; on lance le clignotement de la LED On
		cpi		Work,0								; car on a modifi� la valeur qui �tait stock�e
		brne	MenuTeste6dB						
		call	LanceClignotementLED

MenuTeste6dB:
		cbr		StatReg1,EXP2(FlagIncremente)		; On commence par remettre � 0 les flags de l'encodeur
		cbr		StatReg1,EXP2(FlagDecremente)

		mov		Work,MenuReg2						; On transf�re l'ancienne valeur dans un registre imm�diat
		cpi		Work,0								; C'�tait No ?
		breq	Menu6dBNoToYes						; 	- Oui -> on change

		ldi		Work,0								; 	- Non -> on change aussi
		mov		MenuReg2,Work
		rjmp	ActualiseMenu6dB

Menu6dBNoToYes:
		ldi		Work,1
		mov		MenuReg2,Work

ActualiseMenu6dB:
		rcall 	MenuAffiche6dB						; On affiche la nouvelle valeur
		rjmp	LoopInp6dB							; et on reboucle		

ExitMenuEntree6dB:									; On se sauve en sauvant
		sbis	PinMenu,SwitchMenu					; On attend le rel�chement du bouton de menu
		rjmp	ExitMenuEntree6dB

		call	ArreteClignotementLED				; Au cazo�, on rallume la LED de On/StandBy

		ldi		Work,SaveLong						; Fixe le temps d'affichage du prochain message
		call	AfficheSaving						; Affiche le message de sauvegarde

MenuModif6dBFromType:								; Point d'entr�e pour modifier la valeur si on a chang� le type d'entr�e

		mov		Work2,MenuReg2						; valeur dans le registre de donn�e de l'EEPROM		
		ldi		Work,EE_In1_6dB						; il faut juste la mettre en EEPROM
		add		Work,MenuReg1						; Translation pour pointer au bon endroit
		call	WriteEEprom							; et on �crit

		ldi		ZH,RAM_Start
 		ldi		ZL,RAM_In1_6dB 						; R�cup�re en RAM l'indicateur de 6dB sur l'entr�e
		add		ZL,MenuReg1							; Shifte pour pointer au bon endroit dans la RAM
		st		Z,Work2								; sauve en RAM

		ret											; et c'est fini

ExitMenuEntree6dBNoSave:
		sbis	PinSwitchMC,SwitchMC				; Petit test habituel pour ne pas effectuer
		rjmp	ExitMenuEntree6dBNoSave				; des sorties de menu en cascade

		call	ArreteClignotementLED				; Au cazo�, on rallume la LED de On/StandBy

		ret											; on se casse de ce menu

; =========================================================
; == Activation de la sortie trigger pour une entr�e     ==
; == Le num�ro de l'entr�e consid�r�e est dans MenuReg1  ==
; ==                                                     ==
; ==    - L'encodeur commute entre Yes et No             ==
; ==    - Annulation par le bouton de menu               ==
; ==    - Et la sortie/sauvegarde par le bouton StandBy  ==
; =========================================================

MenuEntreeTrig:

WaitMenuEntreeTrig:
		sbis	PinMenu,SwitchMenu					; Avant de passer � la suite,
		rjmp	WaitMenuEntreeTrig					; On attend le relachement du bouton de menu

; Bouton rel�ch�, on continue

		ldi		Work,0								; Message de la premi�re ligne
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuInputTrigMessage*2)
		ldi		ZL,LOW(MenuInputTrigMessage*2)
		call	DisplayAfficheChaine

		ldi		Work,6								; Cuseur en 7�me position
		call	DisplayPLaceCurseur
		mov		Char,MenuReg1						; affiche le N� de l'entr�e
		subi	Char,-49
		call	DisplayWriteChar

		ldi		Work,0x40							; d�but de seconde ligne
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuEncodeurMessage*2)		; Chaine � afficher
		ldi		ZL,LOW(MenuEncodeurMessage*2)
		call	DisplayAfficheChaine
		call	DisplayArrow

		ldi		ZH,RAM_Start
 		ldi		ZL,RAM_TrigIn1 						; R�cup�re en RAM l'indicateur de trigger sur l'entr�e
		add		ZL,MenuReg1							; Shifte pour pointer au bon endroit dans la RAM
		ld		Work2,Z								; et r�cup�re la valeur dans Work2

		mov		MenuReg2,Work2						; On transf�re la valeur dans MenuReg2

		rcall	MenuAfficheTrig						; et affiche la valeur

LoopInpTrig:

		call 	LectureEncodeur						; Lecture de l'encodeur
		sbrs	StatReg1,FlagIncremente				; doit-on incr�menter
		sbrc	StatReg1,FlagDecremente				; ou d�cr�menter ?
		rjmp	ChangeInputTrig						; l'un des deux...

		sbis	PinSwitchMC,SwitchmC				; Un appui sur le bouton d'annulation pour sortir ?
		rjmp	ExitMenuEntreeTrigNoSave			; 	- Oui, alors on y va

		sbic	PinMenu,SwitchMenu					; Un appui sur Menu pour valider/sortir ?
		rjmp 	LoopInpTrig							; Non, on boucle

		call	Attendre							; On attend un peu...
		sbic	PinMenu,SwitchMenu					; Menu toujours appuy� ?
		rjmp 	LoopInpTrig							; Non, on boucle

		rjmp 	ExitMenuEntreeTrig					; Sortie sans sauvegarde

ChangeInputTrig:									; Comme on n'a que deux valeurs, le choix est facile...

		lds		Work,TCCR3B							; si le timer 3 ne tourne pas
		andi	Work,0b00000111						; on lance le clignotement de la LED On
		cpi		Work,0								; car on a modifi� la valeur qui �tait stock�e
		brne	MenuTesteTrig						
		call	LanceClignotementLED

MenuTesteTrig:
		cbr		StatReg1,EXP2(FlagIncremente)		; On commence par remettre � 0 les flags de l'encodeur
		cbr		StatReg1,EXP2(FlagDecremente)

		mov		Work,MenuReg2						; On transf�re l'ancienne valeur dans un registre imm�diat
		cpi		Work,0								; C'�tait No ?
		breq	MenuTrigNoToYes						; 	- Oui -> on change

		ldi		Work,0								; 	- Non -> on change aussi
		mov		MenuReg2,Work
		rjmp	ActualiseMenuTrig

MenuTrigNoToYes:
		ldi		Work,1
		mov		MenuReg2,Work

ActualiseMenuTrig:
		rcall 	MenuAfficheTrig						; On affiche la nouvelle valeur
		rjmp	LoopInpTrig							; et on reboucle		

ExitMenuEntreeTrig:									; On se sauve en sauvant
		sbis	PinMenu,SwitchMenu					; On attend le rel�chement du bouton de menu
		rjmp	ExitMenuEntreeTrig

		call	ArreteClignotementLED				; Au cazo�, on rallume la LED de On/StandBy

		ldi		Work,SaveLong						; Fixe le temps d'affichage du prochain message
		call	AfficheSaving						; Affiche le message de sauvegarde

		mov		Work2,MenuReg2						; valeur dans le registre de donn�e de l'EEPROM		
		ldi		Work,EE_TrigIn1						; il faut juste la mettre en EEPROM
		add		Work,MenuReg1						; Translation pour pointer au bon endroit
		call	WriteEEprom							; et on �crit

		ldi		ZH,RAM_Start
 		ldi		ZL,RAM_TrigIn1 						; R�cup�re en RAM l'indicateur de trigger sur l'entr�e
		add		ZL,MenuReg1							; Shifte pour pointer au bon endroit dans la RAM
		st		Z,Work2								; sauve en RAM

		ret											; et c'est fini

ExitMenuEntreeTrigNoSave:
		sbis	PinSwitchMC,SwitchMC				; Petit test habituel pour ne pas effectuer
		rjmp	ExitMenuEntreeTrigNoSave			; des sorties de menu en cascade

		call	ArreteClignotementLED				; Au cazo�, on rallume la LED de On/StandBy

		ret											; on se casse de ce menu

; =========================================================
; == Modification particuli�re du volume pour une entr�e ==
; == Le num�ro de l'entr�e consid�r�e est dans MenuReg1  ==
; ==                                                     ==
; ==    - L'encodeur change la valeur                    ==
; ==    - Ajout (bit 7 � 0) ou retrait (bit 7 � 1)       ==
; ==    - Annulation par le bouton de menu               ==
; ==    - Et la sortie/sauvegarde par le bouton StandBy  ==
; =========================================================

MenuEntreeVol:

WaitMenuEntreeVol:
		sbis	PinMenu,SwitchMenu					; Avant de passer � la suite,
		rjmp	WaitMenuEntreeVol					; On attend le relachement du bouton de menu

; Bouton rel�ch�, on continue

		ldi		ZH,RAM_Start						; On commence par regarder si l'entr�e �dit�e n'est pas l'entr�e en cours
		ldi		ZL,RAM_EntreeActive
		ld		Work1,Z								; r�cup�re l'entr�e � afficher dans le registre Work1

		cpse	MenuReg1,Work1						; Sont-ce les m�mes ?
		rjmp	MenuEntreeVolNotSame				; nan, on passe � la suite

		call	MenuRecupereVolume					; Sinon, on r�cup�re la valeur du volume "vrai"

MenuEntreeVolNotSame:
		ldi		Work,0								; Message de la premi�re ligne
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuInputVolMessage*2)
		ldi		ZL,LOW(MenuInputVolMessage*2)
		call	DisplayAfficheChaine

		ldi		Work,6								; Cuseur en 7�me position
		call	DisplayPLaceCurseur
		mov		Char,MenuReg1						; affiche le N� de l'entr�e
		subi	Char,-49
		call	DisplayWriteChar

		ldi		ZH,RAM_Start
 		ldi		ZL,RAM_ModVol_In1 					; R�cup�re en RAM l'indicateur de trigger sur l'entr�e
		add		ZL,MenuReg1							; Shifte pour pointer au bon endroit dans la RAM
		ld		Work2,Z								; et r�cup�re la valeur dans Work2

		mov		MenuReg2,Work2						; On transf�re la valeur dans MenuReg2

		rcall	MenuAfficheInpVol					; et affiche la valeur

LoopInpVol:
		call 	LectureEncodeur						; Lecture de l'encodeur
		sbrs	StatReg1,FlagIncremente				; doit-on incr�menter
		sbrc	StatReg1,FlagDecremente				; ou d�cr�menter ?
		rjmp	ChangeInputVol						; l'un des deux...

		sbis	PinSwitchMC,SwitchMC				; Un appui sur le bouton d'annulation pour sortir ?
		rjmp	ExitMenuEntreeVolNoSave				; 	- Oui, alors on y va

		sbic	PinMenu,SwitchMenu					; Un appui sur Menu pour valider/sortir ?
		rjmp 	LoopInpVol							; Non, on boucle

		call	Attendre							; On attend un peu...
		sbic	PinMenu,SwitchMenu					; Menu toujours appuy� ?
		rjmp 	LoopInpVol							; Non, on boucle

		rjmp 	ExitMenuEntreeVol					; Sortie sans sauvegarde

ChangeInputVol:
		lds		Work,TCCR3B							; si le timer 3 ne tourne pas
		andi	Work,0b00000111						; on lance le clignotement de la LED On
		cpi		Work,0								; car on a modifi� la valeur qui �tait stock�e
		brne	MenuTesteVol						
		call	LanceClignotementLED

MenuTesteVol:
		mov		Work,MenuReg2						; On transf�re l'ancienne valeur dans un registre imm�diat
		cbr		Work,0b10000000						; On efface le bit de signe dans ce registre

		sbrc	StatReg1,FlagIncremente				; regarde dans quel sens allait l'encodeur
		rjmp	IncVolInpVal						; Vers le haut ?
		sbrc	StatReg1,FlagDecremente				; 
		rjmp	DecVolInpVal						; vers le bas ?
		rjmp	LoopInpVol							; Aucun des deux, alors cassos

IncVolInpVal:										; On incr�mente
		sbrc	MenuReg2,7							; On �tait n�gatif ?
		rjmp	DoDecVolInpVal						; Oui, alors on diminue la valeur absolue pour augmenter (c'est fut�, hein ?)

DoIncVolInpVal:										; Incr�mentation effective
		cpi		Work,8								; On �tait au max ?
		breq	ActualiseInpVolOnly					; oui, alors, on ne fait rien

		inc		Work								; Sinon on incr�mente
		rjmp	FinLoopInpVol						; et on termine

DecVolInpVal:										; On d�cr�mente
		sbrc	MenuReg2,7							; On �tait positif ?
		rjmp	DoIncVolInpVal						; Oui, alors on augmente la valeur absolue pour diminuer (c'est fut�, hein ?)
						
DoDecVolInpVal:										; D�cr�mentation effective
		ldi		Work1,0
		cp		Work1,MenuReg2						; Avait-on z�ro avant modif ?
		brne	ReallyDecVolInputVal
		ldi		Work1,0b10000000
		mov		MenuReg2,Work1
		rjmp	DoIncVolInpVal

ReallyDecVolInputVal:
		cpi		Work,0								; On �tait au min ?
		breq	ActualiseInpVolOnly					; oui, alors, on ne fait rien

		dec		Work								; Sinon on d�cr�mente

FinLoopInpVol:
		cpi		Work,0
		breq	FinFinLoopInpVol

		mov		Work1,MenuReg2						; Efface tous les bits de MenuReg2, sauf le bit de signe
		cbr		Work1,0b01111111
		mov		MenuReg2,Work1

		add		MenuReg2,Work						; et y place la nouvelle valeur
		rjmp	ActualiseInpVol						; pour finalement afficher la nouvelle valeur

FinFinLoopInpVol:
		mov		MenuReg2,Work

ActualiseInpVol:
		ldi		ZH,RAM_Start						; Si l'entr�e �dit�e est l'entr�e en cours
		ldi		ZL,RAM_EntreeActive
		ld		Work1,Z								; r�cup�re l'entr�e � afficher dans le registre Work1

		cpse	MenuReg1,Work1						; ce sont les m�mes ?
		rjmp	ActualiseInpVolOnly					; nan, on passe � la suite

		ldi		ZH,RAM_Start						; Oui, l'entr�e �dit�e est l'entr�e en cours
		ldi		ZL,RAM_TempVolume
		ld		VolReg,Z							; r�cup�re la valeur du volume qui �tait stock�e

		mov		Work2,MenuReg2						; Transf�re la valeur dans Work2
		call	InputVolNewNoRam					; Modfie le volume avec le trim
		call	SetVolume							; et r�gle le volume en cons�quence

ActualiseInpVolOnly:
		cbr		StatReg1,EXP2(FlagIncremente)		; On commence par remettre � 0 les flags de l'encodeur
		cbr		StatReg1,EXP2(FlagDecremente)

		call 	MenuAfficheInpVol					; Affiche la nouvelle valeur (contenue dans MenuReg2)

		rjmp	LoopInpVol							; et retourne scruter encodeur et touches

ExitMenuEntreeVol:									; On se sauve en sauvant
		sbis	PinMenu,SwitchMenu					; On attend le rel�chement du bouton de menu
		rjmp	ExitMenuEntreeVol

		call	ArreteClignotementLED				; Au cazo�, on rallume la LED de On/StandBy

		ldi		Work,SaveLong						; Fixe le temps d'affichage du prochain message
		call	AfficheSaving						; Affiche le message de sauvegarde

		mov		Work2,MenuReg2						; valeur dans le registre de donn�e de l'EEPROM		
		ldi		Work,EE_ModVol_In1					; il faut juste la mettre en EEPROM
		add		Work,MenuReg1						; Translation pour pointer au bon endroit
		call	WriteEEprom							; et on �crit

		ldi		ZH,RAM_Start
 		ldi		ZL,RAM_ModVol_In1 					; R�cup�re en RAM l'indicateur de trigger sur l'entr�e
		add		ZL,MenuReg1							; Shifte pour pointer au bon endroit dans la RAM
		st		Z,Work2								; sauve en RAM

		ldi		ZH,RAM_Start						; Si l'entr�e �dit�e est l'entr�e en cours
		ldi		ZL,RAM_EntreeActive
		ld		Work1,Z								; r�cup�re l'entr�e � afficher dans le registre Work1

		cpse	MenuReg1,Work1						; ce sont les m�mes ?
		ret											; nan, on passe � la suite

		ldi		ZH,RAM_Start						; Oui, l'entr�e �dit�e est l'entr�e en cours
		ldi		ZL,RAM_TempVolume
		ld		VolReg,Z							; r�cup�re la valeur du volume qui �tait stock�e

		mov		Work2,MenuReg2
		call	InputVolNewNoRam					; Modfie le volume avec le trim
		call	SetVolume							; et r�gle le volume en cons�quence

		ret											; et c'est fini

ExitMenuEntreeVolNoSave:
		sbis	PinSwitchMC,SwitchMC				; Petit test habituel pour ne pas effectuer
		rjmp	ExitMenuEntreeVolNoSave				; des sorties de menu en cascade

		call	ArreteClignotementLED				; Au cazo�, on rallume la LED de On/StandBy

		ldi		ZH,RAM_Start						; Si l'entr�e �dit�e est l'entr�e en cours
		ldi		ZL,RAM_EntreeActive
		ld		Work1,Z								; r�cup�re l'entr�e � afficher dans le registre Work1

		cpse	MenuReg1,Work1						; ce sont les m�mes ?
		ret											; nan, on passe � la suite

		ldi		ZH,RAM_Start						; Oui, l'entr�e �dit�e est l'entr�e en cours
		ldi		ZL,RAM_TempVolume
		ld		VolReg,Z							; r�cup�re la valeur du volume qui �tait stock�e

		call	InputVolNew							; Modfie le volume avec le trim
		call	SetVolume							; et r�gle le volume en cons�quence

		ret											; on se casse de ce menu

; =========================================================
; == Choix de l'entr�e � activer au d�marrage            ==
; ==                                                     ==
; ==    - L'encodeur commute entre les entr�es           ==
; ==    - Validation par le bouton de menu               ==
; ==    - Et la sortie/annulation par le bouton StandBy  ==
; =========================================================

MenuStartInput:

WaitMenuEntreeStart:
		sbis	PinMenu,SwitchMenu					; Avant de passer � la suite,
		rjmp	WaitMenuEntreeStart					; On attend le relachement du bouton de menu

; Bouton rel�ch�, on continue

		ldi		Work,0								; Message de la premi�re ligne
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuInputPrefMessage*2)
		ldi		ZL,LOW(MenuInputPrefMessage*2)
		call	DisplayAfficheChaine

		ldi		ZH,RAM_Start
		ldi		ZL,RAM_StartInputBehave
		ld		MenuReg1,Z							; Charge le comportement actuel de l'entr�e de startup
		mov		Work,MenuReg1

		cpi		Work,0								; Entr�e pr�d�finie
		breq	MenuSIAffichePreset					; 	- Vi -> On y va

		ldi		Work,0x40							; 	- No -> Derni�re entr�e
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuPrefInpLastMessage*2)	; Chaine � afficher
		ldi		ZL,LOW(MenuPrefInpLastMessage*2)
		call	DisplayAfficheChaine
		call	DisplayArrow
		rjmp	MenuLoopSI

MenuSIAffichePreset:
		ldi		Work,0x40							; Entr�e pr�d�finie
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuPrefInpPresetMessage*2)	; Chaine � afficher
		ldi		ZL,LOW(MenuPrefInpPresetMessage*2)
		call	DisplayAfficheChaine
		call	DisplayArrow

; -- Boucle d'�dition

MenuLoopSI:
		call 	LectureEncodeur						; Lecture de l'encodeur
		sbrs	StatReg1,FlagIncremente				; doit-on incr�menter
		sbrc	StatReg1,FlagDecremente				; ou d�cr�menter ?
		rjmp	ChangeInputStartType				; l'un des deux...

		sbis	PinSwitchMC,SwitchMC				; Un appui sur le bouton d'annulation pour sortir sans sauvegarde ?
		rjmp	ExitMenuEntreeStartTypeNoSave		; 	- Oui, alors on y va

		sbic	PinMenu,SwitchMenu					; Un appui sur Menu pour valider/sortir ?
		rjmp 	MenuLoopSI							; Non, on boucle

		call	Attendre							; On attend un peu...
		sbic	PinMenu,SwitchMenu					; Menu toujours appuy� ?
		rjmp 	MenuLoopSI							; Non, on boucle

		rjmp	ExitMenuEntreeStartTypeSave			; Sortie avec sauvegarde

; -- Changement du type de l'entr�e pr�f�r�e

ChangeInputStartType:
		lds		Work,TCCR3B							; si le timer 3 ne tourne pas
		andi	Work,0b00000111						; on lance le clignotement de la LED On
		cpi		Work,0								; car on a modifi� la valeur qui �tait stock�e
		brne	MenuTesteStartType						
		call	LanceClignotementLED

MenuTesteStartType:
		sbrc	StatReg1,FlagIncremente				; regarde dans quel sens allait l'encodeur
		rjmp	IncDecStartTypeInput				; Vers le haut ?
		sbrc	StatReg1,FlagDecremente				; 
		rjmp	IncDecStartTypeInput				; vers le bas ?
		rjmp	MenuLoopSI							; Aucun des deux, alors cassos

IncDecStartTypeInput:								; Changement de la valeur
		mov		Work,MenuReg1
		cpi		Work,0								; C'est 0 ?
		breq	MenuSIType0to1						; 	- Oui -> on passe � 1

		clr		MenuReg1							; 	- Non -> On passe � 0
		rjmp	MenuAfficheNewInpStartType			; Et on va afficher

MenuSIType0to1:										; Passe la valeur � 1
		ldi		Work,1
		mov		MenuReg1,Work

MenuAfficheNewInpStartType:							; On affiche le type de comportement
		cbr		StatReg1,EXP2(FlagIncremente)		; On commence par remettre � 0 les flags de l'encodeur
		cbr		StatReg1,EXP2(FlagDecremente)

		mov		Work,MenuReg1
		cpi		Work,0								; C'est une entr�e fixe ?
		breq	MenuAfficheSI_Pref					; 	- Oui -> On y va

		ldi		Work,0x40							;	- No -> C'est la derni�re entr�e active
		call	DisplayPlaceCurseur						; Curseur en d�but de seconde ligne
		ldi		ZH,HIGH(MenuPrefInpLastMessage*2)	; 
		ldi		ZL,LOW(MenuPrefInpLastMessage*2)
		call	DisplayAfficheChaine				; et on affiche
		call	DisplayArrow

		rjmp	MenuLoopSI
				
MenuAfficheSI_Pref:									; Entr�e Fixe
		ldi		Work,0x40
		call	DisplayPlaceCurseur					; Curseur en d�but de seconde ligne
		ldi		ZH,HIGH(MenuPrefInpPresetMessage*2)
		ldi		ZL,LOW(MenuPrefInpPresetMessage*2)
		call	DisplayAfficheChaine				; et on affiche
		call	DisplayArrow

		rjmp	MenuLoopSI

; -- Sauvegarde du type d'entr�e au d�marrage, ou passage � la suite

ExitMenuEntreeStartTypeSave:						; Sauvegarde du comportement
		call 	Attendre							; On attend pour le d�bounce
		sbic	PinMenu,SwitchMenu					; C'est un vrai appui sur Standby/On pour sortir ?
		rjmp	MenuLoopSI							; Non, fausse arlette et on replonge dans la boucle

WaitExitMenuEntreeStartTypeSave:
		sbis	PinMenu,SwitchMenu					; petit test habituel pour ne pas effectuer
		rjmp	WaitExitMenuEntreeStartTypeSave		; des sorties de menu en cascade

		call	ArreteClignotementLED				; Au cazo�, on rallume la LED de On/StandBy

		mov		Work,MenuReg1
		cpi		Work,0								; Si c'est 0 (entr�e fix�e) on passe � la suite
		breq	MenuEnterStartInputName

; -- Sinon on m�morise qu'il faut m�moriser la derni�re entr�e

		ldi		Work,SaveLong						; Fixe le temps d'affichage du prochain message
		call	AfficheSaving						; Affiche le message de sauvegarde

; -- On sauve en RAM

		ldi		ZH,RAM_Start
		ldi		ZL,RAM_StartInputBehave
		st		Z,MenuReg1
				
; -- En EEPROM

		ldi		Work,EE_StartInputBehave			; Position dans l'EEPROM
		mov		Work2,MenuReg1						; Valeur transf�r�e dans Work2 pour la routine d'EEPROM
		call	WriteEEprom							; et on �crit

		ret											; Et c'est fini pour ici

; -- Sort d'ici sans sauvegarder

ExitMenuEntreeStartTypeNoSave:
		sbis	PinSwitchMC,SwitchMC				; Petit test habituel pour ne pas effectuer
		rjmp	ExitMenuEntreeStartTypeNoSave		; des sorties de menu en cascade

		call	ArreteClignotementLED				; Au cazo�, on rallume la LED de On/StandBy

		ret											; on se casse de ce menu

; -------------------------------------------------------------------------------------------------------------
; -- Changement du num�ro de l'entr�e pr�f�r�e

MenuEnterStartInputName:

		ldi		ZH,RAM_Start
		ldi		ZL,RAM_StartInputBehave
		st		Z,MenuReg1							; On sauvegarde le comportement

		ldi		Work,0								; Message de la premi�re ligne
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuInputPrefMessage*2)
		ldi		ZL,LOW(MenuInputPrefMessage*2)
		call	DisplayAfficheChaine

		ldi		Work,0x40							; d�but de seconde ligne
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuPrefInpNameMessage*2)	; Chaine � afficher
		ldi		ZL,LOW(MenuPrefInpNameMessage*2)
		call	DisplayAfficheChaine
		call	DisplayArrow

		ldi		ZH,RAM_Start
 		ldi		ZL,RAM_StartInput 					; R�cup�re en RAM le num�ro de l'entr�e pr�f�r�e
		ld		MenuReg1,Z							; et r�cup�re la valeur dans MenuReg1

; On affiche le libell� de l'entr�e pr�f�r�e depuis l'EEPROM

MenuStartEEPROMSeek:
		ldi		Work1,EE_TitreIn1					; On se place au d�but de la zone des libell�s en EEPROM
		clr		Work

		ldi		Work1,EE_TitreIn1					; On se place au d�but de la zone des libell�s en EEPROM
		mov		Work,MenuReg1						; Copie le num�ro de l'entr�e �dit�e
		lsl		Work								; 
		lsl		Work								; 4 Shifts left -> Multiplication par 16
		lsl		Work
		lsl		Work
		add		Work1,Work							; Auquel on ajoute l'adresse de d�part pour pointer sur le bon libell�

MenuStartLib:										; Arriv� ici, l'adresse de d�but du libell� est dans Work1
		ldi		Count1,NameSize						; 12 caract�res � �crire
		ldi		Work,0x46							; On se place sur la seconde ligne, au 5�me caract�re pour centrer les 12 cacat�res
		call	DisplayPlaceCurseur					; Met le curseur en bonne position	

MenuEcritStartLib:
		out		EEARL,Work1							; Adresse � atteindre en EEPROM
	    sbi		EECR,EERE							; Pr�pare l'EEPROM � la lecture
		in		Char,EEDR							; lit la valeur en EEPROM et la met dans le registre Work

		call	DisplayWriteChar					; et on l'�crit
		inc		Work1								; On incr�mente l'adresse EEPROM
		dec 	Count1								; Arriv� au 12�me caract�re ?
		brne	MenuEcritStartLib					;	 -Non, on continue la boucle

		ldi		Work,0x43							; Cuseur en 4�me position
		call	DisplayPLaceCurseur
		mov		Char,MenuReg1						; affiche le N� de l'entr�e
		subi	Char,-49
		call	DisplayWriteChar

; -- Boucle pour l'�dition --

LoopInpStart:

		call 	LectureEncodeur						; Lecture de l'encodeur
		sbrs	StatReg1,FlagIncremente				; doit-on incr�menter
		sbrc	StatReg1,FlagDecremente				; ou d�cr�menter ?
		rjmp	ChangeInputStart					; l'un des deux...

		sbis	PinSwitchMC,SwitchMC				; Un appui sur le bouton d'annulation pour sortir sans sauvegarde ?
		rjmp	ExitMenuEntreeStartNoSave			; 	- Oui, alors on y va

		sbic	PinMenu,SwitchMenu					; Un appui sur Menu pour valider/sortir ?
		rjmp 	LoopInpStart						; Non, on boucle

		call	Attendre							; On attend un peu...
		sbic	PinMenu,SwitchMenu					; Menu toujours appuy� ?
		rjmp 	LoopInpStart						; Non, on boucle

		rjmp	ExitMenuEntreeStartSave				; Sortie avce sauvegarde

ChangeInputStart:									
		lds		Work,TCCR3B							; si le timer 3 ne tourne pas
		andi	Work,0b00000111						; on lance le clignotement de la LED On
		cpi		Work,0								; car on a modifi� la valeur qui �tait stock�e
		brne	MenuTesteStart						
		call	LanceClignotementLED

MenuTesteStart:
		sbrc	StatReg1,FlagIncremente				; regarde dans quel sens allait l'encodeur
		rjmp	IncStartInput						; Vers le haut ?
		sbrc	StatReg1,FlagDecremente				; 
		rjmp	DecStartInput						; vers le bas ?
		rjmp	LoopInpStart						; Aucun des deux, alors cassos

IncStartInput:										; Incr�mentation du num�ro de l'entr�e
		mov		Work,MenuReg1
		cpi		Work,(MaxInput-1)					; derni�re entr�e ?
		brne	DoIncStartInput						; non, alors on peut incr�menter sans pb

;		clr		MenuReg1							; sinon, on le � la premi�re		
		rjmp	MenuAfficheNewInpStart				; et on afficher le nouveau libell� correspondant � l'entr�e
DoIncStartInput:
		inc		MenuReg1							; On incr�mente le registre
		rjmp	MenuAfficheNewInpStart				; et on afficher le nouveau libell� correspondant � l'entr�e

DecStartInput:										; D�cr�mentation du num�ro de l'entr�e
		clr		Work
		cp		MenuReg1,Work						; c'est la premi�re entr�e ?
		brne	DoDecStartInput						; non, alors on peut d�cr�menter sans pb

;		ldi		Work,3								; sinon, on le positionne sur la derni�re entr�e	
;		mov		MenuReg1,Work
		rjmp	MenuAfficheNewInpStart				; et on affiche le nouveau libell� correspondant � l'entr�e

DoDecStartInput:
		dec		MenuReg1							; On d�cr�mente le registre
		rjmp	MenuAfficheNewInpStart				; et on afficher le nouveau libell� correspondant � l'entr�e

MenuAfficheNewInpStart:								; Nouvelle entr�e, nouveau libell�

		cbr		StatReg1,EXP2(FlagIncremente)		; On commence par remettre � 0 les flags de l'encodeur
		cbr		StatReg1,EXP2(FlagDecremente)

		rjmp	MenuStartEEPROMSeek					; et on va chercher le libell� en EEPROM

ExitMenuEntreeStartSave:
		call 	Attendre							; On attend pour le d�bounce
		sbic	PinMenu,SwitchMenu					; C'est un vrai appui sur Standby/On pour sortir ?
		rjmp	LoopInpStart 						; Non, fausse arlette et on replonge dans la boucle

WaitBeforeExitMenuEntreeStartSave:
		sbis	PinMenu,SwitchMenu					; petit test habituel pour ne pas effectuer
		rjmp	WaitBeforeExitMenuEntreeStartSave	; des sorties de menu en cascade

		call	ArreteClignotementLED				; Au cazo�, on rallume la LED de On/StandBy

		ldi		Work,SaveLong						; Fixe le temps d'affichage du prochain message
		call	AfficheSaving						; Affiche le message de sauvegarde

; -- Sauvegarde de la nouvelle valeur

; -- En RAM

		ldi		ZH,RAM_Start
 		ldi		ZL,RAM_StartInput 					; R�cup�re en RAM l'indicateur d'entr�e sym�trique
		st		Z,MenuReg1							; et sauvegarde la valeur en RAM

; -- En EEPROM

		ldi		Work,EE_StartInput					; Position dans l'EEPROM
		mov		Work2,MenuReg1						; Valeur transf�r�e dans Work2 pour la routine d'EEPROM
		call	WriteEEprom							; et on �crit

		ret											; et on se casse de ce menu

ExitMenuEntreeStartNoSave:
		sbis	PinSwitchMC,SwitchMC				; Petit test habituel pour ne pas effectuer
		rjmp	ExitMenuEntreeStartNoSave			; des sorties de menu en cascade

		call	ArreteClignotementLED				; Au cazo�, on rallume la LED de On/StandBy

		ret											; on se casse de ce menu

; =====================================================
; == Affichage du nom de l'entr�e consid�r�e         ==
; == Le num�ro de l'entr�e est dans MenuReg1         ==
; ==                                                 ==
; == On en profite pour stocker le libell� en RAM,   ==
; == Pour le cas o� on voudrait l'�diter juste apr�s ==
; =====================================================

MenuAfficheNomEntree:

		ldi		Work1,EE_TitreIn1					; On se place au d�but de la zone des libell�s en EEPROM

		mov		Work,MenuReg1						; Copie le num�ro de l'entr�e �dit�e
		lsl		Work								; 
		lsl		Work								; 4 Shifts left -> Multiplication par 16
		lsl		Work
		lsl		Work
		add		Work1,Work							; Auquel on ajoute l'adresse de d�part pour pointer sur le bon libell�

		ldi		ZH,RAM_Start
 		ldi		ZL,RAM_TitreActif 					; R�cup�re en RAM l'adresse de d�but du libell� � �diter

		clr 	Count1								; 8 caract�res � r�cup�rer
				
MenuCopieLibelles:
		out		EEARL,Work1							; Adresse � atteindre en EEPROM
	    sbi		EECR,EERE							; Pr�pare l'EEPROM � la lecture
		in		Work,EEDR							; lit la valeur en EEPROM et la met dans le registre Work

		st		Z+,Work								; et stocke la valeur en RAM, avec incr�mentation automatique de l'adresse

		inc		Work1								; incr�mente l'adresse en EEPROM
		inc		Count1								; Incr�mente le compteur de caract�res

		cpi		Count1,NameSize						; teste si on a fini de lire tous les caract�res
		brne	MenuCopieLibelles					; et boucle on n'a pas tout lu

		ldi		ZH,RAM_Start
 		ldi		ZL,RAM_TitreActif 					; On se replace au d�but de la chaine en RAM

		ldi		Count1,NameSize						; 12 caract�res � �crire
				
		ldi		Work,0x40+(DisplaySize-NameSize)/2	; On va centrer l'initul�, encadr� par des ' " '
		call	DisplayPlaceCurseur					; Met le curseur en bonne position	

MenuEcritLibelle:
		ld		Char,Z+								; R�cup�re le caract�re et incr�mente l'adresse en RAM
		call	DisplayWriteChar					; et on l'�crit
		dec 	Count1								; Arriv� au 8�me caract�re ?
		brne	MenuEcritLibelle					;	 -Non, on continue la boucle

		ret											; et c'est fini

; ==============================================
; == Affichage du type de l'entr�e consid�r�e ==
; == Le num�ro de l'entr�e est dans MenuReg1  ==
; ==============================================

MenuAfficheTypeEntree:

		ldi		Work,0x40							; D�but de seconde ligne
		call	DisplayPlaceCurseur

		mov		Work2,MenuReg2						; On transf�re la valeur dans MenuReg2

		cpi		Work2,0								; C'est une entr�e sym�trique ?
		brne	MenuInputEcrireRCA					; 	- Non (Valeur non nulle)

		ldi		ZH,HIGH(MenuInputBalMessage*2)
		ldi		ZL,LOW(MenuInputBalMessage*2)
		call	DisplayAfficheChaine
		call	DisplayArrow

		ret											; �vouala

MenuInputEcrireRCA:
		ldi		ZH,HIGH(MenuInputUnBalMessage*2)
		ldi		ZL,LOW(MenuInputUnBalMessage*2)
		call	DisplayAfficheChaine
		call	DisplayArrow


		ret											; �c�tou

; ====================================================
; == Affiche si on augmente ou non le volume de 6dB ==
; == pour l'entr�e consid�r�e                       ==
; == Le num�ro de l'entr�e est dans MenuReg1        ==
; ====================================================

MenuAffiche6dB:

		ldi		Work,0x40							; D�but de seconde ligne
		call	DisplayPlaceCurseur

		mov		Work2,MenuReg2
		cpi		Work2,0								; 6dB en plus ?
		breq	MenuInputEcrire6dBNo				; 	- Non (Valeur � 0)

		ldi		ZH,HIGH(MenuInput6dBOnMessage*2)
		ldi		ZL,LOW(MenuInput6dBOnMessage*2)
		call	DisplayAfficheChaine
		call	DisplayArrow

		ret											; �vouala

MenuInputEcrire6dBNo:
		ldi		ZH,HIGH(MenuInput6dBOffMessage*2)
		ldi		ZL,LOW(MenuInput6dBOffMessage*2)
		call	DisplayAfficheChaine
		call	DisplayArrow

		ret											; �c�fini

; =================================================
; == Affiche le trigger pour l'entr�e consid�r�e ==
; == Le num�ro de l'entr�e est dans MenuReg1     ==
; =================================================

MenuAfficheTrig:

		ldi		Work,0x40							; D�but de seconde ligne
		call	DisplayPlaceCurseur

		mov		Work2,MenuReg2
		cpi		Work2,0								; Y'a un trigger ?
		breq	MenuInputEcrireNo					; 	- Non (Valeur � 0)

		ldi		ZH,HIGH(MenuInputTrigOnMessage*2)
		ldi		ZL,LOW(MenuInputTrigOnMessage*2)
		call	DisplayAfficheChaine
		call	DisplayArrow

		ret											; �vouala

MenuInputEcrireNo:
		ldi		ZH,HIGH(MenuInputTrigOffMessage*2)
		ldi		ZL,LOW(MenuInputTrigOffMessage*2)
		call	DisplayAfficheChaine
		call	DisplayArrow

		ret											; �c�fini

; ===========================================================================
; == Teste si l'entr�e dont on vient de modifier le type                   ==
; == est l'entr�e active, et modifie le relais de Bal/Unbal en cons�quence ==
; ===========================================================================

MenuCheckActiveInput:

		ldi		ZH,RAM_Start
		ldi		ZL,RAM_EntreeActive
		ld		Work1,Z								; r�cup�re l'entr�e � afficher dans le registre Work1

		cpse	MenuReg1,Work1						; ce sont les m�mes ?
		ret											; Non	-> On termine normalement

		ldi		ZH,RAM_Start
 		ldi		ZL,RAM_BalIn1 						; R�cup�re en RAM l'indicateur d'entr�e sym�trique
		add		ZL,MenuReg1							; Shifte pour pointer au bon endroit dans la RAM
		ld		Work2,Z								; et r�cup�re la valeur dans Work2

		cpi		Work2,0								; C'est une RCA ?
		breq	MenuInputNewTypeXLR					; Non, c'est du XLR	

		sbr		StatReg1,EXP2(FlagAsym)				; Oui, alors passe les flags correspondants � 1
		lds		Work,PortAutresRelais				; R�cup�re l'�tat des autres relais sur le m�me port
		sbr		Work,EXP2(RelaisAsym)				; Et fait passer � 1 le relais de dissym�trisation
		sts		PortAutresRelais,Work				; et on met �a dans le relais
		ret											; et bye

MenuInputNewTypeXLR:
		cbr		StatReg1,EXP2(FlagAsym)
		lds		Work,PortAutresRelais				; R�cup�re l'�tat des autres relais sur le m�me port
		cbr		Work,EXP2(RelaisAsym)				; Et les fait passer � 0
		sts		PortAutresRelais,Work				; et on met �a dans le relais

		ret											; et bye

; ======================================================================
; == Teste si on vient de modifier le comportement de l'entr�e active ==
; == et si c'est le cas, v�rifie si il faut y ajouter 6dB             ==
; ======================================================================

MenuCheckActiveInput6dB:

		ldi		ZH,RAM_Start
		ldi		ZL,RAM_EntreeActive
		ld		Work1,Z								; r�cup�re l'entr�e � afficher dans le registre Work1

		cpse	MenuReg1,Work1						; ce sont les m�mes ?
		ret											; Non	-> On termine normalement

		call	Want6dBMore							; Oui   -> On va tester si il faut ajouter 6dB
		call	SetVolume							; 		   et on actualise le volume

		ret											; et bye

; =========================================================
; == Choix de l'entr�e � bypasser au repos               ==
; ==                                                     ==
; ==    - L'encodeur commute entre les entr�es           ==
; ==    - Validation par le bouton de menu               ==
; ==    - Et la sortie/annulation par le bouton StandBy  ==
; =========================================================

MenuBypassInput:

WaitMenuEntreeBypass:
		sbis	PinMenu,SwitchMenu					; Avant de passer � la suite,
		rjmp	WaitMenuEntreeBypass				; On attend le relachement du bouton de menu

; Bouton rel�ch�, on continue

		ldi		ZH,RAM_Start
		ldi		ZL,RAM_In_Bypass
		ld		MenuReg1,Z							; Charge le num�ro de l'entr�e bypass�e

		ldi		Work,0								; Message de la premi�re ligne
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuPrefInpBypassMessage*2)
		ldi		ZL,LOW(MenuPrefInpBypassMessage*2)
		call	DisplayAfficheChaine

MenuBypassAfficheLigne2:
		ldi		Work,0x40							; d�but de seconde ligne
		call	DisplayPlaceCurseur

		mov		Work,MenuReg1						; R�cup�re la valeur de cette entr�e bypass�e
		cpi		Work,4								; On v�rifie que le bypass existe (4 -> Pas de bypass)
		brne	MenuBypassNormal

		ldi		ZH,HIGH(MenuPrefInpNoBypassMessage*2); Chaine � afficher
		ldi		ZL,LOW(MenuPrefInpNoBypassMessage*2)
		call	DisplayAfficheChaine
		call	DisplayArrow
		rjmp	LoopInpBypass

MenuBypassNormal:
		ldi		ZH,HIGH(MenuPrefInpNameMessage*2)	; Chaine � afficher
		ldi		ZL,LOW(MenuPrefInpNameMessage*2)
		call	DisplayAfficheChaine
		call	DisplayArrow

; On affiche le libell� de l'entr�e bypass�e depuis l'EEPROM

MenuBypassEEPROMSeek:
		ldi		Work1,EE_TitreIn1					; On se place au d�but de la zone des libell�s en EEPROM
		clr		Work

		ldi		Work1,EE_TitreIn1					; On se place au d�but de la zone des libell�s en EEPROM
		mov		Work,MenuReg1						; Copie le num�ro de l'entr�e �dit�e
		lsl		Work								; 
		lsl		Work								; 4 Shifts left -> Multiplication par 16
		lsl		Work
		lsl		Work
		add		Work1,Work							; Auquel on ajoute l'adresse de d�part pour pointer sur le bon libell�

MenuBypassLib:										; Arriv� ici, l'adresse de d�but du libell� est dans Work1
		ldi		Count1,NameSize						; 12 caract�res � �crire
		ldi		Work,0x46							; On se place sur la seconde ligne, au 5�me caract�re pour centrer les 12 cacat�res
		call	DisplayPlaceCurseur					; Met le curseur en bonne position	

MenuEcritBypassLib:
		out		EEARL,Work1							; Adresse � atteindre en EEPROM
	    sbi		EECR,EERE							; Pr�pare l'EEPROM � la lecture
		in		Char,EEDR							; lit la valeur en EEPROM et la met dans le registre Work

		call	DisplayWriteChar					; et on l'�crit
		inc		Work1								; On incr�mente l'adresse EEPROM
		dec 	Count1								; Arriv� au 12�me caract�re ?
		brne	MenuEcritBypassLib					;	 -Non, on continue la boucle

		ldi		Work,0x43							; Cuseur en 4�me position
		call	DisplayPLaceCurseur
		mov		Char,MenuReg1						; affiche le N� de l'entr�e
		subi	Char,-49
		call	DisplayWriteChar

; -- Boucle pour le changement de l'entr�e bypass�e --

LoopInpBypass:

		call 	LectureEncodeur						; Lecture de l'encodeur
		sbrs	StatReg1,FlagIncremente				; doit-on incr�menter
		sbrc	StatReg1,FlagDecremente				; ou d�cr�menter ?
		rjmp	ChangeInputBypass					; l'un des deux...

		sbis	PinSwitchMC,SwitchMC				; Un appui sur le bouton d'annulation pour sortir sans sauvegarde ?
		rjmp	ExitMenuEntreeBypassNoSave			; 	- Oui, alors on y va

		sbic	PinMenu,SwitchMenu					; Un appui sur Menu pour valider/sortir ?
		rjmp 	LoopInpBypass						; Non, on boucle

		call	Attendre							; On attend un peu...
		sbic	PinMenu,SwitchMenu					; Menu toujours appuy� ?
		rjmp 	LoopInpBypass						; Non, on boucle

		rjmp	ExitMenuEntreeBypassSave			; Sortie avec sauvegarde

ChangeInputBypass:									
		lds		Work,TCCR3B							; si le timer 3 ne tourne pas
		andi	Work,0b00000111						; on lance le clignotement de la LED On
		cpi		Work,0								; car on a modifi� la valeur qui �tait stock�e
		brne	MenuTesteBypass						
		call	LanceClignotementLED

MenuTesteBypass:
		sbrc	StatReg1,FlagIncremente				; regarde dans quel sens allait l'encodeur
		rjmp	IncBypassInput						; Vers le haut ?
		sbrc	StatReg1,FlagDecremente				; 
		rjmp	DecBypassInput						; vers le bas ?
		rjmp	LoopInpBypass						; Aucun des deux, alors cassos

IncBypassInput:										; Incr�mentation du num�ro de l'entr�e
		mov		Work,MenuReg1
		cpi		Work,MaxInput   					; derni�re entr�e ?
		brne	DoIncBypassInput					; non, alors on peut incr�menter sans pb

;		clr		MenuReg1							; sinon, on le � la premi�re		
		rjmp	MenuAfficheNewInpBypass				; et on afficher le nouveau libell� correspondant � l'entr�e
DoIncBypassInput:
		inc		MenuReg1							; On incr�mente le registre
		rjmp	MenuAfficheNewInpBypass				; et on afficher le nouveau libell� correspondant � l'entr�e

DecBypassInput:										; D�cr�mentation du num�ro de l'entr�e
		clr		Work
		cp		MenuReg1,Work						; c'est la premi�re entr�e ?
		brne	DoDecBypassInput					; non, alors on peut d�cr�menter sans pb

		rjmp	MenuAfficheNewInpBypass				; et on affiche le nouveau libell� correspondant � l'entr�e

DoDecBypassInput:
		dec		MenuReg1							; On d�cr�mente le registre
		rjmp	MenuAfficheNewInpBypass				; et on afficher le nouveau libell� correspondant � l'entr�e

MenuAfficheNewInpBypass:								; Nouvelle entr�e, nouveau libell�

		cbr		StatReg1,EXP2(FlagIncremente)		; On commence par remettre � 0 les flags de l'encodeur
		cbr		StatReg1,EXP2(FlagDecremente)

		rjmp	MenuBypassAfficheLigne2				; et on va chercher quoi afficher en ligne 2

ExitMenuEntreeBypassSave:
		call 	Attendre							; On attend pour le d�bounce
		sbic	PinMenu,SwitchMenu					; C'est un vrai appui sur l'annulation pour sortir ?
		rjmp	LoopInpBypass						; Non, fausse arlette et on replonge dans la boucle

WaitBeforeExitMenuEntreeBypassSave:
		sbis	PinMenu,SwitchMenu					; petit test habituel pour ne pas effectuer
		rjmp	WaitBeforeExitMenuEntreeBypassSave	; des sorties de menu en cascade

		call	ArreteClignotementLED				; Au cazo�, on rallume la LED de On/StandBy

		ldi		Work,SaveLong						; Fixe le temps d'affichage du prochain message
		call	AfficheSaving						; Affiche le message de sauvegarde

; -- Sauvegarde de la nouvelle valeur

; -- En RAM

		ldi		ZH,RAM_Start
 		ldi		ZL,RAM_In_Bypass 					; R�cup�re l'adresse
		st		Z,MenuReg1							; et sauvegarde la valeur en RAM

; -- En EEPROM

		ldi		Work,EE_In_Bypass					; Position dans l'EEPROM
		mov		Work2,MenuReg1						; Valeur transf�r�e dans Work2 pour la routine d'EEPROM
		call	WriteEEprom							; et on �crit

		ret											; et on se casse de ce menu

ExitMenuEntreeBypassNoSave:
		sbis	PinSwitchMC,SwitchMC				; Petit test habituel pour ne pas effectuer
		rjmp	ExitMenuEntreeBypassNoSave			; des sorties de menu en cascade

		call	ArreteClignotementLED				; Au cazo�, on rallume la LED de On/StandBy

		ret											; on se casse de ce menu

; ==================================================================================================
; == Routine pour sauter certains caract�res non utiles dans la table de caract�re de l'afficheur ==
; == Utilis� pour l'OPTREX seulement                                                              ==
; ==================================================================================================

TestDisplayIncASCII:
		inc		Char								; On incr�mente le registre
		cpi		Char,8								; Saute la zone 8-15
		brne	IncTestChar128						; va tester la zone 128-160
		ldi		Char,32								
		ret
IncTestChar128:
		cpi		Char,128							; Pour sauter une zone non d�finie
		brne	IncTestChar166						; dans la m�moire du Display (entre 128 et 160 compris)
		ldi		Char,161
		ret											; et on va afficher la chaine qu'il faut
IncTestChar166:										; Saute les caract�res japonais (166-175)
		cpi		Char,166
		brne	IncTestChar177
		ldi		Char,176
		ret											; et on va afficher la chaine qu'il faut
IncTestChar177:										; Garde le 176 et saute 177-222
		cpi		Char,177
		brne	IncTestBye
		ldi		Char,223
IncTestBye:
		ret											; et on se casse
		

TestDisplayDecASCII:								; D�cr�mentation du num�ro de menu
		dec		Char								; On d�cr�mente le registre
		cpi		Char,222
		brne	DecTestChar175
		ldi		Char,176
		ret
DecTestChar175:
		cpi		Char,175
		brne	DecTestChar160
		ldi		Char,165
		ret
DecTestChar160:
		cpi		Char,160
		brne	DecTestChar31
		ldi		Char,127
		ret
DecTestChar31:
		cpi		Char,31
		brne	DecTestBye
		ldi		Char,7
DecTestBye:
		ret

; ---------------------------------------------------------
; --                                                     --
; -- Affichage de la correction de volume sur une entr�e --
; --                                                     --
; -- La valeur � afficher est dans MenuReg2              --
; -- Si le bit 7 est � 1, la valeur est n�gative         --
; -- et si elle est � z�ro, c'est positif                --
; --                                                     --
; ---------------------------------------------------------

MenuAfficheInpVol:

; On commence par effacer l'ancienne valeur en r��crivant toute la ligne

		ldi		Work,0x40							; d�but de seconde ligne
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuInpVolValMessage*2)		; Chaine � afficher
		ldi		ZL,LOW(MenuInpVolValMessage*2)
		call	DisplayAfficheChaine
		call	DisplayArrow

	    ldi		Work,0x4A							; On se place au bon endroit
		call	DisplayPlaceCurseur					; pour �crire la valeur

		sbrs	MenuReg2,7							; C'est une valeur n�gative ?
		rjmp	MenuTestTrimPlus		    		; Non, c'est positif (ou nul)
		
		ldi		Char,'-'							; Oui, c'est n�gatif
		call	DisplayWriteChar					; et on commence par �crire un '-'
		rjmp	MenuAfficheTrimValue

MenuTestTrimPlus:
	    ldi		Work,0								; V�rifie que ce n'est pas une valeur nulle 
		cp		Work,MenuReg2
		brne 	TrimPlus							; C'est pas z�ro

		ldi		Char,32								; Sinon, on n'�crit pas de signe
		call	DisplayWriteChar
		rjmp	MenuAfficheTrimValue

TrimPlus:
		ldi		Char,'+'							; Ecrit le "+"
		call	DisplayWriteChar

MenuAfficheTrimValue:
		mov		Work,MenuReg2						; Copie la valeur dans un reistre de travail
		cbr		Work,0b10000000						; Efface le bit de signe pour ne garder que la valeur

; -- On convertit la valeur en d�cimal --

		mov		Work3,Work							; 3 additions -> Multiplication par 3
		add		Work3,Work							; 
		add		Work3,Work							; la valeur max est 3x8 donc on n'a pas besoin du bit de carry... 

		mov		Work2,Work3							; Conserve la valeur, on va en avoir besoin car les deux derniers bits vont �tre perdus durant le d�calage � droite
		lsr		Work3								; Premi�re division par 2,pas besoin de shifter le bit de "Carry"
		lsr		Work3								; Seconde division par deux

		andi	Work2,0b00000011					; on ne garde que les deux bits qui auraient �t� perdus lors du shift
		mov		LSDVol,Work3						; et le nombre "principal"

; Arriv�s ici, on a le r�sultat de l'op�ration dans LSDVol et les d�cimales dans Work2

		call	BinaireToBCD						; transforme �a en un nombre � deux chiffres (MSDVol et LSDVol)

		mov		Char,LSDVol				
		call	DisplayWriteChar					; Affiche le chiffre des unit�s

		ldi		Char,'.'							; Affiche le point d�cimal
		call	DisplayWriteChar

; -- On s'attaque maintenant aux d�cimales (contenues dans Work2)

		cpi		Work2,0								; Si on a z�ro, c'est '00' qu'il faut afficher
		brne	NextTenthTrim1						; c'est pas z�ro

		ldi		Char,'0'							; Deux �critures de "0"
		call	DisplayWriteChar
		call	DisplayWriteChar
		rjmp	TrimFinDB

NextTenthTrim1:	

		cpi		Work2,1								; si on a 1, c'est "0.25"
		brne	NextTenthTrim2						; c'est pas �a

		ldi		Char,'2'							; on �crit "25"
		call	DisplayWriteChar
		ldi		Char,'5'
		call	DisplayWriteChar
		rjmp	TrimFinDB

NextTenthTrim2:	

		cpi		Work2,2								; si on a 2, c'est "0.50"
		brne	NextTenthTrim3						; c'est toujours pas �a

		ldi		Char,'5'							; on �crit "50"
		call	DisplayWriteChar
		ldi		Char,'0'
		call	DisplayWriteChar
		rjmp	TrimFinDB

NextTenthTrim3:										; arriv� ici, c'est s�rement 3, donc il faut �crire "0.75"

		ldi		Char,'7'							; on �crit "50"
		call	DisplayWriteChar
		ldi		Char,'5'
		call	DisplayWriteChar

TrimFinDB:											; Termine en �crivant 'dB'

		ldi		Char,'d'
		call	DisplayWriteChar
		ldi		Char,'B'
		call	DisplayWriteChar

		ret											; Et mission accomplie

; ==============================================
; == R�cup�re la valeur du volume avant modif ==
; ==============================================

MenuRecupereVolume:

		ldi		ZL,RAM_ModVol_In1					; Quelle valeur de modif de volume avait-on ?
		add		ZL,MenuReg1							; Pointe sur la bonne entr�e
		ld		Work2,Z

		cpi		Work2,0								; Si c'�tait z�ro
		breq	MenuStoreVol						; on ne change rien

		sbrs	Work2,7								; Sinon, on teste si c'�tait une valeur n�gative (bit 7 � 1) 
	    rjmp	MenuInputVolWasMore					; ou positive (bit 7 � 0)
		rjmp	MenuInputVolWasLess

MenuInputVolWasMore:
		cp		VolReg,Work2						; Avant de soustraire la valeur, on v�rifie qu'on peut bien l'enlever
		brlo	MenuOldVol2Min						; sinon, on met le volume au mini

		sub		VolReg,Work2						; On peut bien soustraire
		rjmp	MenuStoreVol

MenuOldVol2Min:
		clr		VolReg								; Volume au mini
		rjmp	MenuStoreVol						; et on passe au volume de la nouvelle entr�e

MenuInputVolWasLess:								; On avait enlev� du volume
		cbr		Work2,0b10000000					; on met le bit 7 � 0
		ldi		Work,VolumeMaxi						; On regarde si on peut rajouter 
		sub		Work,Work2							; la valeur de modif sans overflow
		cp		VolReg,Work
		brsh	MenuOldVol2Max						; sinon, on met le volume au maxi

		add		VolReg,Work2						; On rajoute la valeur qu'on avait retranch�e
		rjmp	MenuStoreVol						; et on passe au nouveau volume

MenuOldVol2Max:
		ldi		Work,VolumeMaxi						; sinon on met au maxi
		mov		VolReg,Work							; et on passe � la suite

MenuStoreVol:
		ldi		ZH,RAM_Start						; Stocke en RAM
		ldi		ZL,RAM_TempVolume					; le volume non corrig�
		st		Z,VolReg

		ret

				
