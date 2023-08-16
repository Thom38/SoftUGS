; ============================================================
; == Routines pour la gestion des param�tres en EEPROM      ==
; ==                                                        ==
; ==   - Encodeur -> Navigation dans les options            ==
; ==   - Menu     -> Entrer dans une option                 ==
; ==   - StandBy  -> Remonter au menu pr�c�dent sans sauver ==
; ==                                                        ==
; ============================================================

MenuEEProm:

		sbis	PinMenu,SwitchMenu					; Avant de passer � la suite,
		rjmp	MenuEEProm							; On attend le relachement du bouton de menu

; OK, on a l�ch� le bouton

		ldi		Work,0								; D�but de premi�re ligne
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuEEPROMSetup*2)
		ldi		ZL,LOW(MenuEEPROMSetup*2)
		call	DisplayAfficheChaine

		ldi		Work,0x40							; on se place
		call	DisplayPlaceCurseur					; sur la seconde ligne de l'afficheur
		ldi		ZH,HIGH(MenuEEPromRestoreFactory*2)
		ldi		ZL,LOW(MenuEEPromRestoreFactory*2)
		call	DisplayAfficheChaine				; affiche le "message" de l'encodeur 
		call	DisplayArrow						; et les fl�ches de l'encodeur

		clr		MenuReg1

; Lit d'abord le contenu de la premi�re adresse destin�e � l'�criture

; Pour la premi�re zone (Memory1)

MenuCheckUserEEprom1:
		sbic	EECR,EEWE							; Si EEWE n'est pas � 0
		rjmp	MenuCheckUserEEprom1				; on attend

