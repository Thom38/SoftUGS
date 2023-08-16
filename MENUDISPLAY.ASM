; ============================================================
; == Routines pour la gestion des paramètres de l'afficheur ==
; ==                                                        ==
; ==   - Encodeur -> Navigation dans les options            ==
; ==   - Menu     -> Entrer dans une option                 ==
; ==   - StandBy  -> Remonter au menu précédent sans sauver ==
; ==                                                        ==
; ============================================================

MenuDisplay:

WaitMenuDisplay:
		sbis	PinMenu,SwitchMenu					; Avant de passer à la suite,
		rjmp	WaitMenuDisplay						; On attend le relachement du bouton de menu

; OK, on a lâché le bouton

		ldi		Work,0								; Début de première ligne
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuDisplayTopMessage*2)
		ldi		ZL,LOW(MenuDisplayTopMessage*2)
		call	DisplayAfficheChaine

		ldi		Work,0x40							; on se place
		call	DisplayPlaceCurseur					; sur la seconde ligne de l'afficheur
		ldi		ZH,HIGH(MenuDisplayBrightMessage*2)
		ldi		ZL,LOW(MenuDisplayBrightMessage*2)
		call	DisplayAfficheChaine				; affiche le "message" de l'encodeur 
		call	DisplayArrow						; et les flèches de l'encodeur

		clr		MenuReg1

LoopLevelD0:

		call 	LectureEncodeur						; Lecture de l'encodeur
		sbrs	StatReg1,FlagIncremente				; doit-on incrémenter
		sbrc	StatReg1,FlagDecremente				; ou décrémenter ?
		rjmp	ChangeDisplayMenu					; l'un des deux...

		sbis	PinSwitchMC,SwitchMC				; Un appui sur l'annulation pour sortir ?
		rjmp	ExitDisplayMenu						; Oui, alors on y va

		sbic	PinMenu,SwitchMenu					; Un appui sur Menu ?
		rjmp 	LoopLevelD0							; Non, on boucle

		call	Attendre							; On attend un peu...
		sbic	PinMenu,SwitchMenu					; Menu  toujours appuyé ?
		rjmp 	LoopLevelD0							; Non, on boucle

		rjmp	WhatDisplayMenuToEnter				; sinon on entre dans le menu de config qu'il faut
			
ChangeDisplayMenu:

		sbrc	StatReg1,FlagIncremente				; regarde dans quel sens allait l'encodeur
		rjmp	IncDispMenuReg1						; Vers le haut ?
		sbrc	StatReg1,FlagDecremente				; 
		rjmp	DecDispMenuReg1						; vers le bas ?
		rjmp	LoopLevelD0							; Aucun des deux, alors cassos

IncDispMenuReg1:									; Incrémentation du numéro de menu
		mov		Work,MenuReg1						; transfert dans un registre immédiat
		cpi		Work,4								; c'est le dernier menu ?
		brne	DoIncDispMR1						; non, alors on peut incrémenter sans pb

		clr		MenuReg1							; sinon, on le repasse à 0		
		rjmp	AfficheMenuDisp0					; et on va afficher la chaine qu'il faut
DoIncDispMR1:
		inc		MenuReg1							; On incrémente le registre
#if defined(VFD)
		ldi		Work,1								; Vérifie dans le cas du VFD que l'on ne vas pas toucher au contraste 
		cp		Work,MenuReg1
		brne	AfficheMenuDisp0
		inc 	MenuReg1
#endif
		rjmp	AfficheMenuDisp0					; et on va afficher la chaine qu'il faut

DecDispMenuReg1:									; Décrémentation du numéro de menu
		mov		Work,MenuReg1						; transfert dans un registre immédiat
		cpi		Work,0								; c'est le dernier menu ?
		brne	DoDecDispMR1						; non, alors on peut décrémenter sans pb

		ldi		Work,4
		mov		MenuReg1,Work						; sinon, on le repasse à 4		
		rjmp	AfficheMenuDisp0					; et on va afficher la chaine qu'il faut
DoDecDispMR1:
		dec		MenuReg1							; On décrémente le registre
#if defined(VFD)
		ldi		Work,1								; Vérifie dans le cas du VFD que l'on ne vas pas toucher au contraste 
		cp		Work,MenuReg1
		brne	AfficheMenuDisp0
		dec 	MenuReg1
#endif

AfficheMenuDisp0:									; affiche le menu correspondant au contenu de MenuReg1 (entre 0 et 4)

		cbr		StatReg1,EXP2(FlagIncremente)		; On commence par remettre à 0 les flags de l'encodeur
		cbr		StatReg1,EXP2(FlagDecremente)

		ldi		Work,0x40							; On se place en début de seconde ligne
		call	DisplayPlaceCurseur

		mov		Work,MenuReg1						; On met le registre dans un registre immédiat

TestMenuDispBright:

		cpi		Work,0								; C'est 0 ?
		brne	TestMenuDispContrast				; Nan...

		ldi		ZH,HIGH(MenuDisplayBrightMessage*2)	; Oui, c'est 0
		ldi		ZL,LOW(MenuDisplayBrightMessage*2)
		call	DisplayAfficheChaine				; Affiche la première chaine de setup
		call	DisplayArrow						; et les flèches de l'encodeur
		rjmp	LoopLevelD0							; et on continue la boucle

TestMenuDispContrast:

		cpi		Work,1								; C'est 1 ?
		brne	TestMenuIdleBright					; Nan...

		ldi		ZH,HIGH(MenuDisplayContrastMessage*2); Oui, c'est 1
		ldi		ZL,LOW(MenuDisplayContrastMessage*2)
		call	DisplayAfficheChaine				; Affiche la première chaine de setup
		call	DisplayArrow						; et les flèches de l'encodeur
		rjmp	LoopLevelD0							; et on continue la boucle

TestMenuIdleBright:

		cpi		Work,2								; C'est 2 ?
		brne	TestMenuIdleTimeOut					; Nan...

		ldi		ZH,HIGH(MenuDisplayIdleBrightMessage*2); Oui
		ldi		ZL,LOW(MenuDisplayIdleBrightMessage*2)
		call	DisplayAfficheChaine				; Affiche la première chaine de setup
		call	DisplayArrow						; et les flèches de l'encodeur
		rjmp	LoopLevelD0							; et on continue la boucle

TestMenuIdleTimeOut:

		cpi		Work,3								; C'est 3 ?
		brne	TestMenuIdleLed						; Nan...

		ldi		ZH,HIGH(MenuDisplayIdleTimeOutMessage*2); Yes
		ldi		ZL,LOW(MenuDisplayIdleTimeOutMessage*2)
		call	DisplayAfficheChaine				; Affiche la première chaine de setup
		call	DisplayArrow						; et les flèches de l'encodeur
		rjmp	LoopLevelD0							; et on continue la boucle

