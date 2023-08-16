; ======================================================================
; == Les routines pour les diff�rents relais, hormis le relais d'alim ==
; ======================================================================

; ---------------------
; -- Change d'entr�e --
; ---------------------

ChangeEntree:

; On cherche d'abord sur quel bouton on a appuy�,
; et en m�me temps, �a fait un peu de debouncing...

		sbic	PinsSwitches,SwitchIn1				; On a appuy� sur l'entr�e 1 (actif � 0) ?
		rjmp 	TestIn2								; 	- Non, alors on va tester l'autre entr�e
		ldi 	Work1,0								; 	- Oui, on m�morise le n� de l'entr�e
		rjmp	WaitIn1SwitchRelease				; 	  et on passe � la suite

TestIn2:
		sbic	PinsSwitches,SwitchIn2				; On a appuy� sur l'entr�e 2 (actif � 0) ?
		rjmp 	TestIn3								; 	- Non, alors on va tester l'entr�e suivante
		ldi 	Work1,1								; 	- Oui, on m�morise le n� de l'entr�e
		rjmp	WaitIn2SwitchRelease				; 	  et on passe � la suite

TestIn3:
		sbic	PinsSwitches,SwitchIn3				; On a appuy� sur l'entr�e 3 (actif � 0) ?
		rjmp 	TestIn4								; 	- Non, alors on va tester l'entr�e suivante
		ldi 	Work1,2								; 	- Oui, on m�morise le n� de l'entr�e
		rjmp	WaitIn3SwitchRelease				; 	  et on passe � la suite

TestIn4:
		sbic	PinsSwitches,SwitchIn4				; On a appuy� sur l'entr�e 4 (actif � 0) ?
		rjmp 	TestInTapeOrBypass					; 	- Non, alors on va tester le bouton suivant
		ldi 	Work1,3								; 	- Oui, on m�morise le n� de l'entr�e
		rjmp	WaitIn4SwitchRelease				; 	  et on passe � la suite

TestInTapeOrBypass:
		sbic	PinsSwitches,SwitchTapeOrBypass		; On a appuy� sur l'entr�e Tape/Bypass (actif � 0) ?
		ret											;	- Non, alors on se casse
		ldi 	Work1,4								; 	- Oui, on m�morise le n� de l'entr�e
		rjmp	WaitInTapeOrBypassSwitchRelease

WaitIn1SwitchRelease:								; On attend le rel�chement du bouton  de l'entr�e 1 avant de passer � autre chose
		sbis	PinsSwitches,SwitchIn1
		rjmp	WaitIn1SwitchRelease
		rjmp	ChangeEntreeStopIdle

WaitIn2SwitchRelease:								; On attend le rel�chement du bouton  de l'entr�e 2 avant de passer � autre chose
		sbis	PinsSwitches,SwitchIn2
		rjmp	WaitIn2SwitchRelease
		rjmp	ChangeEntreeStopIdle

WaitIn3SwitchRelease:								; On attend le rel�chement du bouton  de l'entr�e 3 avant de passer � autre chose
		sbis	PinsSwitches,SwitchIn3
		rjmp	WaitIn3SwitchRelease
		rjmp	ChangeEntreeStopIdle

WaitIn4SwitchRelease:								; On attend le rel�chement du bouton  de l'entr�e 4 avant de passer � autre chose
		sbis	PinsSwitches,SwitchIn4
		rjmp	WaitIn4SwitchRelease
		rjmp	ChangeEntreeStopIdle

WaitInTapeOrBypassSwitchRelease:					; On attend le rel�chement du bouton  de l'entr�e Tape/Bypass avant de passer � autre chose
		sbis	PinsSwitches,SwitchTapeOrBypass
		rjmp	WaitInTapeOrBypassSwitchRelease
		rjmp	ChangeEntreeStopIdle

ChangeEntreeStopIdle:								; On a bien appuy� sur un bouton
        sbrc	StatReg1,FlagIdle					; Si le timer d'Idle �tait en train de tourner,
		call	StopIdle							; alors on l'arr�te
		call	RestoreBrightness					; Sinon, on remet l'afficheur en pleine luminosit�

		call	IRClearIRSup						; Autre action que IR -> Efface le registre de speedup

ChangeEntreeAfterSwitches:							; Si on arrive l�, c'est qu'on a bien appuy� sur un bouton (et qu'on l'a rel�ch�)
													; ou qu'on a re�u une commande RC5

; On va tout d'abord v�rifier que l'entr�e s�lectionn�e n'est pas l'entr�e active,
; auquel cas pas besoin de s'emb�ter.

		ldi		ZH,RAM_Start						; R�cup�re en RAM
		ldi		ZL,RAM_EntreeActive					; le num�ro de l'entr�e active (l'ancienne)
		ld		Work,Z								; et r�cup�re la valeur

		cpse	Work,Work1							; Compare l'ancienne et la nouvelle
		rjmp	ChangeVraimentEntree				; Si ce n'est pas la m�me, on change vraiment...
		rjmp	ExitChangeEntree					; Si c'est la m�me -> Cassos, plus rien � faire ici

ChangeVraimentEntree:

; On commence par arr�ter le timer au cas o�, muter la sortie et d�sactiver tous les relais

		ldi		Work,TimerStop						; On arr�te le Timer 1
		out		TCCR1B,Work

		MacroMuteOn
		sbr		StatReg1,EXP2(FlagMute)				; Signale qu'on est en mute (bit � 1)
		call 	Attendre							; Attend un peu

		clr		Work								; On fait passer tous les relais d'entr�e
		out		PortRelaisIn,Work					; au repos (on coupe tout)

		lds		Work,PortAutresRelais				; R�cup�re l'�tat des autres relais
		cbr		Work,EXP2(RelaisAsym)				; Et les met dans l'�tat initial