; D�but de la zone de lecture (0x0200)
		ldi		ZH,Memory1							; Adresse haute 
		clr 	ZL									; Adresse basse

		out		EEARH,ZH
		out     EEARL,ZL	  	                    ; On charge "l'adresse" pour l'EEPROM

		sbi		EECR,EERE							; Signale � l'EEPROM qu'on veut lire
													; (4 cycles d'horloge)
		in		Work2,EEDR						; r�cup�re la donn�e

		clr		Work								; On r�tablit l'adresse haute de l'EEPROM
		out		EEARH,Work							; dans la zone "normale" (0x0000)

; Pour la seconde zone (memory2)

MenuCheckUserEEprom2:
		sbic	EECR,EEWE							; Si EEWE n'est pas � 0
		rjmp	MenuCheckUserEEprom2				; on attend

; D�but de la zone de lecture (0x0400)
		ldi		ZH,Memory2							; Adresse haute 
		clr 	ZL									; Adresse basse

		out		EEARH,ZH
		out     EEARL,ZL	  	                    ; On charge "l'adresse" pour l'EEPROM

		sbi		EECR,EERE							; Signale � l'EEPROM qu'on veut lire
													; (4 cycles d'horloge)
		in		Work3,EEDR							; r�cup�re la donn�e

		clr		Work								; On r�tablit l'adresse haute de l'EEPROM
		out		EEARH,Work							; dans la zone "normale" (0x0000)

; On regarde ce qu'on a r�colt�

		clr 	Work
		cpi		Work2,Vide							; Premi�re zone vide ?
		breq	MenuEETestZ2						;   -Yes, on teste la seconde zone
		ldi		Work,0x0F							;   - No -> 4 bits � 1 pour la premi�re zone
MenuEETestZ2:
		cpi		Work3,Vide							; Seconde zone vide ?
		breq	MenuEEMems							;  - Oui -> On conserve le r�sultat
		sbr		Work,0b11110000						;  - Non -> 4 bits de plus � 1
MenuEEMems:
		cpi		Work,0
		breq	MenuEE0M10M2
		cpi		Work,0x0F
		breq	MenuEE1M10M2
		cpi		Work,0xF0
		breq	MenuEE0M11M2
		cpi		Work,0xFF
		breq	MenuEE1M11M2

MenuEE0M10M2:
		ldi		Work2,0
		mov		MenuReg2,Work2
		rjmp	LoopLevelEE0

MenuEE1M10M2:
		ldi		Work2,1
		mov		MenuReg2,Work2
		rjmp	LoopLevelEE0

MenuEE0M11M2:
		ldi		Work2,2
		mov		MenuReg2,Work2
		rjmp	LoopLevelEE0

MenuEE1M11M2:
		ldi		Work2,3
		mov		MenuReg2,Work2

LoopLevelEE0:
		call 	LectureEncodeur						; Lecture de l'encodeur
		sbrs	StatReg1,FlagIncremente				; doit-on incr�menter
		sbrc	StatReg1,FlagDecremente				; ou d�cr�menter ?
		rjmp	ChangeEEPromMenu					; l'un des deux...

		sbis	PinSwitchMC,SwitchMC				; Un appui sur l'annulation pour sortir ?
		rjmp	ExitEEPromMenu						; Oui, alors on y va

		sbic	PinMenu,SwitchMenu					; Un appui sur Menu ?
		rjmp 	LoopLevelEE0						; Non, on boucle

		call	Attendre							; On attend un peu...
		sbic	PinMenu,SwitchMenu					; Menu toujours appuy� ?
		rjmp 	LoopLevelEE0						; Non, on boucle

		rjmp	WhatEEPromMenuToEnter				; sinon on entre dans le menu de config qu'il faut
			
ChangeEEPromMenu:

		sbrc	StatReg1,FlagIncremente				; regarde dans quel sens allait l'encodeur
		rjmp	IncEEMenuReg1						; Vers le haut ?
		sbrc	StatReg1,FlagDecremente				; 
		rjmp	DecEEMenuReg1						; vers le bas ?
		rjmp	LoopLevelEE0						; Aucun des deux, alors cassos

IncEEMenuReg1:										; Incr�mentation du num�ro de menu
		mov		Work,MenuReg1
		cpi		Work,2
		brlo	DoIncEEMR1

		mov		Work2,MenuReg2

		cpi		Work,2
		brne	IncEETest3

		cpi		Work2,0
		breq	IncEERAZ

		cpi		Work2,1
		breq	DoIncEEMR1

		cpi		Work2,2
		breq	IncEETwo	

		cpi		Work2,3
		breq	DoIncEEMR1

IncEETest3:
		cpi		Work,3
		brne	IncEERAZ

		cpi		Work2,1
		breq	IncEERAZ

		cpi		Work2,2
		breq	DoIncEEMR1

		cpi		Work2,3
		breq	DoIncEEMR1

IncEERAZ:
		ldi		Work,0
		mov		MenuReg1,Work
		rjmp 	AfficheMenuEE0

IncEETwo:
		ldi		Work,4
		mov		MenuReg1,Work
		rjmp	AfficheMenuEE0

DoIncEEMR1:
		inc		MenuReg1							; On incr�mente le registre
		rjmp	AfficheMenuEE0						; et on va afficher la chaine qu'il faut

DecEEMenuReg1:										; D�cr�mentation du num�ro de menu
		mov		Work,MenuReg1						; transfert dans un registre imm�diat
		mov		Work2,MenuReg2
		cpi		Work,0
		breq	DecEEToMax

		cpi		Work,4								; c'est le dernier menu ?
		brlo	DoDecEEMR1							; non, alors on peut d�cr�menter sans pb

		cpi		Work2,2
		breq	DecEEToMax2

		rjmp	DoDecEEMR1

DecEEToMax:
		cpi		Work2,0
		breq	DecEEtoMax2
		cpi		Work2,1
		breq	DecEEtoMax3
		ldi		Work,4
		mov		MenuReg1,Work
		rjmp	AfficheMenuEE0

DecEEToMax2:
		ldi		Work,2
		mov		MenuReg1,Work
		rjmp	AfficheMenuEE0

DecEEToMax3:
		ldi		Work,3
		mov		MenuReg1,Work
		rjmp	AfficheMenuEE0

DoDecEEMR1:
		dec		MenuReg1							; On d�cr�mente le registre

AfficheMenuEE0:										; affiche le menu correspondant au contenu de MenuReg1 (entre 0 et 2)
		cbr		StatReg1,EXP2(FlagIncremente)		; On commence par remettre � 0 les flags de l'encodeur
		cbr		StatReg1,EXP2(FlagDecremente)

		ldi		Work,0x40							; On se place en d�but de seconde ligne
		call	DisplayPlaceCurseur

		mov		Work,MenuReg1						; On met le registre dans un registre imm�diat

TestMenuEEFactory:

		cpi		Work,0								; C'est 0 ?
		brne	TestMenuEESU						; Nan...

		ldi		ZH,HIGH(MenuEEPromRestoreFactory*2)	; Oui, c'est 0
		ldi		ZL,LOW(MenuEEPromRestoreFactory*2)
		call	DisplayAfficheChaine				; Affiche la premi�re chaine de setup
		call	DisplayArrow						; et les fl�ches de l'encodeur
		rjmp	LoopLevelEE0						; et on continue la boucle

TestMenuEESU:

		cpi		Work,1								; C'est 1 ?
		breq	OKEELU								; Vi...
		cpi		Work,2								; Ou c'est 2 ?
		brne	TestMenuEELU						; Nan...
OKEELU:
		ldi		ZH,HIGH(MenuEEPromSaveUser*2)		; Oui, c'est 1
		ldi		ZL,LOW(MenuEEPromSaveUser*2)
		call	DisplayAfficheChaine				; Affiche la premi�re chaine de setup
		ldi		Work,0x51
		call	DisplayPlaceCurseur
		mov		Char,MenuReg1
		subi	Char,-48
		call	DisplayWriteChar
		call	DisplayArrow						; et les fl�ches de l'encodeur
		rjmp	LoopLevelEE0						; et on continue la boucle

TestMenuEELU:

		ldi		ZH,HIGH(MenuEEPromLoadUser*2)		; Ici c'est 2
		ldi		ZL,LOW(MenuEEPromLoadUser*2)
		call	DisplayAfficheChaine				; Affiche la premi�re chaine de setup
		ldi		Work,0x46
		call	DisplayPlaceCurseur
		mov		Char,MenuReg1
		subi	Char,-46
		call	DisplayWriteChar
		call	DisplayArrow						; et les fl�ches de l'encodeur
		rjmp	LoopLevelEE0						; et on continue la boucle

WhatEEPromMenuToEnter:

		mov		Work,MenuReg1						; Transfert en imm�diat
		cpi		Work,0								; si c'est 0
		breq	EnterMenuEEFactory					; on va restaurer les r�glages d'usine
		cpi		Work,1								; si c'est 1
		breq	EnterMenuEESU						; on va sauvegarder les r�glages en EEPROM1 
		cpi		Work,2								; si c'est 2
		breq	EnterMenuEESU						; on va sauvegarder les r�glages en EEPROM2
		cpi		Work,3								; si c'est 3
		breq	EnterMenuEELU						; on va recharger des r�glages pr�c�demment sauv�s en EEPROM 1
		cpi		Work,4								; si c'est 4
		breq	EnterMenuEELU						; on va recharger des r�glages pr�c�demment sauv�s en EEPROM 2


EnterMenuEEFactory:									; on va restaurer les r�glages d'usine

		call 	Attendre							; On attend un peu
		sbic	PinMenu,SwitchMenu					; Un vrai appui sur le bouton de menu ?
		rjmp	TestMenuEEFactory					; Sinon,on revient au bon endroit

		rcall	MenuEERestoreDefault				; On y va
		call	EEPromToRam							; et on recopie en RAM les nouvelles valeurs en EEPROM


		ldi		Work,0								; Pour le retour -> D�but de premi�re ligne
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuEEPROMSetup*2)
		ldi		ZL,LOW(MenuEEPROMSetup*2)
		call	DisplayAfficheChaine

		ldi		Work,0x40							; on se place
		call	DisplayPlaceCurseur					; sur la seconde ligne de l'afficheur

		clr		Work
		mov		MenuReg1,Work						; On remet la bonne valeur dans MenuReg1
		rjmp	TestMenuEEFactory					; et on revient au bon endroit

EnterMenuEESU:										; on va sauver les pr�f�rences utilisateur

		call 	Attendre							; On attend un peu
		sbic	PinMenu,SwitchMenu					; Un vrai appui sur le bouton de menu ?
		rjmp	TestMenuEESU						; Sinon,on revient au bon endroit
		
		push	MenuReg2							; Sauvegarde MenuReg2
		mov		MenuReg2,MenuReg1
		rcall	MenuEESaveUserSettings				; On y va
		pop		MenuReg2

		ldi		Work,0								; Pour le retour -> D�but de premi�re ligne
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuEEPROMSetup*2)
		ldi		ZL,LOW(MenuEEPROMSetup*2)
		call	DisplayAfficheChaine

		ldi		Work,0x40							; on se place
		call	DisplayPlaceCurseur					; sur la seconde ligne de l'afficheur

		mov		Work,MenuReg1						; On remet la bonne valeur dans MenuReg1
		rjmp	TestMenuEESU						; et on revient au bon endroit