TestMenuIdleLed:

		ldi		ZH,HIGH(MenuDisplayIdleLedMessage*2); Yes
		ldi		ZL,LOW(MenuDisplayIdleLedMessage*2)
		call	DisplayAfficheChaine				; Affiche la première chaine de setup
		call	DisplayArrow						; et les flèches de l'encodeur
		rjmp	LoopLevelD0							; et on continue la boucle

WhatDisplayMenuToEnter:

		mov		Work,MenuReg1						; Transfert en immédiat
		cpi		Work,0								; si c'est 0
		breq	EnterMenuDisplayBrightness			; on va triturer le menu de la luminosité
		cpi		Work,1								; si c'est 1
		breq	EnterMenuDisplayContrast			; on va triturer le menu du contraste
		cpi		Work,2								; si c'est 2
		breq	EnterMenuDisplayIdleBright			; on va triturer le menu de la luminosité d'Idle
		cpi		Work,3								; si c'est 3
		breq	EnterMenuDisplayIdleTimeOut			; on va triturer le menu de la durée du Timeout
		rjmp	EnterMenuDisplayIdleLed				; Sinon, c'est 4 et on va triturer le menu de l'extinction de la led


EnterMenuDisplayBrightness:							; on va triturer le menu de la luminosité

		call 	Attendre							; On attend un peu
		sbic	PinMenu,SwitchMenu					; Un vrai appui sur le bouton de menu ?
		rjmp	TestMenuDispBright					; Sinon,on revient au bon endroit

		ldi		Work,0								; Valeur à 0 -> Luminosité
		mov		MenuReg2,Work
		rcall	MenuAjusteDisplayB					; On y va

		ldi		Work,0								; Pour le retour -> Début de première ligne
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuDisplayTopMessage*2)
		ldi		ZL,LOW(MenuDisplayTopMessage*2)
		call	DisplayAfficheChaine

		ldi		Work,0x40							; on se place
		call	DisplayPlaceCurseur					; sur la seconde ligne de l'afficheur

		clr		Work
		mov		MenuReg1,Work						; On remet la bonne valeur dans MenuReg1
		rjmp	TestMenuDispBright					; et on revient au bon endroit

EnterMenuDisplayContrast:							; on va triturer le menu du contraste

		call 	Attendre							; On attend un peu
		sbic	PinMenu,SwitchMenu					; Un vrai appui sur le bouton de menu ?
		rjmp	TestMenuDispContrast				; Sinon,on revient au bon endroit

		ldi		Work,1								; Valeur à 1 -> Contraste
		mov		MenuReg2,Work
		rcall	MenuAjusteDisplayC					; On y va

		ldi		Work,0								; Pour le retour -> Début de première ligne
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuDisplayTopMessage*2)
		ldi		ZL,LOW(MenuDisplayTopMessage*2)
		call	DisplayAfficheChaine

		ldi		Work,0x40							; on se place
		call	DisplayPlaceCurseur					; sur la seconde ligne de l'afficheur

		ldi		Work,1
		mov		MenuReg1,Work						; On remet la bonne valeur dans MenuReg1
		rjmp	TestMenuDispContrast				; et on revient au bon endroit

EnterMenuDisplayIdleBright:							; on va triturer le menu de la luminosité d'Idle

		call 	Attendre							; On attend un peu
		sbic	PinMenu,SwitchMenu					; Un vrai appui sur le bouton de menu ?
		rjmp	TestMenuIdleBright					; Sinon,on revient au bon endroit

		ldi		Work,2								; Valeur à 2 -> Luminosité Idle
		mov		MenuReg2,Work
		rcall	MenuAjusteDisplayI					; On y va

		ldi		Work,0								; Pour le retour -> Début de première ligne
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuDisplayTopMessage*2)
		ldi		ZL,LOW(MenuDisplayTopMessage*2)
		call	DisplayAfficheChaine

		ldi		Work,0x40							; on se place
		call	DisplayPlaceCurseur					; sur la seconde ligne de l'afficheur

		ldi		Work,2
		mov		MenuReg1,Work						; On remet la bonne valeur dans MenuReg1
		rjmp	TestMenuIdleBright					; et on revient au bon endroit

EnterMenuDisplayIdleTimeOut:						; on va triturer le menu de la durée avant passage en mode Idle

		call 	Attendre							; On attend un peu
		sbic	PinMenu,SwitchMenu					; Un vrai appui sur le bouton de menu ?
		rjmp	TestMenuIdleBright					; Sinon,on revient au bon endroit

		ldi		Work,3								; Valeur à 3 -> Durée avant Idle
		mov		MenuReg2,Work
		rcall	MenuAjusteDisplayT					; On y va

		ldi		Work,0								; Pour le retour -> Début de première ligne
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuDisplayTopMessage*2)
		ldi		ZL,LOW(MenuDisplayTopMessage*2)
		call	DisplayAfficheChaine

		ldi		Work,0x40							; on se place
		call	DisplayPlaceCurseur					; sur la seconde ligne de l'afficheur

		ldi		Work,3
		mov		MenuReg1,Work						; On remet la bonne valeur dans MenuReg1
		rjmp	TestMenuIdleTimeOut					; et on revient au bon endroit

EnterMenuDisplayIdleLed:							; on va triturer le menu de la Led en Idle

		call 	Attendre							; On attend un peu
		sbic	PinMenu,SwitchMenu					; Un vrai appui sur le bouton de menu ?
		rjmp	TestMenuIdleBright					; Sinon,on revient au bon endroit

		ldi		Work,4								; Valeur à 4 -> Luminosité Led
		mov		MenuReg2,Work
		rcall	MenuAjusteDisplayL					; On y va

		ldi		Work,0								; Pour le retour -> Début de première ligne
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuDisplayTopMessage*2)
		ldi		ZL,LOW(MenuDisplayTopMessage*2)
		call	DisplayAfficheChaine

		ldi		Work,0x40							; on se place
		call	DisplayPlaceCurseur					; sur la seconde ligne de l'afficheur

		ldi		Work,4
		mov		MenuReg1,Work						; On remet la bonne valeur dans MenuReg1
		rjmp	TestMenuIdleBright					; et on revient au bon endroit

ExitDisplayMenu:
		call 	Attendre							; On attend pour le débounce
		sbic	PinSwitchMC,SwitchMC				; C'est un vrai appui sur l'annulation pour sortir ?
		rjmp	LoopLevelD0							; Non, fausse arlette et on replonge dans la boucle