#if !defined (BYPASS)
		cbr		Work,EXP2(RelaisTape)				; On s'occupe de ce relais seulement si c'est pas celui de bypass 
#endif
		cbr		StatReg1,EXP2(FlagAsym)				; Passe les flags correspondants � 0
		sts		PortAutresRelais,Work

; pour les besoins de triggering, on r�cup�re l'ancienne entr�e active

		ldi		ZH,RAM_Start						; R�cup�re en RAM
		ldi		ZL,RAM_EntreeActive					; le num�ro de l'entr�e active (l'ancienne, maintenant)
		ld		Work,Z								; et r�cup�re la valeur
		ldi		ZL,RAM_AncienneEntreeActive			; pour la mettre � sa place
		st		Z,Work

		ldi		ZH,RAM_Start						; Stocke en RAM
		ldi		ZL,RAM_EntreeActive					; le num�ro de l'entr�e maintenant active
		st		Z,Work1	

		call	TriggerSource						; Envoie (ou non) un trigger sur les sources

; On s'occupe du timer 1 pour la seconde de d�lai du mute

		ldi		Work,UneDemiSecHi					; On charge dedans
		out		TCNT1H,Work							; une premi�re demi-seconde
		ldi		Work,UneDemiSecLo					; pour avoir le d�lai entre l'activation 
		out 	TCNT1L,Work							; du relais de masse et le relais de signal

		sbr		StatReg2,EXP2(FlagWait)				; Met � 1 le flag d'attente 
													; C'est lui qui va nous servir � d�terminer o� on en est

		ldi		Work,TimerDiv						; Lance le Timer 1 en Ck/1024
		out 	TCCR1B,Work	

; On passe le volume � Z�ro (att�nuation maximale)
; pour �viter les plocs de commutation d'entr�e

		in		Work,PortVolume						; R�cup�re l'�tat des relais mute et volume
		andi	Work,0b10000000						; et on met tous le volume � z�ro (att�nuation max) sans toucher au relais de mute	
		out		PortVolume,Work 					; On remet ce registre � disposition sur le port de volume
		sbi		PortLatchVolG,LE_VolG				; Une impulsion pour le latch
		cbi		PortLatchVolG,LE_VolG
		sbi		PortLatchVolD,LE_VolD				; Une impulsion pour le latch
		cbi		PortLatchVolD,LE_VolD

; Pendant que le timer commence � tourner, on regarde si on a affaire � une entr�e sym�trique ou non,
; puis si il faut un trigger, et on fait coller le relais de masse de l'entr�e