EnterMenuEELU:										; on va restaurer les pr�f�rences utilisateur autres que le d�faut

		call 	Attendre							; On attend un peu
		sbic	PinMenu,SwitchMenu					; Un vrai appui sur le bouton de menu ?
		rjmp	TestMenuEELU						; Sinon,on revient au bon endroit

		push	MenuReg2							; Sauvegarde MenuReg2
		mov		Work,MenuReg1
		subi	Work,2
		mov		MenuReg2,Work
		rcall	MenuEELoadUserSettings				; On y va
		pop		MenuReg2
		call	EEPromToRam							; et on recopie en RAM les nouvelles valeurs en EEPROM

		ldi		Work,0								; Pour le retour -> D�but de premi�re ligne
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuEEPROMSetup*2)
		ldi		ZL,LOW(MenuEEPROMSetup*2)
		call	DisplayAfficheChaine

		ldi		Work,0x40							; on se place
		call	DisplayPlaceCurseur					; sur la seconde ligne de l'afficheur

		mov		Work,MenuReg1						; On remet la bonne valeur dans MenuReg1
		rjmp	TestMenuEELU						; et on revient au bon endroit

ExitEEPromMenu:
		call 	Attendre							; On attend pour le d�bounce
		sbic	PinSwitchMC,SwitchMC				; C'est un vrai appui sur l'annulation pour sortir ?
		rjmp	LoopLevelEE0						; Non, fausse arlette et on replonge dans la boucle