WaitBeforeExitDisplayMenu:
		sbis	PinSwitchMC,SwitchMC				; petit test habituel pour ne pas effectuer
		rjmp	WaitBeforeExitDisplayMenu			; des sorties de menu en cascade

		ret											; on se casse de ce menu

; ============================================================
; == Réglage de la luminosité de l'afficheur                ==
; ==                                                        ==
; ==   - Encodeur -> Changer la valeur                      ==
; ==   - Menu     -> Valider la nouvelle valeur             ==
; ==   - StandBy  -> Remonter au menu précédent sans sauver ==
; ============================================================

MenuAjusteDisplayB:

WaitMenuAjusteDisplayB:
		sbis	PinMenu,SwitchMenu					; Avant de passer à la suite,
		rjmp	WaitMenuAjusteDisplayB				; On attend le relachement du bouton de menu

; Bouton relâché, on continue

		ldi		Work,0								; Se place au début
		call	DisplayPlaceCurseur

		ldi		ZH,HIGH(MenuDisplayBrightTopMessage*2)
		ldi		ZL,LOW(MenuDisplayBrightTopMessage*2)
		call	DisplayAfficheChaine

; On récupère la valeur de la luminosité en RAM

		ldi		ZH,RAM_Start						; Octet de poids fort de l'adresse de début en RAM 
		ldi		ZL,RAM_StartBrightness				; L'adresse de ce paramètre en RAM

		ld		MenuReg1,Z							; Récupère la valeur stockée en RAM dans MenuReg1

		rcall	AfficheBrightnessOrContrast			; En seconde ligne

LoopLevelDispAdj0B:

		call 	LectureEncodeur						; Lecture de l'encodeur
		sbrs	StatReg1,FlagIncremente				; doit-on incrémenter
		sbrc	StatReg1,FlagDecremente				; ou décrémenter ?
		rjmp	MenuChangeB							; l'un des deux...

		sbis	PinSwitchMC,SwitchMC				; Un appui sur l'annulation pour sortir sans sauver ?
		rjmp	ExitAjusteDisplayBMenuNoSave		; Oui, alors on y va

		sbic	PinMenu,SwitchMenu					; Un appui sur Menu ?
		rjmp 	LoopLevelDispAdj0B					; Non, on boucle

		rjmp	ExitAjusteDisplayBMenu				; sinon on se sauve en sauvant

MenuChangeB:

		sbrc	StatReg1,FlagIncremente				; regarde dans quel sens allait l'encodeur
		rjmp	IncBMenuReg1						; Vers le haut ?
		sbrc	StatReg1,FlagDecremente				; 
		rjmp	DecBMenuReg1						; vers le bas ?
		rjmp	LoopLevelDispAdj0B					; Aucun des deux, alors cassos

IncBMenuReg1:										; Incrémentation du paramètre
		mov		Work,MenuReg1
		cpi		Work,BrightnessMax					; c'est le max ?
		brne	DoIncBMR1							; non, alors on peut incrémenter sans pb

		rjmp	LoopLevelDispAdj0B					; Sinon, on ne fait rien

DoIncBMR1:
		inc		MenuReg1							; On incrémente le registre
		rjmp	MenuActualiseB						; et on modifie la luminosité

DecBMenuReg1:										; Décrémentation de la luminosité
		mov		Work,MenuReg1						; transfert dans un registre immédiat
		cpi		Work,0								; c'est le min ?
		brne	DoDecBMR1							; non, alors on peut décrémenter sans pb

		rjmp	LoopLevelDispAdj0B					; Sinon, on ne fait rien

DoDecBMR1:
		dec		MenuReg1							; On décrémente le registre
		rjmp	MenuActualiseB						; et on modifier la luminosité

MenuActualiseB:										; On modifie vraiment la luminosité

		lds		Work,TCCR3B							; si le timer 3 ne tourne pas
		andi	Work,0b00000111						; on lance le clignotement de la LED On
		cpi		Work,0								; car on a modifié la valeur qui était stockée
		brne	DoMenuActualiseB						
		call	LanceClignotementLED

DoMenuActualiseB:
		cbr		StatReg1,EXP2(FlagIncremente)		; On commence par remettre à 0 les flags de l'encodeur
		cbr		StatReg1,EXP2(FlagDecremente)

		mov		Work,MenuReg1						; On transfère le paramètre dans le bon regsitre

		call	SetBrightness						;
		rcall	AfficheBrightnessOrContrast			; et affiche la valeur
		rjmp	LoopLevelDispAdj0B					; Boucle Again

ExitAjusteDisplayBMenuNoSave:						; On se sauve sans sauver...

		sbis	PinSwitchMC,SwitchMC				; petit test habituel pour ne pas effectuer
		rjmp	ExitAjusteDisplayBMenuNoSave		; des sorties de menu en cascade

		call	ArreteClignotementLED				; Au cazoù, on rallume la LED de On/StandBy

		ldi		ZH,RAM_Start						; Octet de poids fort de l'adresse de début en RAM 
		ldi		ZL,RAM_StartBrightness				; L'adresse de ce paramètre en RAM
		ld		Work,Z							 	; Récupère la valeur stockée en RAM
		call	SetBrightness
		ret

ExitAjusteDisplayBMenu:
		sbis	PinMenu,SwitchMenu					; petit test habituel pour ne pas effectuer
		rjmp	ExitAjusteDisplayBMenu				; des sorties de menu en cascade

		call	ArreteClignotementLED				; Au cazoù, on rallume la LED de On/StandBy

		ldi		Work,SaveLong						; Fixe le temps d'affichage du prochain message
		call	AfficheSaving						; Affiche le message de sauvegarde

		ldi		ZH,RAM_Start						; Octet de poids fort de l'adresse de début en RAM 
		ldi		ZL,RAM_StartBrightness				; L'adresse de ce paramètre en RAM
		st		Z,MenuReg1							; et enregistre la valeur en RAM

		mov		Work2,MenuReg1						; La donnée à enregistrer en EEPROM
		ldi		Work,EE_StartBrightness				; et son adresse					
		call	WriteEEprom							; on enregistre

		ret											; et cassos


; ============================================================
; == Réglage du contraste de l'afficheur                    ==
; ==                                                        ==
; ==   - Encodeur -> Changer la valeur                      ==
; ==   - Menu     -> Valider la nouvelle valeur             ==
; ==   - StandBy  -> Remonter au menu précédent sans sauver ==
; ============================================================

MenuAjusteDisplayC:

#if defined(LCD)

WaitMenuAjusteDisplayC:
		sbis	PinMenu,SwitchMenu					; Avant de passer à la suite,
		rjmp	WaitMenuAjusteDisplayC				; On attend le relachement du bouton de menu