;		cpi		Work1,4								; L'entr�e � activer, c'est celle de tape ?
;		breq	ExitChangeEntree					; Oui, alors plus rien � faire...
			
 		ldi		ZL,RAM_BalIn1 						; R�cup�re en RAM l'indicateur d'entr�e sym�trique
		add		ZL,Work1							; Shifte pour pointer au bon endroit dans la RAM
		ld		Work,Z								; et r�cup�re la valeur

		cpi		Work,0								; C'est une entr�e sym�trique ?
		breq	LookFor6dB							; 	- Oui (Valeur � 0), alors on ne touche pas au relais, et on passe � autre chose

		lds		Work,PortAutresRelais				; 	- Sinon (Valeur � 1), on active le relais de dissym�trisation
		sbr		Work,EXP2(RelaisAsym)				;    (Au repos, on est en sym�trique, donc il faut que le relais de Bal/unBal soit activ� pour de l'asym�trique)
		sts		PortAutresRelais,Work				; Envoie �a sur le port des relais
		sbr		StatReg1,EXP2(FlagAsym)				; Passe le flag correspondant � 1

LookFor6dB:
		call	Want6dBMore							; Regarde si il faut 6 dB en plus dans le cas d'une entr�e asym�trique
	    call	InputVol							; Faut-il ajuster le volume pour cette entr�e
					
; Activation des relais de masse

ActiveGND:											; Active le relais de masse pour l'entr�e s�lectionn�e
		cpi 	Work1,0								; C'est l'entr�e 1 ?
		brne	ActiveGND2							; Nan, on teste la suivante
		sbi		PortRelaisIn,RelaisGNDIn1			; Oui, alors on met la masse en circuit
		rjmp	ExitChangeEntree					; et on va lancer le Timer 1

ActiveGND2:
		cpi 	Work1,1								; C'est l'entr�e 2 ?
		brne	ActiveGND3							; Nan, on teste la suivante
		sbi		PortRelaisIn,RelaisGNDIn2			; Oui, alors on met la masse en circuit
		rjmp	ExitChangeEntree					; et on va lancer le Timer 1

ActiveGND3:
		cpi 	Work1,2								; C'est l'entr�e 3 ?
		brne	ActiveGND4							; Nan, on teste la suivante
		sbi		PortRelaisIn,RelaisGNDIn3			; Oui, alors on met la masse en circuit
		rjmp	ExitChangeEntree					; et on va lancer le Timer 1

ActiveGND4:
		sbi		PortRelaisIn,RelaisGNDIn4			; Si on arrive l�,pas d'autre chose � faire que de mettre la masse en circuit

ExitChangeEntree:
		call	AfficheEntree						; On affiche le nom de la nouvelle entr�e
		call	StartIdle							; On relance le timer de "fout rien"
		ret											; et c'est tout pour l'instant. Suite et Fin dans TimerRelay...

; -------------------------------------------
; -- Mise en route des relais au d�marrage --
; -------------------------------------------

StartRelays:

		ldi		ZH,RAM_Start						; Stocke en RAM
		ldi		ZL,RAM_EntreeActive					; le num�ro de l'entr�e active
		st		Z,Work1	

		cpi		Work1,4								; L'entr�e � activer, c'est celle de tape ?
		breq	ExitStartRelays			 			; Oui, alors plus rien � faire...
			
 		ldi		ZL,RAM_BalIn1 						; R�cup�re en RAM l'indicateur d'entr�e sym�trique
		add		ZL,Work1							; Shifte pour pointer au bon endroit dans la RAM
		ld		Work,Z								; et r�cup�re la valeur

		cpi		Work,0								; C'est une entr�e asym�trique ?
		breq	Start6dB							; 	- Non (Valeur � 0), alors on ne touche pas au relais, et on passe � autre chose

		lds		Work,PortAutresRelais				; 	- Sinon (Valeur � 1), on active le relais de Bal/UnBal
		sbr		Work,EXP2(RelaisAsym)
		sts		PortAutresRelais,Work
		sbr		StatReg1,EXP2(FlagAsym)				; Passe le flag correspondant � 1

Start6dB:
		call	Want6dBMore							; 6dB de plus pour une entr�e asym�trique ?
		call 	InputVolNew							; Un ajustement particulier du volume ?

; Activation des relais de masse

StartActiveGND:										; Active le relais de masse pour l'entr�e s�lectionn�e
		cpi 	Work1,0								; C'est l'entr�e 1 ?
		brne	StartActiveGND2						; Nan, on teste la suivante
		ldi		Work,RelaisOnlyGNDIn1				; Oui, alors on met la masse en circuit
		out		PortRelaisIn,Work					; en d�sactivant les autres relais de masse
		rjmp	ExitStartRelays						; et on va lancer le Timer 1

StartActiveGND2:
		cpi 	Work1,1								; C'est l'entr�e 2 ?
		brne	StartActiveGND3						; Nan, on teste la suivante
		ldi		Work,RelaisOnlyGNDIn2				; Oui, alors on met la masse en circuit
		out		PortRelaisIn,Work					; en d�sactivant les autres relais de masse
		rjmp	ExitStartRelays						; et on va lancer le Timer 1

StartActiveGND3:
		cpi 	Work1,2								; C'est l'entr�e 3 ?
		brne	StartActiveGND4						; Nan, on teste la suivante
		ldi		Work,RelaisOnlyGNDIn3				; Oui, alors on met la masse en circuit
		out		PortRelaisIn,Work					; en d�sactivant les autres relais de masse
		rjmp	ExitStartRelays						; et on va lancer le Timer 1

StartActiveGND4:
		ldi		Work,RelaisOnlyGNDIn4				; Si on arrive l�,pas d'autre chose � faire que de mettre la masse en circuit
		out		PortRelaisIn,Work					; pour l'entr�e 4

ExitStartRelays:
#if defined(BYPASS)
		lds		Work,PortAutresRelais				; R�cup�re l'�tat des autres relais
		sbr		Work,EXP2(RelaisBypass)				; et active le relais de bypass
		sts		PortAutresRelais,Work				; (Bypass d�sactiv� quand le relais est activ�)
#endif
		ret											; et c'est tout pour l'instant. Suite et Fin dans TimerRelay...

; ------------------------------------
; -- Fait coller le relais d'entr�e --
; ------------------------------------

ActiveRelaisEntree:

;		call	TriggerSource						; Envoie (ou non) un trigger

		ldi		ZH,RAM_Start
#if defined(BYPASS)
		sbrc	StatReg2,FlagBypass					; R�cup�re soit l'entr�e � activer
		ldi		ZL,RAM_In_Bypass					; soit l'entr�e de bypass
		sbrs	StatReg2,FlagBypass					; suivant l'�tat du flag
		ldi		ZL,RAM_EntreeActive
#else
		ldi		ZL,RAM_EntreeActive
#endif
		ld		Work,Z								; r�cup�re l'entr�e � activer

		cpi 	Work,0								; C'est l'entr�e 1 ?
		brne	ActiveIn2							; Nan, on teste la suivante
		sbi		PortRelaisIn,RelaisInput1			; Oui, alors on met l'entr�e en circuit
		rjmp	ExitActiveRelaisEntree				; et on s'en va...

ActiveIn2:
		cpi 	Work,1								; C'est l'entr�e 2 ?
		brne	ActiveIn3							; Nan, on teste la suivante
		sbi		PortRelaisIn,RelaisInput2			; Oui, alors on met l'entr�e en circuit
		rjmp	ExitActiveRelaisEntree				; et on s'en va...

ActiveIn3:
		cpi 	Work,2								; C'est l'entr�e 3 ?
		brne	ActiveIn4							; Nan, on teste la suivante
		sbi		PortRelaisIn,RelaisInput3			; Oui, alors on met l'entr�e en circuit
		rjmp	ExitActiveRelaisEntree				; et on s'en va...

ActiveIn4:
		cpi 	Work,3								; C'est l'entr�e 4 ?
		brne	ActiveTape							; Nan, on teste la suivante
		sbi		PortRelaisIn,RelaisInput4			; Oui, alors on met l'entr�e en circuit
		rjmp	ExitActiveRelaisEntree				; et on s'en va...

ActiveTape:
#if !defined(BYPASS)
		lds		Work,PortAutresRelais				; Si on arrive l�,pas d'autre chose � faire que de mettre l'entr�e 4 en circuit
		sbr		Work,EXP2(RelaisTape)
		sts		PortAutresRelais,Work
#endif
ExitActiveRelaisEntree:
		ret											; et c'est finito

; ------------------------------------
; -- Gestion des triggers de source --
; ------------------------------------

TriggerSource:

	    push	Work1								; Sauvegarde ce registre (il contient le n� de l'entr�e choisie)

		ldi		ZH,RAM_Start						; R�cup�re en RAM
		ldi		ZL,RAM_AncienneEntreeActive			; le num�ro de l'ancienne entr�e active
		ld		Work1,Z								; et r�cup�re la valeur
		cpi		Work1,4								; Si c'�tait l'entr�e tape (valeur=4)
		breq	TrigOn								; pas besoin de trigger l'extinction
		
		ldi		ZL,RAM_TrigIn1						; Sinon,adresse en RAM du d�but des triggers
		add		ZL,Work1							; Offset pour pointer au bon endroit
		ld 		Work,Z								; et met �a dans Work
		
		cpi		Work,0								; pas de trigger ?
		breq	TrigOn								; non, alors on passe � la suite
													; sinon, on envoie un trigger pour �teindre l'ancien truc

		subi	Work1,-3							; On ajoute 3 � l'adresse (Trig Inp1 =3, Trig Inp 2=4, etc...)

		sbrs	StatReg1,FlagMute					; Attention � ne pas d�sactiver le mute
		sbr		Work1,EXP2(RelaisMute)				; en transf�rant l'adresse
		sbrc	StatReg1,FlagMute					; (Le mute et les HC238/HC151 partagent le m�me port)
		cbr		Work1,EXP2(RelaisMute)

		out		PortAdresTrig,Work1					; Met l'adresse de l'entr�e sur le "bus"
		nop											; Petite attente de 500ns
		nop											; pour que tout soit stable
		sbis	PinTriggerIn,LectureTrigIn			; Si le truc �tait �teint, (Lecture sur le HC151)
		rjmp	TrigOn								; Pas besoin de l'�teindre
		sbi		PortTriggers,LatchTrigOut			; Sinon, envoie un pulse de latch sur le 74HC238 de la t�l�commande
		call	Attendre							; Le temps que l'impulsion fasse effet
		cbi		PortTriggers,LatchTrigOut			; et toutes les sorties du HC238 retombent � z�ro

TrigOn:												; Autre point d'entr�e de la routine
		ldi		ZH,RAM_Start						; R�cup�re en RAM
		ldi		ZL,RAM_EntreeActive					; le num�ro de la nouvelle entr�e active
		ld		Work1,Z								; et r�cup�re la valeur
		cpi		Work1,4								; Si c'est l'entr�e tape (valeur=4)
		breq	ExitTrigger							; on ne va pas plus loin.

		ldi		ZL,RAM_TrigIn1						; Adresse en RAM du d�but des triggers
		add		ZL,Work1							; On ajoute le num�ro de l'entr�e (0--3) � l'adresse pour pointer au bon endroit
		ld		Work,Z								; et charge le comportement du trigger

		cpi 	Work,0								; Pas de trigger ?
		breq	ExitTrigger							; non, alors on passe � la suite

		subi	Work1,-3							; On ajoute 3 � l'adresse (Trig Inp1 =3, Trig Inp 2=4, etc...)

		sbrs	StatReg1,FlagMute					; Attention � ne pas d�sactiver le mute
		sbr		Work1,EXP2(RelaisMute)				; en transf�rant l'adresse
		sbrc	StatReg1,FlagMute					; (Le mute et les HC238/HC151 partagent le m�me port)
		cbr		Work1,EXP2(RelaisMute)

		out		PortAdresTrig,Work1					; Met l'adresse de l'entr�e sur le "bus"
		nop											; Petite attente de 500ns
		nop											; pour que tout soit stable
		sbic	PinTriggerIn,LectureTrigIn			; Si le truc �tait d�j� allum�,
		rjmp	ExitTrigger							; Pas besoin de le refaire...
		sbi		PortTriggers,LatchTrigOut			; Sinon, on envoie un pulse de latch sur le 74HC238 de la t�l�commande
		call	Attendre							; Le temps que l'impulsion fasse effet
		cbi		PortTriggers,LatchTrigOut			; et toutes les sorties du HC238 retombent � z�ro

ExitTrigger:
		pop		Work1								; restaure le registre pour retourner dans de bonnes conditions
		ret 										; et c'est fini

; --------------------------------------------------------------------------------------------
; -- On va regarder si il faut ajouter 6dB au volume (dans le cas d'une entr�e asym�trique) --
; --------------------------------------------------------------------------------------------

Want6dBMore:

		sbrs	StatReg2,Flag6dB					; Avait-on ajout� 6dB ?
		rjmp	No6dB								; 	- Non, on passe � la suite

		ldi		Work,SixdBMore						; 	- Oui, alors faut les enlever
		cp		VolReg,Work							; 	  si on peut...
		brge	Substract6dB						;     et l�, on peut.
		clr		VolReg								; sinon on le met au min
		rjmp	No6dB								; et on passe � la suite

Substract6dB:
		sub		VolReg,Work							; On retranche les 6dB							
No6dB:
		cbr		StatReg2,EXP2(Flag6dB)				; Met le flag correspondant � 0 dans le registre d'�tat
													; et on va maintenant regarder pour la nouvelle entr�e... 
		ldi		ZH,RAM_Start
		ldi		ZL,RAM_EntreeActive
		ld		Work,Z								; r�cup�re l'entr�e active

		ldi		ZL,RAM_BalIn1						; C'est une entr�e unbalanced ?
		add		ZL,Work								; Pointe sur la bonne entr�e
		ld		Work2,Z

		cpi		Work2,0								; Entr�e en RCA ?
		breq	ExitWant6dBMore						;   - Non -> va jouer plus loin

		ldi		ZL,RAM_In1_6dB						; 	- Oui -> Cette entr�e, il lui faut 6dB en plus ?
		add		ZL,Work
		ld		Work2,Z

		cpi		Work2,0								; 6dB de plus ?
		breq	ExitWant6dBMore						; 	- Non -> La suite
		sbr		StatReg2,EXP2(Flag6dB)				; 	- B�oui -> On met le flag � 1

		ldi		Work,(VolumeMaxi-SixdBMore+1)		; On peut augmenter de 6dB ?
		cp		VolReg,Work
		brge	Set6toMax							; 	 - B�non
		ldi		Work,SixdBMore						; 	 - B�oui
		add		VolReg,Work							; 	   alors on ajoute
		rjmp	ExitWant6dBMore						; et ouala

Set6ToMax:
		ldi		Work,VolumeMaxi						; sinon on met le volume au maxi...
		mov		VolReg,Work

ExitWant6dBMore:
		ret											; et c'est fini

; ---------------------------------------------------------------------------------------
; -- On va regarder de quelle valeur il faut modifier le volume individuel de l'entr�e --
; ---------------------------------------------------------------------------------------

InputVol:

; On commence par remettre le volume � la bonne valeur en annulant ce qui avait �t� fait avant
 
		ldi		ZH,RAM_Start						; R�cup�re en RAM
		ldi		ZL,RAM_AncienneEntreeActive			; le num�ro de l'ancienne entr�e active
		ld		Work,Z								; et r�cup�re la valeur

		ldi		ZL,RAM_ModVol_In1					; Quelle vamleur de modif de volume avait-on ?
		add		ZL,Work								; Pointe sur la bonne entr�e
		ld		Work2,Z

		cpi		Work2,0								; Si c'�tait z�ro
		breq	InputVolNew							; on ne change rien

		sbrs	Work2,7								; Sinon, on teste si c'�tait une valeur n�gative (bit 7 � 1) 
	    rjmp	InputVolWasMore						; ou positive (bit 7 � 0)
		rjmp	InputVolWasLess

InputVolWasMore:
		cp		VolReg,Work2						; Avant de soustraire la valeur, on v�rifie qu'on peut bien l'enlever
		brlo	OldVol2Min							; sinon, on met le volume au mini

		sub		VolReg,Work2						; On peut bien soustraire
		rjmp	InputVolNew

OldVol2Min:
		clr		VolReg								; Volume au mini
		rjmp	InputVolNew							; et on passe au volume de la nouvelle entr�e

InputVolWasLess:									; On avait enlev� du volume
		cbr		Work2,0b10000000					; on met le bit 7 � 0
		ldi		Work,VolumeMaxi						; On regarde si on peut rajouter 
		sub		Work,Work2							; la valeur de modif sans overflow
		cp		VolReg,Work
		brsh	OldVol2Max							; sinon, on met le volume au maxi

		add		VolReg,Work2						; On rajoute la valeur qu'on avait retranch�e
		rjmp	InputVolNew							; et on passe au nouveau volume

OldVol2Max:
		ldi		Work,VolumeMaxi						; sinon on met au maxi
		mov		VolReg,Work							; et on passe � la suite


InputVolNew:
		ldi		ZH,RAM_Start						; R�cup�re en RAM
		ldi		ZL,RAM_EntreeActive					; le num�ro de la nouvelle entr�e active
		ld		Work,Z								; et r�cup�re la valeur

		ldi		ZL,RAM_ModVol_In1					; Quelle valeur de modif de volume veut-on ?
		add		ZL,Work								; Pointe sur la bonne entr�e
		ld		Work2,Z

InputVolNewNoRam:
		cpi		Work2,0								; Si c'est z�ro
		breq	ExitInputVol						; on ne change rien

		sbrs	Work2,7								; Sinon, on teste si c'est une valeur n�gative (bit 7 � 1) 
	    rjmp	InputVolIsMore						; ou positive (bit 7 � 0)

InputVolIsLess:
		cbr		Work2,0b10000000					; on met le bit 7 � 0
		cp		VolReg,Work2						; Avant de soustraire la valeur, on v�rifie qu'on peut bien l'enlever
		brlo	NewVol2Min							; sinon, on met le volume au mini

		sub		VolReg,Work2						; On peut bien soustraire
		rjmp	ExitInputVol

NewVol2Min:
		clr		VolReg								; Volume au mini
		rjmp	ExitInputVol						; et on passe au volume de la nouvelle entr�e

InputVolIsMore:										; On veut ajouter du volume
		ldi		Work,VolumeMaxi						; On regarde si on peut rajouter 
		sub		Work,Work2							; la valeur de modif sans overflow
		cp		VolReg,Work
		brsh	NewVol2Max							; sinon, on met le volume au maxi

		add		VolReg,Work2						; On rajoute la valeur qu'on avait retranch�e
		rjmp	ExitInputVol						; et on passe au nouveau volume

NewVol2Max:
		ldi		Work,VolumeMaxi						; on taquine les taquets
		mov		VolReg,Work

ExitInputVol:
		ret											; et c'est fini

; ================================================
; == Mise en route et arr�t du bypass de l'UGS
; ================================================
#if defined(BYPASS)
BypassOnOff:

		sbic	PinsSwitches,SwitchTapeOrBypass		; C'est bien un appui sur le bouton ?  (actif � 0) ?
		ret											;	- Non, alors on se casse

WaitBypassSwitchRelease:							; On attend le rel�chement du bouton  de l'entr�e Tape/Bypass avant de passer � autre chose
		sbis	PinsSwitches,SwitchTapeOrBypass
		rjmp	WaitBypassSwitchRelease
		rjmp	BypassStopIdle

BypassStopIdle:										; On a bien appuy� sur le bouton
        sbrc	StatReg1,FlagIdle					; Si le timer d'Idle �tait en train de tourner,
		call	StopIdle							; alors on l'arr�te
		call	RestoreBrightness					; Sinon, on remet l'afficheur en pleine luminosit�

		call	IRClearIRSup		 				; Autre action que IR -> Efface le registre de speedup
			
BypassAfterSwitches:								; Si on arrive l�, c'est qu'on a bien appuy� sur le bouton (et qu'on l'a rel�ch�)
													; ou qu'on a re�u une commande RC5
; On commence par arr�ter le timer au cas o�

		ldi		Work,TimerStop						; On arr�te le Timer 1
		out		TCCR1B,Work

; On v�rifie qu'il y a bien une entr�e � Bypasser...

		ldi		ZH,RAM_Start
		ldi		ZL,RAM_In_Bypass
		ld		Work,Z								; r�cup�re ce num�ro
		cpi		Work,4								; et si c'est pas 4, 
		brne	ConfirmBypassOnOff					; ben on s'y jette vraiment

; Sinon on affiche pendant 2 secondes un message comme quoi on peut pas, et tout et tout...

		ldi		Work,0								; Se place au d�but
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(NoBypassMessageL1*2)		; Affiche la premi�re ligne du message
		ldi		ZL,LOW(NoBypassMessageL1*2)
		call	DisplayAfficheChaine

		ldi		Work,0x40							; Se place au d�but
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(NoBypassMessageL2*2)		; de la seconde ligne du message
		ldi		ZL,LOW(NoBypassMessageL2*2)
		call	DisplayAfficheChaine

		sbr		StatReg1,EXP2(FlagBalance)			; Le process est exactement le m�me que pendant l'affichage de balance,
													; alors on en profite
		clr		Work
		sts		TCCR3B,Work							; Arr�te le timer 3

		ldi		Work,DeuxSecHi
		sts		TCNT3H,Work
		ldi		Work,DeuxSecLo
		sts		TCNT3L,Work
		ldi		Work,TimerDiv						; et relance le timer en CK1024
		sts		TCCR3B,Work				

		rjmp	ExitBypass							; et on s'en va, au timer de finir le boulot

ConfirmBypassOnOff:

; Mute de la sortie 

		MacroMuteOn
		sbr		StatReg1,EXP2(FlagMute)				; Signale qu'on est en mute (bit � 1)

; On s'occupe du timer 1 pour la seconde de d�lai du mute

		ldi		Work,UneDemiSecHi					; On charge dedans
		out		TCNT1H,Work							; une premi�re demi-seconde
		ldi		Work,UneDemiSecLo					; pour avoir le d�lai entre l'activation 
		out 	TCNT1L,Work							; du relais de masse et le relais de signal

		sbr		StatReg2,EXP2(FlagWait)				; Met � 1 le flag d'attente 
													; C'est lui qui va nous servir � d�terminer o� on en est

		ldi		Work,TimerDiv						; Lance le Timer 1 en Ck/1024
		out 	TCCR1B,Work	

		sbrs	StatReg2,FlagBypass					; �tait-on d�j� en bypass ?
	    rjmp	Bypass2On							; non, alors on passe en Bypass

; -- Ici, on passe du bypass vers le mode de fontionnement normal

Bypass2Off:
	    cbr		StatReg2,EXP2(FlagBypass)			; D�sactive le Flag de Bypass

		ldi		Work,RelaisAllGND					; On active tous les relais de masse des entr�es
		out		PortRelaisIn,Work					; Et �a d�sactive en m�me temps les relais d'entr�e

		lds		Work,PortAutresRelais				; R�cup�re l'�tat des autres relais sur le port du relais bypass
		sbr		Work,EXP2(RelaisBypass)				; Et d�sactive le relais de bypass (bypass inactif quand le relais est "on")
		sts		PortAutresRelais,Work				; et transmet �a au port concern�

		call 	Attendre							; Attend un peu

		lds		Work,PortAutresRelais				; R�cup�re l'�tat des autres relais
		cbr		Work,EXP2(RelaisAsym)				; Et les met dans l'�tat initial
		cbr		StatReg1,EXP2(FlagAsym)				; Passe les flags correspondants � 0
		sts		PortAutresRelais,Work

; On passe le volume � Z�ro (att�nuation maximale)
; pour �viter les plocs de commutation d'entr�e

		in		Work,PortVolume						; R�cup�re l'�tat des relais mute et volume
		andi	Work,0b10000000						; et on met tous le volume � z�ro (att�nuation max) sans toucher au relais de mute	
		out		PortVolume,Work 					; On remet ce registre � disposition sur le port de volume
		sbi		PortLatchVolG,LE_VolG				; Une impulsion pour le latch de gauche
		cbi		PortLatchVolG,LE_VolG
		sbi		PortLatchVolD,LE_VolD				; Une impulsion pour le latch de droite, on n'est pas sectaire
		cbi		PortLatchVolD,LE_VolD

; Pendant que le timer commence � tourner, on regarde si on a affaire � une entr�e sym�trique ou non,

		ldi		ZH,RAM_Start						; R�cup�re en RAM
		ldi		ZL,RAM_EntreeActive					; le num�ro de l'entr�e qui �tait activ�e pr�c�demment
		ld		Work1,Z								; et r�cup�re la valeur
		rjmp	FinishBypass						; Passe au Bal/Unbal et relais de masse

; -- Ici, on passe en mode bypass

Bypass2On:

	    sbr		StatReg2,EXP2(FlagBypass)			; Active le Flag de Bypass

		call 	Attendre							; Attend un peu

;		clr		Work								; On fait passer tous les relais d'entr�e
;		out		PortRelaisIn,Work					; au repos (on coupe tout)

		lds		Work,PortAutresRelais				; R�cup�re l'�tat des autres relais
		cbr		Work,EXP2(RelaisAsym)				; Et les met dans l'�tat initial
		cbr		StatReg1,EXP2(FlagAsym)				; Passe les flags correspondants � 0
		sts		PortAutresRelais,Work

		ldi		ZH,RAM_Start						; R�cup�re en RAM
		ldi		ZL,RAM_In_Bypass					; le num�ro de l'entr�e � bypasser
		ld		Work1,Z								; et r�cup�re la valeur

FinishBypass:
 		ldi		ZL,RAM_BalIn1 						; R�cup�re en RAM l'indicateur d'entr�e sym�trique
		add		ZL,Work1							; Shifte pour pointer au bon endroit dans la RAM
		ld		Work,Z								; et r�cup�re la valeur

		cpi		Work,0								; C'est une entr�e sym�trique ?
		breq	BPActiveGND							; 	- Oui (Valeur � 0), alors on ne touche pas au relais, et on passe � autre chose

		lds		Work,PortAutresRelais				; 	- Sinon (Valeur � 1), on active le relais de dissym�trisation
		sbr		Work,EXP2(RelaisAsym)				;    (Au repos, on est en sym�trique, donc il faut que le relais de Bal/unBal soit activ� pour de l'asym�trique)
		sts		PortAutresRelais,Work				; Envoie �a sur le port des relais
		sbr		StatReg1,EXP2(FlagAsym)				; Passe le flag correspondant � 1

; Activation du relais de masse

BPActiveGND:										; Active le relais de masse pour l'entr�e s�lectionn�e
		cpi 	Work1,0								; C'est l'entr�e 1 ?
		brne	BPActiveGND2						; Nan, on teste la suivante
		ldi		Work,RelaisOnlyGNDIn1				;  - Oui, alors on met la masse en circuit
		out		PortRelaisIn,Work					;    en d�sactivant les autres relais de masse
		rjmp	ExitBypassOnOff						; et on va lancer le Timer 1

BPActiveGND2:
		cpi 	Work1,1								; C'est l'entr�e 2 ?
		brne	BPActiveGND3						; Nan, on teste la suivante
		ldi		Work,RelaisOnlyGNDIn2				;  - Oui, alors on met la masse en circuit
		out		PortRelaisIn,Work					;    en d�sactivant les autres relais de masse
		rjmp	ExitBypassOnOff						; et on va lancer le Timer 1

BPActiveGND3:
		cpi 	Work1,2								; C'est l'entr�e 3 ?
		brne	BPActiveGND4						; Nan, on teste la suivante
		ldi		Work,RelaisOnlyGNDIn3				;  - Oui, alors on met la masse en circuit
		out		PortRelaisIn,Work					;    en d�sactivant les autres relais de masse
		rjmp	ExitBypassOnOff						; et on va lancer le Timer 1

BPActiveGND4:
		ldi		Work,RelaisOnlyGNDIn4				; Si on arrive l�,pas d'autre chose � faire que de mettre la masse de l'entr�e 4 en circuit
		out		PortRelaisIn,Work					; en d�sactivant les autres relais de masse

ExitBypassOnOff:
		sbrc	StatReg2,FlagBypass					; Si on vient de passer en mode bypass
		rjmp	ExitBypassOn						; On affiche sp�cialement cet �tat de fait

		call	AfficheEntree						; sinon, on affiche le nom de l'ancienne entr�e
		rjmp	ExitBypass							; et on se casse

ExitBypassOn:
		call 	AfficheBypass						; Affiche le message de Bypass
		
ExitBypass:
		call	StartIdle							; On relance le timer de "fout rien"
		ret											; et c'est tout pour l'instant. Suite et Fin dans TimerRelay...

; =======================================================================
; == Petite routine pour l'activation du bypass � la mise sous tension ==
; =======================================================================

StartOrByeBypass :

; -- On commence par lire en EEPROM le n� de l'entr�e � bypasser

		sbic	EECR,EEWE
		rjmp	StartOrByeBypass
        clr     Work
        out     EEARH,Work
		ldi		Work1,EE_In_Bypass				; Ce qu'on cherche � atteindre en EEPROM
		out		EEARL,Work1						; 
	    sbi		EECR,EERE						; Pr�pare l'EEPROM � la lecture
		in		Work2,EEDR						; lit la valeur en EEPROM et la met dans le registre Work2
	
; -- On regarde si par hasard il faut vraiment bypasser (n� < 4)

		cpi		Work2,4
		brne	BypassSym						; Vi, il faut bien un bypass (n� < 4), alors on y va

; -- Sinon, on active juste le relais de masse de l'entr�e pr�f�r�e, pour �viter les ronflettes

StartOnlyGndPref:
		sbic	EECR,EEWE
		rjmp	StartOnlyGndPref
        clr     Work
        out     EEARH,Work
		ldi		Work1,EE_StartInput				; Ce qu'on cherche � atteindre en EEPROM
		out		EEARL,Work1						; 
	    sbi		EECR,EERE						; Pr�pare l'EEPROM � la lecture
		in		Work2,EEDR						; lit la valeur en EEPROM et la met dans le registre Work2

; -- Avant de se lancer, on va d�sactiver le relais de bypass.

		lds		Work,PortAutresRelais			; R�cup�re l'�tat des autres relais
		sbr		Work,EXP2(RelaisBypass)			; et d�sactive le relais de bypass
		sts		PortAutresRelais,Work			; (Bypass d�sactiv� quand le relais est activ�)

; -- Au tour de l'entr�e par d�faut, maintenant

		cpi		Work2,0							; C'est l'entr�e 1 ?
		brne	SOnGnd2							;   nan, c'est-y la 2 ?
		ldi		Work,RelaisOnlyGNDIn1			;   vi, c'est la 1, alors on charge la config de relais a des couettes
		out		PortRelaisIn,Work				;   on envoie �a sur le port des relais
		ret										;   et zou, finito
SOnGnd2:
		cpi		Work2,1							; C'est l'entr�e 2 ?
		brne	SOnGnd3							;   nan, c'est-y la 3 ?
		ldi		Work,RelaisOnlyGNDIn2			;   vi, c'est la 2, alors on charge la config de relais a des couettes
		out		PortRelaisIn,Work				;   on envoie �a sur le port des relais
		ret										;   et zou, finished

SOnGnd3:
		cpi		Work2,2							; C'est l'entr�e 3 ?
		brne	SOnGnd4							;   nan, c'est-y la 4 ?
		ldi		Work,RelaisOnlyGNDIn3			;   vi, c'est la 2, alors on charge la config de relais a des couettes
		out		PortRelaisIn,Work				;   on envoie �a sur le port des relais
		ret										;   et zou, finished

SOnGnd4:
		ldi		Work,RelaisOnlyGNDIn4			;   Arriv� l�, c'est forc�ment la 4, alors on charge la config de relais a des couettes
		out		PortRelaisIn,Work				;   on envoie �a sur le port des relais
		ret										;   et zou, finished
	
; -- On regarde si cette entr�e est sym�trique ou non

BypassSym:
		sbic	EECR,EEWE
		rjmp	BypassSym
        clr     Work
        out     EEARH,Work
		ldi		Work1,EE_BalIn1					; Ce qu'on cherche � atteindre en EEPROM
		add		Work1,Work2						; Petite addition pour pointer sur la bonne adresse
		out		EEARL,Work1						; 
	    sbi		EECR,EERE						; Pr�pare l'EEPROM � la lecture
		in		Work1,EEDR						; lit la valeur en EEPROM et la met dans le registre Work1

		cpi		Work1,0							; L'entr�e est-elle assym�trique ?
		breq	SBTest1							; 	- Non (Valeur � 0), alors on ne touche pas au relais, et on passe � l'entr�e � activer

		lds		Work,PortAutresRelais			; 	- Sinon (Valeur � 1), on active le relais de Bal/UnBal
		sbr		Work,EXP2(RelaisAsym)
		sts		PortAutresRelais,Work
		
SBTest1:
		cpi		Work2,0							; c'est l'entr�e 1 ?
		brne	SBTest2							;  - Non -> Est-ce la 2 ?
		ldi		Work,RelaisOnlyGNDIn1			;  - Oui, alors on met la masse en circuit
		out		PortRelaisIn,Work				;    en d�sactivant les autres relais de masse
		sbi		PortRelaisIn,RelaisInput1		;    et on active le relais signal
		rjmp 	ActionStartBypass				;  et on se barre pour activer le relais de bypass (relais au repos)

SBTest2:
		cpi		Work2,1							; c'est l'entr�e 2 ?
		brne	SBTest3							;  - Non -> Est-ce la 3 ?
		ldi		Work,RelaisOnlyGNDIn2			;  - Oui, alors on met la masse en circuit
		out		PortRelaisIn,Work				;    en d�sactivant les autres relais de masse
		sbi		PortRelaisIn,RelaisInput2		;    et on active le relais signal
		rjmp 	ActionStartBypass				;  et on se barre pour activer le relais de bypass (relais au repos)

SBTest3:
		cpi		Work2,2							; c'est l'entr�e 3 ?
		brne	SBTest4							;  - Non -> Est-ce la 4 ?
		ldi		Work,RelaisOnlyGNDIn3			;  - Oui, alors on met la masse en circuit
		out		PortRelaisIn,Work				;    en d�sactivant les autres relais de masse
		sbi		PortRelaisIn,RelaisInput3		;    et on active le relais signal
		rjmp 	ActionStartBypass				;  et on se barre pour activer le relais de bypass (relais au repos)

SBTest4:										; Ce ne peut donc �tre que l'entr�e 4,
		ldi		Work,RelaisOnlyGNDIn4			; Alors on met la masse en circuit
		out		PortRelaisIn,Work				; en d�sactivant les autres relais de masse
		sbi		PortRelaisIn,RelaisInput4		; et on active le relais signal

ActionStartBypass:								; On met le relais de bypass au repos, ce qui met le bypass en circuit
		lds		Work,PortAutresRelais			; R�cup�re l'�tat des autres relais
		cbr		Work,EXP2(RelaisBypass)			; et d�sactive le relais de bypass
		sts		PortAutresRelais,Work			; (Bypass activ� quand le relais est d�sactiv�)

#endif