WaitBeforeExitEEMenu:
		sbis	PinSwitchMC,SwitchMC				; petit test habituel pour ne pas effectuer
		rjmp	WaitBeforeExitEEMenu				; des sorties de menu en cascade

		ret											; on se casse de ce menu

; ============================================
; == Restaure les param�tres "usine"        ==
; == Recopie la zone d'EEPROM 0x0600-0x07FF ==
; == dans la zone basse (0x0000-0x01FF)     ==
; ============================================

MenuEERestoreDefault:
		
		sbis	PinMenu,SwitchMenu					; Avant de passer � la suite,
		rjmp	MenuEERestoreDefault				; On attend le relachement du bouton de menu

; Bouton rel�ch�, on continue

		ldi		Work,0								; Se place au d�but
		call	DisplayPlaceCurseur

		ldi		ZH,HIGH(MenuEEPromRestoreFactory*2)	; Message qui convient
		ldi		ZL,LOW(MenuEEPromRestoreFactory*2)
		call	DisplayAfficheChaine


		ldi		Work,0x40							; On est s�r de c'qu'on fait ?
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuEEPromSure*2)
		ldi		ZL,LOW(MenuEEPromSure*2)
		call	DisplayAfficheChaine

MenuWaitEERestore1:
		sbis	PinSwitchMC,SwitchMC				; Un appui sur l'annulation pour sortir sans sauver ?
		rjmp	ExitEERestoreDefaultsCancel			; Oui, alors on y va

		sbic	PinMenu,SwitchMenu					; Un appui sur Menu ?
		rjmp 	MenuWaitEERestore1					; Non, on boucle

		ldi		Work,0x40							; On est VRAIMENT s�r de c'qu'on fait ?
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuEEPromSureSure*2)
		ldi		ZL,LOW(MenuEEPromSureSure*2)
		call	DisplayAfficheChaine

MenuWaitEERestore2:
		call	Attendre
		sbis	PinMenu,SwitchMenu					; Avant de passer � la suite,
		rjmp	MenuWaitEERestore2					; On attend le relachement du bouton de menu

MenuWaitEERestore3:
		sbis	PinSwitchMC,SwitchMC				; Un appui sur l'annulation pour sortir sans sauver ?
		rjmp	ExitEERestoreDefaultsCancel			; Oui, alors on y va

		sbic	PinMenu,SwitchMenu					; Un appui sur Menu ?
		rjmp 	MenuWaitEERestore3					; Non, on boucle

; Bon, ben c'est parti...
		ldi		Work,0x40							; Affiche le message de sauvegarde
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuEEPromLoadingDefaults*2)
		ldi		ZL,LOW(MenuEEPromLoadingDefaults*2)
		call	DisplayAfficheChaine

; D�but de la zone d'�criture (0x0000)
		clr		ZH									; 
		clr		ZL									; 

; D�but de la zone de lecture (0x0600)
		ldi		YH,Default							; Adresse haute de lecture
		clr		YL									; Adresse basse de lecture


; Lecture de l'EEPROM