; Bouton relâché, on continue

		ldi		Work,0								; Se place au début
		call	DisplayPlaceCurseur

		ldi		ZH,HIGH(MenuDisplayContrastTopMessage*2)
		ldi		ZL,LOW(MenuDisplayContrastTopMessage*2)
		call	DisplayAfficheChaine

; On récupère la valeur du contraste en RAM

		ldi		ZH,RAM_Start						; Octet de poids fort de l'adresse de début en RAM 
		ldi		ZL,RAM_StartContrast				; L'adresse de ce paramètre en RAM

		ld		MenuReg1,Z							; Récupère la valeur stockée en RAM dans MenuReg1

		rcall	AfficheBrightnessOrContrast			; En seconde ligne

LoopLevelDispAdj0C:

		call 	LectureEncodeur						; Lecture de l'encodeur
		sbrs	StatReg1,FlagIncremente				; doit-on incrémenter
		sbrc	StatReg1,FlagDecremente				; ou décrémenter ?
		rjmp	MenuChangeC							; l'un des deux...

		sbis	PinSwitchMC,SwitchMC				; Un appui sur le bouton d'annulation pour sortir sans sauver ?
		rjmp	ExitAjusteDisplayCMenuNoSave		; Oui, alors on y va

		sbic	PinMenu,SwitchMenu					; Un appui sur Menu ?
		rjmp 	LoopLevelDispAdj0C					; Non, on boucle

;		call	Attendre							; On attend un peu...
;		sbic	PinMenu,SwitchMenu					; Menu  toujours appuyé ?
;		rjmp 	LoopLevelDispAdj0C					; Non, on boucle

		rjmp	ExitAjusteDisplayCMenu				; sinon on se sauve en sauvant


MenuChangeC:

		sbrc	StatReg1,FlagIncremente				; regarde dans quel sens allait l'encodeur
		rjmp	IncCMenuReg1						; Vers le haut ?
		sbrc	StatReg1,FlagDecremente				; 
		rjmp	DecCMenuReg1						; vers le bas ?
		rjmp	LoopLevelDispAdj0C					; Aucun des deux, alors cassos

IncCMenuReg1:										; Incrémentation du paramètre
		mov		Work,MenuReg1
		cpi		Work,ContrasteMaxi					; c'est le max ?
		brne	DoIncCMR1							; non, alors on peut incrémenter sans pb

		rjmp	LoopLevelDispAdj0C					; Sinon, on ne fait rien

DoIncCMR1:
		inc		MenuReg1							; On incrémente le registre
		rjmp	MenuActualiseC						; et on modifie le contraste

DecCMenuReg1:										; Décrémentation ddu contraste
		mov		Work,MenuReg1						; transfert dans un registre immédiat
		cpi		Work,0								; c'est le min ?
		brne	DoDecCMR1							; non, alors on peut décrémenter sans pb

		rjmp	LoopLevelDispAdj0C					; Sinon, on ne fait rien

DoDecCMR1:
		dec		MenuReg1							; On décrémente le registre
		rjmp	MenuActualiseC						; et on modifier la luminosité

MenuActualiseC:										; On modifie vraiment la luminosité

		lds		Work,TCCR3B							; si le timer 3 ne tourne pas
		andi	Work,0b00000111						; on lance le clignotement de la LED On
		cpi		Work,0								; car on a modifié la valeur qui était stockée
		brne	DoMenuActualiseC						
		call	LanceClignotementLED

DoMenuActualiseC:
		cbr		StatReg1,EXP2(FlagIncremente)		; On commence par remettre à 0 les flags de l'encodeur
		cbr		StatReg1,EXP2(FlagDecremente)

		mov		Work,MenuReg1						; On transfère le paramètre dans le bon regsitre

		call	SetContrast							;	- Oui
		rcall	AfficheBrightnessOrContrast			; et affiche la valeur
		rjmp	LoopLevelDispAdj0C					; Boucle Again

ExitAjusteDisplayCMenuNoSave:						; On se sauve sans sauver...

		sbis	PinSwitchMC,SwitchMC				; petit test habituel pour ne pas effectuer
		rjmp	ExitAjusteDisplayCMenuNoSave		; des sorties de menu en cascade

		call	ArreteClignotementLED				; Au cazoù, on rallume la LED de On/StandBy

		ldi		ZH,RAM_Start						; Octet de poids fort de l'adresse de début en RAM 
		ldi		ZL,RAM_StartContrast				; L'adresse de ce paramètre en RAM
		ld		Work,Z							 	; Récupère la valeur stockée en RAM
		call	SetContrast
		ret

ExitAjusteDisplayCMenu:
		sbis	PinMenu,SwitchMenu					; petit test habituel pour ne pas effectuer
		rjmp	ExitAjusteDisplayCMenu				; des sorties de menu en cascade

		call	ArreteClignotementLED				; Au cazoù, on rallume la LED de On/StandBy

		ldi		Work,SaveLong						; Fixe le temps d'affichage du prochain message
		call	AfficheSaving						; Affiche le message de sauvegarde

		ldi		ZH,RAM_Start						; Octet de poids fort de l'adresse de début en RAM 
		ldi		ZL,RAM_StartContrast				; L'adresse de ce paramètre en RAM
		st		Z,MenuReg1							; et enregistre la valeur en RAM

		mov		Work2,MenuReg1						; La donnée à enregistrer en EEPROM
		ldi		Work,EE_StartContrast				; et son adresse					
		call	WriteEEprom							; on enregistre
#endif
		ret											; et cassos


; ============================================================
; == Réglage de la luminosité Idle de l'afficheur           ==
; ==                                                        ==
; ==   - Encodeur -> Changer la valeur                      ==
; ==   - Menu     -> Valider la nouvelle valeur             ==
; ==   - StandBy  -> Remonter au menu précédent sans sauver ==
; ============================================================

MenuAjusteDisplayI:

WaitMenuAjusteDisplayI:
		sbis	PinMenu,SwitchMenu					; Avant de passer à la suite,
		rjmp	WaitMenuAjusteDisplayI				; On attend le relachement du bouton de menu

; Bouton relâché, on continue

		ldi		Work,0								; Se place au début
		call	DisplayPlaceCurseur

		ldi		ZH,HIGH(MenuDisplayIdleTopMessage*2)
		ldi		ZL,LOW(MenuDisplayIdleTopMessage*2)
		call	DisplayAfficheChaine

; On récupère la valeur de la luminosité en RAM

		ldi		ZH,RAM_Start						; Octet de poids fort de l'adresse de début en RAM 
		ldi		ZL,RAM_IdleBrightness				; L'adresse de ce paramètre en RAM

		ld		MenuReg1,Z							; Récupère la valeur stockée en RAM dans MenuReg1

		mov		Work,MenuReg1						; On va fixer la luminosité à cette valeur
		call	SetBrightness

		rcall	AfficheBrightnessOrContrast			; On affiche la valeur en seconde ligne