LoopReadEEpromFactory:
		sbic	EECR,EEWE							; Si EEWE n'est pas � 0
		rjmp	LoopReadEEpromFactory				; on attend

		out     EEARL,YL	  	                    ; On charge "l'adresse" pour l'EEPROM
		out		EEARH,YH
		sbi		EECR,EERE							; Signale � l'EEPROM qu'on veut lire
													; (4 cycles d'horloge)
		in		Work,EEDR							; r�cup�re la donn�e

; Ecriture dans la zone haute de l'EEPROM

	    cli											; inhibe les interruptions
LoopWriteEEpromFactory:
        sbic    EECR,EEWE                   	    ; On attend que l'EEprom soit pr�te pour l'�criture
        rjmp    LoopWriteEEpromFactory
        
		out     EEARL,ZL		                    ; On charge "l'adresse" pour l'EEPROM
		out		EEARH,ZH
		out     EEDR,Work	                        ; ainsi que la donn�e
        
        sbi     EECR,EEMWE                         	; Master Write Enable
        sbi     EECR,EEWE                         	; On �crit dans l'EEPROM (arr�te le CPU pendant 2 cycles)
	    sei											; R�autorise les interruptions

		adiw	YL,0x01								; Incr�mente les adresses de lecture
		adiw	ZL,0x01								; et d'�criture

		cpi		YH,Default+2						; Tant qu'on n'a pas atteint la fin de la zone de lecture
		brne	LoopReadEEpromFactory				; On continue la boucle

		clr		Work								; R�tablit l'adresse haute de l'EEPROM
		out		EEARH,Work		

LoopReadEEpromFactoryExit:
		sbic	EECR,EEWE							; Si EEWE n'est pas � 0
		rjmp	LoopReadEEpromFactoryExit			; on attend

		ret

ExitEERestoreDefaultsCancel:
		sbis	PinSwitchMC,SwitchMC				; petit test habituel pour ne pas effectuer
		rjmp	ExitEERestoreDefaultsCancel			; des sorties de menu en cascade

		ret

; ========================================================================
; == Sauvegarde les pr�f�rences utilisateur dans une zone de l'EEPROM   ==
; == Lecture de 0x0000-0x01FF et �criture en 0x0200-0x03FF (MenuReg2=1) ==
; == ou en 0x0400-0x05FF (MenuReg=2)                                    ==
; ========================================================================

MenuEESaveUserSettings:

		sbis	PinMenu,SwitchMenu					; Avant de passer � la suite,
		rjmp	MenuEESaveUserSettings				; On attend le relachement du bouton de menu

; Bouton rel�ch�, on continue

		ldi		Work,0								; Se place au d�but
		call	DisplayPlaceCurseur

		ldi		ZH,HIGH(MenuEEPromSaveUser*2)		; Message qui convient
		ldi		ZL,LOW(MenuEEPromSaveUser*2)
		call	DisplayAfficheChaine
		ldi		Work,0x11
		call	DisplayPlaceCurseur
		mov		Char,MenuReg2
		subi	Char,-48
		call	DisplayWriteChar

		ldi		Work,0x40							; On est s�r de c'qu'on fait ?
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuEEPromSure*2)
		ldi		ZL,LOW(MenuEEPromSure*2)
		call	DisplayAfficheChaine

MenuWaitEESU1:
		sbis	PinSwitchMC,SwitchMC				; Un appui sur l'annulation pour sortir sans sauver ?
		rjmp	ExitEESaveUserCancel				; Oui, alors on y va

		sbic	PinMenu,SwitchMenu					; Un appui sur Menu ?
		rjmp 	MenuWaitEESU1						; Non, on boucle

		ldi		Work,0x40							; On est VRAIMENT s�r de c'qu'on fait ?
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuEEPromSureSure*2)
		ldi		ZL,LOW(MenuEEPromSureSure*2)
		call	DisplayAfficheChaine

MenuWaitEESU2:
		call	Attendre
		sbis	PinMenu,SwitchMenu					; Avant de passer � la suite,
		rjmp	MenuWaitEESU2						; On attend le relachement du bouton de menu

MenuWaitEESU3:
		sbis	PinSwitchMC,SwitchMC				; Un appui sur l'annulation pour sortir sans sauver ?
		rjmp	ExitEESaveUserCancel				; Oui, alors on y va

		sbic	PinMenu,SwitchMenu					; Un appui sur Menu ?
		rjmp 	MenuWaitEESU3						; Non, on boucle

; Bon, ben c'est parti...
		ldi		Work,0x40							; On affiche le message de sauvegarde
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuEEPromSavingUser*2)
		ldi		ZL,LOW(MenuEEPromSavingUser*2)
		call	DisplayAfficheChaine

; D�but de la zone d'�criture (0x0200)
		clr		ZL									; 
		mov		Work,MenuReg2
		lsl		Work
		mov		ZH,Work
											; 
; D�but de la zone de lecture (0x0000)
		clr		YL									; Adresse basse de lecture
		clr		YH									; Adresse haute de lecture

; Lecture de l'EEPROM

LoopReadEEpromSU:
		sbic	EECR,EEWE							; Si EEWE n'est pas � 0
		rjmp	LoopReadEEpromSU					; on attend

		out     EEARL,YL	  	                    ; On charge "l'adresse" pour l'EEPROM
		out		EEARH,YH
		sbi		EECR,EERE							; Signale � l'EEPROM qu'on veut lire
													; (4 cycles d'horloge)
		in		Work,EEDR							; r�cup�re la donn�e

; Ecriture dans la zone haute de l'EEPROM

	    cli											; inhibe les interruptions
LoopWriteEEpromSU:
        sbic    EECR,EEWE                   	    ; On attend que l'EEprom soit pr�te pour l'�criture
        rjmp    LoopWriteEEpromSU
        
		out     EEARL,ZL		                    ; On charge "l'adresse" pour l'EEPROM
		out		EEARH,ZH
		out     EEDR,Work	                        ; ainsi que la donn�e
        
        sbi     EECR,EEMWE                         	; Master Write Enable
        sbi     EECR,EEWE                         	; On �crit dans l'EEPROM (arr�te le CPU pendant 2 cycles)
	    sei											; R�autorise les interruptions

		adiw	YL,0x01								; Incr�mente les adresses de lecture
		adiw	ZL,0x01								; et d'�criture

		cpi		YH,0x02								; Tant qu'on n'a pas atteint la fin de la zone de lecture
		brne	LoopReadEEpromSU					; On continue la boucle

		clr		Work								; R�tablit l'adresse haute de l'EEPROM
		out		EEARH,Work		

LoopReadEEpromSUExit:
		sbic	EECR,EEWE							; Si EEWE n'est pas � 0
		rjmp	LoopReadEEpromSUExit				; on attend

		ret

ExitEESaveUserCancel:
		sbis	PinSwitchMC,SwitchMC				; petit test habituel pour ne pas effectuer
		rjmp	ExitEESaveUserCancel				; des sorties de menu en cascade

		ret

; ======================================================================
; == Lecture les pr�f�rences utilisateur dans une zone de l'EEPROM    ==
; == Lecture de 0x0200-0x03FF et �criture en 0x0000-0x01FF            ==
; ======================================================================

MenuEELoadUserSettings:

		sbis	PinMenu,SwitchMenu					; Avant de passer � la suite,
		rjmp	MenuEELoadUserSettings				; On attend le relachement du bouton de menu

; Bouton rel�ch�, on continue

		ldi		Work,0								; Se place au d�but
		call	DisplayPlaceCurseur

		ldi		ZH,HIGH(MenuEEPromLoadUser*2)		; Message qui convient
		ldi		ZL,LOW(MenuEEPromLoadUser*2)
		call	DisplayAfficheChaine

		ldi		Work,6
		call	DisplayPlaceCurseur
		mov		Char,MenuReg2
		subi	Char,-48
		call	DisplayWriteChar

		ldi		Work,0x40							; On est s�r de c'qu'on fait ?
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuEEPromSure*2)
		ldi		ZL,LOW(MenuEEPromSure*2)
		call	DisplayAfficheChaine

MenuWaitEELU1:
		sbis	PinSwitchMC,SwitchMC				; Un appui sur l'annulation pour sortir sans sauver ?
		rjmp	ExitEELoadUserCancel				; Oui, alors on y va

		sbic	PinMenu,SwitchMenu					; Un appui sur Menu ?
		rjmp 	MenuWaitEELU1						; Non, on boucle

		ldi		Work,0x40							; On est VRAIMENT s�r de c'qu'on fait ?
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuEEPromSureSure*2)
		ldi		ZL,LOW(MenuEEPromSureSure*2)
		call	DisplayAfficheChaine

MenuWaitEELU2:
		call	Attendre
		sbis	PinMenu,SwitchMenu					; Avant de passer � la suite,
		rjmp	MenuWaitEELU2						; On attend le relachement du bouton de menu

MenuWaitEELU3:
		sbis	PinSwitchMC,SwitchMC				; Un appui sur l'annulation pour sortir sans sauver ?
		rjmp	ExitEELoadUserCancel				; Oui, alors on y va

		sbic	PinMenu,SwitchMenu					; Un appui sur Menu ?
		rjmp 	MenuWaitEELU3						; Non, on boucle

; Bon, ben c'est parti...
		ldi		Work,0x40							; On affiche le message de sauvegarde
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuEEPromLoadingUser*2)
		ldi		ZL,LOW(MenuEEPromLoadingUser*2)
		call	DisplayAfficheChaine

; D�but de la zone d'�criture (0x0000)
		clr		ZL									; 
		clr		ZH									; Adresse haute de lecture
; D�but de la zone de lecture (0x0200)
		clr		YL									; Adresse basse de lecture
		mov		Work,MenuReg2
		lsl		Work
		mov		YH,Work									; 


; Lecture de l'EEPROM