LoopLevelDispAdj0I:

		call 	LectureEncodeur						; Lecture de l'encodeur
		sbrs	StatReg1,FlagIncremente				; doit-on incrémenter
		sbrc	StatReg1,FlagDecremente				; ou décrémenter ?
		rjmp	MenuChangeI							; l'un des deux...

		sbis	PinSwitchMC,SwitchMC				; Un appui sur le bouton d'annulation pour sortir sans sauver ?
		rjmp	ExitAjusteDisplayIMenuNoSave		; Oui, alors on y va

		sbic	PinMenu,SwitchMenu					; Un appui sur Menu ?
		rjmp 	LoopLevelDispAdj0I					; Non, on boucle

		rjmp	ExitAjusteDisplayIMenu				; sinon on se sauve en sauvant


MenuChangeI:

		sbrc	StatReg1,FlagIncremente				; regarde dans quel sens allait l'encodeur
		rjmp	IncIMenuReg1						; Vers le haut ?
		sbrc	StatReg1,FlagDecremente				; 
		rjmp	DecIMenuReg1						; vers le bas ?
		rjmp	LoopLevelDispAdj0I					; Aucun des deux, alors cassos

IncIMenuReg1:										; Incrémentation du paramètre
		mov		Work,MenuReg1
		cpi		Work,BrightnessMax					; c'est le max ?
		brne	DoIncIMR1							; non, alors on peut incrémenter sans pb

		rjmp	LoopLevelDispAdj0I					; Sinon, on ne fait rien

DoIncIMR1:
		inc		MenuReg1							; On incrémente le registre
		rjmp	MenuActualiseI						; et on modifie la luminosité

DecIMenuReg1:										; Décrémentation de la luminosité
		mov		Work,MenuReg1						; transfert dans un registre immédiat
		cpi		Work,0								; c'est le min ?
		brne	DoDecIMR1							; non, alors on peut décrémenter sans pb

		rjmp	LoopLevelDispAdj0I					; Sinon, on ne fait rien

DoDecIMR1:
		dec		MenuReg1							; On décrémente le registre
		rjmp	MenuActualiseI						; et on modifie la luminosité

MenuActualiseI:										; On modifie vraiment la luminosité

		lds		Work,TCCR3B							; si le timer 3 ne tourne pas
		andi	Work,0b00000111						; on lance le clignotement de la LED On
		cpi		Work,0								; car on a modifié la valeur qui était stockée
		brne	DoMenuActualiseI						
		call	LanceClignotementLED

DoMenuActualiseI:
		cbr		StatReg1,EXP2(FlagIncremente)		; On commence par remettre à 0 les flags de l'encodeur
		cbr		StatReg1,EXP2(FlagDecremente)

		mov		Work,MenuReg1						; On transfère le paramètre dans le bon regsitre

		call	SetBrightness						; On règle la loupiote
		rcall	AfficheBrightnessOrContrast			; et affiche la valeur
		rjmp	LoopLevelDispAdj0I

ExitAjusteDisplayIMenuNoSave:						; On se sauve sans sauver...

		sbis	PinSwitchMC,SwitchMC				; petit test habituel pour ne pas effectuer
		rjmp	ExitAjusteDisplayIMenuNoSave		; des sorties de menu en cascade

		call	ArreteClignotementLED				; Au cazoù, on rallume la LED de On/StandBy

		ldi		ZH,RAM_Start						; Octet de poids fort de l'adresse de début en RAM 
		ldi		ZL,RAM_StartBrightness				; L'adresse de ce paramètre en RAM
		ld		Work,Z							 	; Récupère la valeur stockée en RAM
		call	SetBrightness

		ret

ExitAjusteDisplayIMenu:
		sbis	PinMenu,SwitchMenu					; petit test habituel pour ne pas effectuer
		rjmp	ExitAjusteDisplayIMenu				; des sorties de menu en cascade

		call	ArreteClignotementLED				; Au cazoù, on rallume la LED de On/StandBy

		ldi		Work,SaveLong						; Fixe le temps d'affichage du prochain message
		call	AfficheSaving						; Affiche le message de sauvegarde

		ldi		ZH,RAM_Start						; Octet de poids fort de l'adresse de début en RAM 
		ldi		ZL,RAM_IdleBrightness				; L'adresse de ce paramètre en RAM
		st		Z,MenuReg1							; et enregistre la valeur en RAM

		mov		Work2,MenuReg1						; La donnée à enregistrer en EEPROM
		ldi		Work,EE_IdleBrightness				; et son adresse					
		call	WriteEEprom							; on enregistre

; -- On n'oublie pas de restaurer la luminosité de départ
		ldi		ZH,RAM_Start						; Octet de poids fort de l'adresse de début en RAM 
		ldi		ZL,RAM_StartBrightness				; L'adresse de ce paramètre en RAM
		ld		Work,Z
		call	SetBrightness						; et c'est fini

		ret

; ============================================================
; == Réglage de durée avant passage en mode Idle            ==
; ==                                                        ==
; ==   - Encodeur -> Changer la valeur                      ==
; ==   - Menu     -> Valider la nouvelle valeur             ==
; ==   - StandBy  -> Remonter au menu précédent sans sauver ==
; ============================================================

MenuAjusteDisplayT:

WaitMenuAjusteDisplayT:
		sbis	PinMenu,SwitchMenu					; Avant de passer à la suite,
		rjmp	WaitMenuAjusteDisplayT				; On attend le relachement du bouton de menu

; Bouton relâché, on continue

		ldi		Work,0								; Se place au début
		call	DisplayPlaceCurseur

		ldi		ZH,HIGH(MenuDisplayIdleTimeOutTopMessage*2)
		ldi		ZL,LOW(MenuDisplayIdleTimeOutTopMessage*2)
		call	DisplayAfficheChaine

; On récupère la valeur de la durée en RAM

		ldi		ZH,RAM_Start						; Octet de poids fort de l'adresse de début en RAM 
		ldi		ZL,RAM_IdleTimeOut					; L'adresse de ce paramètre en RAM

		ld		MenuReg1,Z							; Récupère la valeur stockée en RAM dans MenuReg1

		rcall	AfficheIdleTimeOut					; En seconde ligne

LoopLevelDispAdj0T:

		call 	LectureEncodeur						; Lecture de l'encodeur
		sbrs	StatReg1,FlagIncremente				; doit-on incrémenter
		sbrc	StatReg1,FlagDecremente				; ou décrémenter ?
		rjmp	MenuChangeT							; l'un des deux...

		sbis	PinSwitchMC,SwitchMC				; Un appui sur le bouton d'annulation pour sortir sans sauver ?
		rjmp	ExitAjusteDisplayTMenuNoSave		; Oui, alors on y va

		sbic	PinMenu,SwitchMenu					; Un appui sur Menu ?
		rjmp 	LoopLevelDispAdj0T					; Non, on boucle

		rjmp	ExitAjusteDisplayTMenu				; sinon on se sauve en sauvant

MenuChangeT:

		sbrc	StatReg1,FlagIncremente				; regarde dans quel sens allait l'encodeur
		rjmp	IncTMenuReg1						; Vers le haut ?
		sbrc	StatReg1,FlagDecremente				; 
		rjmp	DecTMenuReg1						; vers le bas ?
		rjmp	LoopLevelDispAdj0T					; Aucun des deux, alors cassos

IncTMenuReg1:										; Incrémentation du paramètre
		mov		Work,MenuReg1
		cpi		Work,241							; c'est le max ?
		brlo	DoIncTMR1							; non, alors on peut incrémenter sans pb

		rjmp	LoopLevelDispAdj0T					; Sinon, on ne fait rien

DoIncTMR1:
		cpi		Work,0								; Désactivé
	    breq	LoopLevelDispAdj0T					; on n'incrémente pas

		cpi		Work,240							; 1 heure ?
		breq	TOHtoOff							; On passe à 0 pour "Never"
		cpi		Work,1								; 15 secondes ?
		breq	TO15To30							; on passe à 30 s
		cpi		Work,2								; 30 secondes ?
		breq	TO30To1								; on passe à 1 min
		cpi		Work,4								; 1 minute ?
		breq	TO1To2								; on passe à 2 min
		cpi		Work,8								; 2 minutes ?
		breq	TO2To5								; on passe à 5 min

		subi	Work,-20							; On ajoute 5 minutes...
		mov		MenuReg1,Work						; Et on remet ça dans le bon registre
		rjmp	MenuActualiseT						; et on modifie la durée
TOHToOff:
		ldi		Work,0								; Valeur pour désactiver le TimeOut
		mov		MenuReg1,Work						; Et on remet ça dans le bon registre
		rjmp	MenuActualiseT						; et on modifie la durée

TO15To30:
		ldi		Work,2								; Valeur pour 30 secondes
		mov		MenuReg1,Work						; Et on remet ça dans le bon registre
		rjmp	MenuActualiseT						; et on modifie la durée

TO30To1:
		ldi		Work,4								; Valeur pour 1 minute
		mov		MenuReg1,Work						; Et on remet ça dans le bon registre
		rjmp	MenuActualiseT						; et on modifie la durée

TO1To2:
		ldi		Work,8								; Valeur pour 2 minutes
		mov		MenuReg1,Work						; Et on remet ça dans le bon registre
		rjmp	MenuActualiseT						; et on modifie la durée

TO2To5:
		ldi		Work,20								; Valeur pour 5 minutes
		mov		MenuReg1,Work						; Et on remet ça dans le bon registre
		rjmp	MenuActualiseT						; et on modifie la durée

DecTMenuReg1:										; Décrémentation de la luminosité
		mov		Work,MenuReg1						; transfert dans un registre immédiat
		cpi		Work,1								; c'est le min ?
		brne	DoDecTMR1							; non, alors on peut décrémenter sans pb

		rjmp	LoopLevelDispAdj0T					; Sinon, on ne fait rien

DoDecTMR1:
		cpi		Work,0								; Désactivé
		breq	TOOffToH							; On passe à 1 Heure
		cpi		Work,2								; 30 secondes ?
		breq	TO30To15							; On passe à 15 secondes
		cpi		Work,4								; 1 minute ?
		breq	TO1To30								; On passe à 30 secondes
		cpi		Work,8								; 2 minutes ?
		breq	TO2To1								; On passe à 1 minute
		cpi		Work,20								; 5 minutes ?
		breq	TO5To2								; On passe à 2 minutes

		subi	Work,20								; 5 minutes de moins...
		mov		MenuReg1,Work						; Et on remet ça dans le bon registre
		rjmp	MenuActualiseT						; et on modifier la durée
TOOffToH:
		ldi		Work,240							; Valeur pour 1 Heure
		mov		MenuReg1,Work						; Et on remet ça dans le bon registre
		rjmp	MenuActualiseT						; et on modifier la durée

TO30To15:
		ldi		Work,1								; Valeur pour 30 secondes
		mov		MenuReg1,Work						; Et on remet ça dans le bon registre
		rjmp	MenuActualiseT						; et on modifier la durée

TO1To30:
		ldi		Work,2								; Valeur pour 30 secondes
		mov		MenuReg1,Work						; Et on remet ça dans le bon registre
		rjmp	MenuActualiseT						; et on modifier la durée

TO2To1:
		ldi		Work,4								; Valeur pour 1 Minute
		mov		MenuReg1,Work						; Et on remet ça dans le bon registre
		rjmp	MenuActualiseT						; et on modifier la durée

TO5To2:
		ldi		Work,8								; Valeur pour 2 minutes
		mov		MenuReg1,Work						; Et on remet ça dans le bon registre
		rjmp	MenuActualiseT						; et on modifier la durée

MenuActualiseT:										; On modifie vraiment la durée

		lds		Work,TCCR3B							; si le timer 3 ne tourne pas
		andi	Work,0b00000111						; on lance le clignotement de la LED On
		cpi		Work,0								; car on a modifié la valeur qui était stockée
		brne	DoMenuActualiseT						
		call	LanceClignotementLED

DoMenuActualiseT:
		cbr		StatReg1,EXP2(FlagIncremente)		; On commence par remettre à 0 les flags de l'encodeur
		cbr		StatReg1,EXP2(FlagDecremente)

		mov		Work,MenuReg1						; On transfère le paramètre dans le bon regsitre

		rcall	AfficheIdleTimeOut					; et affiche la valeur
		rjmp	LoopLevelDispAdj0T					; Boucle Again

ExitAjusteDisplayTMenuNoSave:						; On se sauve sans sauver...

		sbis	PinSwitchMC,SwitchMC				; petit test habituel pour ne pas effectuer
		rjmp	ExitAjusteDisplayTMenuNoSave		; des sorties de menu en cascade

		call	ArreteClignotementLED				; Au cazoù, on rallume la LED de On/StandBy

		ldi		ZH,RAM_Start						; Octet de poids fort de l'adresse de début en RAM 
		ldi		ZL,RAM_IdleTimeOut					; L'adresse de ce paramètre en RAM
		ld		Work,Z							 	; Récupère la valeur stockée en RAM
		ret