LoopReadEEpromLU:
		sbic	EECR,EEWE							; Si EEWE n'est pas � 0
		rjmp	LoopReadEEpromLU					; on attend

		out     EEARL,YL	  	                    ; On charge "l'adresse" pour l'EEPROM
		out		EEARH,YH
		sbi		EECR,EERE							; Signale � l'EEPROM qu'on veut lire
													; (4 cycles d'horloge)
		in		Work,EEDR							; r�cup�re la donn�e

; Ecriture dans la zone haute de l'EEPROM

	    cli											; inhibe les interruptions
LoopWriteEEpromLU:
        sbic    EECR,EEWE                   	    ; On attend que l'EEprom soit pr�te pour l'�criture
        rjmp    LoopWriteEEpromLU
        
		out     EEARL,ZL		                    ; On charge "l'adresse" pour l'EEPROM
		out		EEARH,ZH
		out     EEDR,Work	                        ; ainsi que la donn�e
        
        sbi     EECR,EEMWE                         	; Master Write Enable
        sbi     EECR,EEWE                         	; On �crit dans l'EEPROM (arr�te le CPU pendant 2 cycles)
	    sei											; R�autorise les interruptions

		adiw	YL,0x01								; Incr�mente les adresses de lecture
		adiw	ZL,0x01								; et d'�criture

		cpi		ZH,0x02								; Tant qu'on n'a pas atteint la fin de la zone de lecture
		brne	LoopReadEEpromLU					; On continue la boucle

		clr		Work								; R�tablit l'adresse haute de l'EEPROM
		out		EEARH,Work		

LoopReadEEpromLUExit:
		sbic	EECR,EEWE							; Si EEWE n'est pas � 0
		rjmp	LoopReadEEpromLUExit				; on attend

		ret

ExitEELoadUserCancel:
		sbis	PinSwitchMC,SwitchMC				; petit test habituel pour ne pas effectuer
		rjmp	ExitEELoadUserCancel				; des sorties de menu en cascade

		ret

; =============================================================================================
; == Routine de recopie en RAM les valeurs de config et les commandes RC5 qui sont en EEPROM ==
; =============================================================================================

EEPromToRam:

; On commence par la lecture de la table de d�codage de l'encodeur 

		ldi		ZH,RAM_Encodeur_H
		clr		ZL

		clr 	Work1								; D�but d'EEPROM en 0x0000
		out		EEARH,Work1

BoucleNibble:
		sbic	EECR,EEWE							; Si EEWE n'est pas � 0
		rjmp	BoucleNibble						; on attend

		out		EEARL,Work1							; Adresse � atteindre en EEPROM
	    sbi		EECR,EERE							; Pr�pare l'EEPROM � la lecture
		in		Work,EEDR							; lit la valeur en EEPROM et la met dans le registre Work

		st		Z+,Work								; et stocke la valeur en RAM, avec incr�mentation automatique de l'adresse

		inc		Work1								; incr�mente l'adresse en EEPROM
		cpi		Work1,EE_Start_Config				; teste si on a fini de lire les param�tres
		brne	BoucleNibble						; et boucle si on n'a pas tout lu

; -- Lecture des param�tres de config

		clr 	Work1
		out		EEARH,Work1

		ldi 	Work1,EE_Start_Config				; Adresse de d�but en EEPROM
		ldi		ZH,RAM_Start						; Octet de poids fort de l'adresse de d�but en RAM 
		clr		ZL									; Octet de poids faible de l'adresse de d�but en RAM (0 -> D�but de RAM)

BouclePaRam:
		sbic	EECR,EEWE							; Si EEWE n'est pas � 0
		rjmp	BouclePaRam							; on attend

		out		EEARL,Work1							; Adresse � atteindre en EEPROM
	    sbi		EECR,EERE							; Pr�pare l'EEPROM � la lecture
		in		Work,EEDR							; lit la valeur en EEPROM et la met dans le registre Work

		st		Z+,Work								; et stocke la valeur en RAM, avec incr�mentation automatique de l'adresse

		inc		Work1								; incr�mente l'adresse en EEPROM
		cpi		Work1,EE_Stop_Config				; teste si on a fini de lire les param�tres
		brne	BouclePaRam							; et boucle si on n'a pas tout lu

; --- M�me chose pour les commandes IR

		ldi 	Work1,EE_Start_IR					; Adresse de d�but en EEPROM

BoucleIRRam:
		sbic	EECR,EEWE							; Si EEWE n'est pas � 0
		rjmp	BoucleIRRam							; on attend

		out		EEARL,Work1							; Adresse � atteindre en EEPROM
	    sbi		EECR,EERE							; Pr�pare l'EEPROM � la lecture
		in		Work,EEDR							; lit la valeur en EEPROM et la met dans le registre Work

		st		Z+,Work								; et stocke la valeur en RAM, avec incr�mentation automatique de l'adresse

		inc		Work1								; incr�mente l'adresse en EEPROM
		cpi		Work1,EE_Stop_IR					; teste si on a fini de lire les param�tres
		brne	BoucleIRRam							; et boucle on n'a pas tout lu

; =================================================================
; == Recopie en RAM des intitul�s des entr�es qui sont en EEPROM ==
; =================================================================

		ldi		Work1,EE_Start_Label				; Adresse de d�but en EEPROM

		ldi		ZH,RAM_Start
		ldi		ZL,RAM_TitreIn1

BoucleTitreRAM:
		sbic	EECR,EEWE							; Si EEWE n'est pas � 0
		rjmp	BoucleTitreRAM						; on attend

		out		EEARL,Work1							; Adresse � atteindre en EEPROM
	    sbi		EECR,EERE							; Pr�pare l'EEPROM � la lecture
		in		Work,EEDR							; lit la valeur en EEPROM et la met dans le registre Work

		st		Z+,Work								; et stocke la valeur en RAM, avec incr�mentation automatique de l'adresse

		inc		Work1								; incr�mente l'adresse en EEPROM
		cpi		Work1,EE_Stop_Label					; teste si on a fini de lire les param�tres
		brne	BoucleTitreRAM						; et boucle si on n'a pas tout lu

; ==========================================================
; == Recopie en RAM les messages (Bienvenue, Fin et Mute) ==
; ==========================================================

; -----------------------
; -- Message de bienvenue
; -----------------------

		ldi		ZH,RAM_Start						; Adresse en RAM
		ldi		ZL,RAM_Welcome_M					; Du message de bienvenue

		ldi		Work,EE_Welcome_Hi					; Adresse en EEPROM
		out		EEARH,Work					
		ldi		Work,EE_Welcome_Lo					; du m�me message...
		out		EEARL,Work

		ldi		Count1,0							; 40 caract�res � lire

BoucleWelcomeRAM:
		sbic	EECR,EEWE							; Si EEWE n'est pas � 0
		rjmp	BoucleWelcomeRAM					; on attend

		out		EEARL,Work							; Adresse � atteindre en EEPROM
	    sbi		EECR,EERE							; Pr�pare l'EEPROM � la lecture
		in		Char,EEDR							; lit la valeur en EEPROM et la met dans le registre Work

		st		Z+,Char								; et stocke la valeur en RAM, avec incr�mentation automatique de l'adresse

		inc		Work								; Incr�mente l'adresse en EEPROM
		inc		Count1								; Incr�mente le compteur de caract�res
		cpi		Count1,(2*DisplaySize)+2			; C'est le dernier caract�re des 2 lignes ?
		brne	BoucleWelcomeRAM					; nan, alors on boucle

; -----------------
; -- Message de fin
; -----------------

		ldi		ZH,RAM_Start						; Adresse en RAM
		ldi		ZL,RAM_Bye_M						; Du message de fin

		ldi		Work,EE_Bye_Hi						; Adresse en EEPROM
		out		EEARH,Work					
		ldi		Work,EE_Bye_Lo						; du m�me message...
		out		EEARL,Work

		ldi		Count1,0							; 40 caract�res � lire

BoucleByeRAM:
		sbic	EECR,EEWE							; Si EEWE n'est pas � 0
		rjmp	BoucleByeRAM						; on attend

		out		EEARL,Work							; Adresse � atteindre en EEPROM
	    sbi		EECR,EERE							; Pr�pare l'EEPROM � la lecture
		in		Char,EEDR							; lit la valeur en EEPROM et la met dans le registre Work

		st		Z+,Char								; et stocke la valeur en RAM, avec incr�mentation automatique de l'adresse

		inc		Work								; Incr�mente l'adresse en EEPROM
		inc		Count1								; Incr�mente le compteur de caract�res
		cpi		Count1,(2*DisplaySize)+2			; C'est le dernier caract�re des 2 lignes  (2 fois la taille de l'afficheur plus 1 octet de terminaison de cha�ne ) ?
		brne	BoucleByeRAM						; nan, alors on boucle