ExitAjusteDisplayTMenu:
		sbis	PinMenu,SwitchMenu					; petit test habituel pour ne pas effectuer
		rjmp	ExitAjusteDisplayTMenu				; des sorties de menu en cascade

		call	ArreteClignotementLED				; Au cazoù, on rallume la LED de On/StandBy

		ldi		Work,SaveLong						; Fixe le temps d'affichage du prochain message
		call	AfficheSaving						; Affiche le message de sauvegarde

		ldi		ZH,RAM_Start						; Octet de poids fort de l'adresse de début en RAM 
		ldi		ZL,RAM_IdleTimeOut					; L'adresse de ce paramètre en RAM
		st		Z,MenuReg1							; et enregistre la valeur en RAM

		mov		Work2,MenuReg1						; La donnée à enregistrer en EEPROM
		ldi		Work,EE_IdleTimeOut					; et son adresse					
		call	WriteEEprom							; on enregistre

		ret											; et cassos

; ============================================================
; == Extinction ou non de la led "on" en mode Idle          ==
; ==                                                        ==
; ==   - Encodeur -> Choisir Yes/No 	                    ==
; ==   - Menu     -> Valider la nouvelle valeur             ==
; ==   - StandBy  -> Remonter au menu précédent sans sauver ==
; ============================================================

MenuAjusteDisplayL:

WaitMenuAjusteDisplayL:
		sbis	PinMenu,SwitchMenu					; Avant de passer à la suite,
		rjmp	WaitMenuAjusteDisplayL				; On attend le relachement du bouton de menu

; Bouton relâché, on continue

		ldi		Work,0								; Se place au début
		call	DisplayPlaceCurseur

		ldi		ZH,HIGH(MenuDisplayIdleLedTopMessage*2)
		ldi		ZL,LOW(MenuDisplayIdleLedTopMessage*2)
		call	DisplayAfficheChaine

; On récupère la valeur de la luminosité en RAM

		ldi		ZH,RAM_Start						; Octet de poids fort de l'adresse de début en RAM 
		ldi		ZL,RAM_IdleLed						; L'adresse de ce paramètre en RAM

		ld		MenuReg1,Z							; Récupère la valeur stockée en RAM dans MenuReg1

		rcall	AfficheIdleLed						; On affiche la valeur en seconde ligne

LoopLevelDispAdj0L:

		call 	LectureEncodeur						; Lecture de l'encodeur
		sbrs	StatReg1,FlagIncremente				; doit-on incrémenter
		sbrc	StatReg1,FlagDecremente				; ou décrémenter ?
		rjmp	MenuChangeL							; l'un des deux...

		sbis	PinSwitchMC,SwitchMC				; Un appui sur le bouton d'annulation pour sortir sans sauver ?
		rjmp	ExitAjusteDisplayLMenuNoSave		; Oui, alors on y va

		sbic	PinMenu,SwitchMenu					; Un appui sur Menu ?
		rjmp 	LoopLevelDispAdj0L					; Non, on boucle

		rjmp	ExitAjusteDisplayLMenu				; sinon on se sauve en sauvant

MenuChangeL:

		sbrc	StatReg1,FlagIncremente				; regarde dans quel sens allait l'encodeur
		rjmp	ChangeLMenuReg1						; Vers le haut ?
		sbrc	StatReg1,FlagDecremente				; 
		rjmp	ChangeLMenuReg1						; vers le bas ?
		rjmp	LoopLevelDispAdj0L					; Aucun des deux, alors cassos

ChangeLMenuReg1:									; Juste à transformer les 0 en 1 ou 1 en 0 

		inc		MenuReg1							; on ajoute 1
		ldi		Work,0b00000001
		and		MenuReg1,Work						; et on met à zéro tous les bits, sauf le premier

		lds		Work,TCCR3B							; si le timer 3 ne tourne pas
		andi	Work,0b00000111						; on lance le clignotement de la LED On
		cpi		Work,0								; car on a modifié la valeur qui était stockée
		brne	DoMenuActualiseL						
		call	LanceClignotementLED

DoMenuActualiseL:
		cbr		StatReg1,EXP2(FlagIncremente)		; On commence par remettre à 0 les flags de l'encodeur
		cbr		StatReg1,EXP2(FlagDecremente)

		rcall	AfficheIdleLed						; et affiche la valeur
		rjmp	LoopLevelDispAdj0L

ExitAjusteDisplayLMenuNoSave:						; On se sauve sans sauver...

		sbis	PinSwitchMC,SwitchMC				; petit test habituel pour ne pas effectuer
		rjmp	ExitAjusteDisplayLMenuNoSave		; des sorties de menu en cascade

		call	ArreteClignotementLED				; Au cazoù, on rallume la LED de On/StandBy

		ret

ExitAjusteDisplayLMenu:
		sbis	PinMenu,SwitchMenu					; petit test habituel pour ne pas effectuer
		rjmp	ExitAjusteDisplayLMenu				; des sorties de menu en cascade

		call	ArreteClignotementLED				; Au cazoù, on rallume la LED de On/StandBy

		ldi		Work,SaveLong						; Fixe le temps d'affichage du prochain message
		call	AfficheSaving						; Affiche le message de sauvegarde

		ldi		ZH,RAM_Start						; Octet de poids fort de l'adresse de début en RAM 
		ldi		ZL,RAM_IdleLed						; L'adresse de ce paramètre en RAM
		st		Z,MenuReg1							; et enregistre la valeur en RAM

		mov		Work2,MenuReg1						; La donnée à enregistrer en EEPROM
		ldi		Work,EE_IdleLed						; et son adresse					
		call	WriteEEprom							; on enregistre

		ret

; =============================================================
; == Affichage de la valeur de la luminosité ou du contraste ==
; == Cette valeur est contenue dans MenuReg1                 ==
; =============================================================

AfficheBrightnessOrContrast:

		ldi		Work,0x40							; Début de seconde ligne
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuDisplayValueMessage*2)
		ldi		ZL,LOW(MenuDisplayValueMessage*2)
		call	DisplayAfficheChaine
		call	DisplayArrow

		ldi		Work,0x4A							; Curseur au bon endroit
		call	DisplayPlaceCurseur

		mov		Work1,MenuReg1						; Dans un registre immédiat

		call 	Affiche255							; et on affiche la valeur

		ldi		Char,32								; et deux blancs pour éventuellement effacer le reste
		call	DisplayWriteChar
		call	DisplayWriteChar

		ret											; et voilà

; =================================================
; == Affiche le trigger pour l'entrée considérée ==
; == Le numéro de l'entrée est dans MenuReg1     ==
; =================================================

AfficheIdleLed:

		ldi		Work,0x40							; Début de seconde ligne
		call	DisplayPlaceCurseur

		mov		Work2,MenuReg1
		cpi		Work2,0								; Eteindre la Led ?
		brne	MenuIdleLedEcrireOff				; 	- Oui (Valeur > 0)

		ldi		ZH,HIGH(MenuIdleLedOnMessage*2)
		ldi		ZL,LOW(MenuIdleLedOnMessage*2)
		call	DisplayAfficheChaine
		call	DisplayArrow

		ret											; évouala

MenuIdleLedEcrireOff:
		ldi		ZH,HIGH(MenuIdleLedOffMessage*2)
		ldi		ZL,LOW(MenuIdleLedOffMessage*2)
		call	DisplayAfficheChaine
		call	DisplayArrow

		ret											; écéfini

; =============================================================
; == Affichage de la valeur de la luminosité ou du contraste ==
; == Cette valeur est contenue dans MenuReg1                 ==
; =============================================================

AfficheIdleTimeOut:

		ldi		Work,0x40							; Début de seconde ligne
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuDisplayTOValueMessage*2)
		ldi		ZL,LOW(MenuDisplayTOValueMessage*2)
		call	DisplayAfficheChaine
		call	DisplayArrow

		mov		Work1,MenuReg1						; Dans un registre immédiat

		cpi		Work1,0								; Pour '0', on affiche "Never"							
		breq	TimeOutNever

		cpi		Work1,240							; pour 240, afficher '1 hour'
		breq	TimeOutOneHour

		cpi		Work1,5								; Moins de 2 minutes 
		brlo	TimeOutOneOrLess

		ldi		Work,0x45							; Curseur en position pour les dizaines de minutes
		cpi		Work1,40							; c'est bien plus de 5 minutes ?
		brsh	TimeOutLocCursor					; Vi alors Go

		ldi		Work,0x46							; Sinon curseur pour les unités

TimeOutLocCursor:
		call	DisplayPlaceCurseur

; Comme "l'unité" est de 15 secondes, on divise la valeur par 4 pour avoir le temps en minutes...

		lsr		Work1								; Divise par 2
		lsr		Work1								; Et encore par deux

		mov		LSDVol,Work1						; on transfère dans le registre de 'conversion'
		call	BinaireToBCD						; et on convertit en décimal

		ldi		Work,48								; Y-a-t-il un 0 au début (48 en Ascii)
		cp		Work,MSDVol						
		breq	TimeOutAffUnits						; Oui -> On n'affiche que les unités
		
		mov		Char,MSDVol							; Sinon, on affiche le chiffre
		call	DisplayWriteChar

TimeOutAffUnits:									; On affiche les unités des minutes...
		mov		Char,LSDVol
		call	DisplayWriteChar						
		call	AfficheToMinutes		
		ret											; et oualà

TimeOutNever:										; On écrit "Off"
		ldi		Work,0x48
		call	DisplayPlaceCurseur
		call	AfficheToNever
		ret	

TimeOutOneHour:										; On écrit '1 hour'
		ldi		Work,0x47
		call	DisplayPlaceCurseur
		ldi 	Char,'1'
		call	DisplayWriteChar
		ldi 	Char,32
		call	DisplayWriteChar
		ldi 	Char,'H'
		call	DisplayWriteChar
		ldi 	Char,'o'
		call	DisplayWriteChar
		ldi 	Char,'u'
		call	DisplayWriteChar
		ldi 	Char,'r'
		call	DisplayWriteChar
		
		ret
			
TimeOutOneOrLess:
		ldi		Work,0x46
		call	DisplayPlaceCurseur

		cpi		Work1,4								; Une minute ?
		brne	TimeOut30Seconds

		ldi		Char,'1'							; Et on affiche 'Minute'
		call	DisplayWriteChar
		ldi		Char,32
		call	DisplayWriteChar						
		ldi		Char,'M'							
		call	DisplayWriteChar						
		ldi		Char,'i'
		call	DisplayWriteChar						
		ldi		Char,'n'
		call	DisplayWriteChar						
		ldi		Char,'u'
		call	DisplayWriteChar						
		ldi		Char,'t'
		call	DisplayWriteChar						
		ldi		Char,'e'
		call	DisplayWriteChar						

		ret

TimeOut30Seconds:									; On affiche "30 Seconds"

		ldi		Work,0x45
		call	DisplayPlaceCurseur
		
		cpi		Work1,2								; 15 Secondes ?
		brne	TimeOut15Seconds

		ldi		Char,'3'
		call	DisplayWriteChar
		ldi		Char,'0'
		call	DisplayWriteChar
		ldi		Char,32
		call	DisplayWriteChar						
		ldi		Char,'S'							
		call	DisplayWriteChar						
		ldi		Char,'e'
		call	DisplayWriteChar						
		ldi		Char,'c'
		call	DisplayWriteChar						
		ldi		Char,'o'
		call	DisplayWriteChar						
		ldi		Char,'n'
		call	DisplayWriteChar						
		ldi		Char,'d'
		call	DisplayWriteChar						
		ldi		Char,'s'
		call	DisplayWriteChar						

		ret

TimeOut15Seconds:									; On affiche "15 Seconds"

		ldi		Work,0x45
		call	DisplayPlaceCurseur
		
		ldi		Char,'1'
		call	DisplayWriteChar
		ldi		Char,'5'
		call	DisplayWriteChar
		ldi		Char,32
		call	DisplayWriteChar						
		ldi		Char,'S'							
		call	DisplayWriteChar						
		ldi		Char,'e'
		call	DisplayWriteChar						
		ldi		Char,'c'
		call	DisplayWriteChar						
		ldi		Char,'o'
		call	DisplayWriteChar						
		ldi		Char,'n'
		call	DisplayWriteChar						
		ldi		Char,'d'
		call	DisplayWriteChar						
		ldi		Char,'s'
		call	DisplayWriteChar						

		ret

AfficheTOMinutes:
		ldi		Char,32
		call	DisplayWriteChar						
		ldi		Char,'M'							; Et on affiche 'Minutes'
		call	DisplayWriteChar						
		ldi		Char,'i'
		call	DisplayWriteChar						
		ldi		Char,'n'
		call	DisplayWriteChar						
		ldi		Char,'u'
		call	DisplayWriteChar						
		ldi		Char,'t'
		call	DisplayWriteChar						
		ldi		Char,'e'
		call	DisplayWriteChar						
		ldi		Char,'s'
		call	DisplayWriteChar						
				 
		ret

AfficheToNever:										; "Never" pour le time out désactivé
		ldi		Char,'N'
		call	DisplayWriteChar						
		ldi		Char,'e'
		call	DisplayWriteChar						
		ldi		Char,'v'
		call	DisplayWriteChar						
		ldi		Char,'e'
		call	DisplayWriteChar						
		ldi		Char,'r'
		call	DisplayWriteChar						

		ret