; ------------------
; -- Message de Mute
; ------------------

		ldi		ZH,RAM_Start						; Adresse en RAM
		ldi		ZL,RAM_Mute_M						; Du message de mute

		ldi		Work,EE_Mute_Hi						; Adresse en EEPROM
		out		EEARH,Work					
		ldi		Work,EE_Mute_Lo						; du m�me message...
		out		EEARL,Work

		ldi		Count1,0							; 42 caract�res � lire

BoucleMuteRAM:
		sbic	EECR,EEWE							; Si EEWE n'est pas � 0
		rjmp	BoucleMuteRAM						; on attend

		out		EEARL,Work							; Adresse � atteindre en EEPROM
	    sbi		EECR,EERE							; Pr�pare l'EEPROM � la lecture
		in		Char,EEDR							; lit la valeur en EEPROM et la met dans le registre Work

		st		Z+,Char								; et stocke la valeur en RAM, avec incr�mentation automatique de l'adresse

		inc		Work								; Incr�mente l'adresse en EEPROM
		inc		Count1								; Incr�mente le compteur de caract�res
		cpi		Count1,(2*DisplaySize)+2			; C'est le dernier caract�re des 2 lignes ?
		brne	BoucleMuteRAM						; nan, alors on boucle

		clr 	Work								; On remet l'adresse haute de l'EEPROM
		out		EEARH,Work							; � sa valeur initiale

		ldi		ZH,RAM_Start
		ret											; et voilou
