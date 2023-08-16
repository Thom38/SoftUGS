; ===========================================================
; === Traitement des commandes RC5 si jamais on en re�oit ===
; ===========================================================

RecRC5:

		cbr		StatReg2,EXP2(FlagIRRec)		; Flag de r�ception � 0

		rcall	IRDetect						; R�ception de qq chose ?

		sbrc	StatReg1,FlagPower				; Si le biniou est allum�, 
		rjmp	RC5ReadSysRam					; On va lire les commandes en RAM

		ser 	Work							; Erreur de r�ception ($FF dans les registres) ?
		cpse	SystemIR,Work
		rjmp	RC5ReadSysRam					; Non, re�u fort et clair, et on va voir ce que c'est
		ret										; Oui, erreur, alors on calte

RC5ReadSysRam:									; On est allum�, alors on lit en RAM
	
		ldi		ZH,RAM_Start
		ldi		ZL,RAM_IRSytemID				; ID RC5 du syst�me
		ld		Work,Z

RC5TestCommand:
		cpse 	SystemIR,Work					; Compare l'adresse re�ue et celle � laquelle on doit r�pondre
		rjmp	ExitRecRC5						; On s'en va si �a n'est pas le cas..

; -- On a bien re�u quelque chose, et c'est pour nous

 		sbrs	StatReg1,FlagPower				; Si la bestiole �tait �teinte, on ne s'occupe pas de l'Idle
		rjmp	RC5QuelleCommande

        sbrc	StatReg1,FlagIdle				; Si le timer d'Idle �tait en train de tourner,
		call	StopIdle						; alors on l'arr�te
		call	RestoreBrightness				; Sinon, on remet l'afficheur en pleine luminosit�

RC5QuelleCommande:

		bst		CommandeIR,6					; R�cup�re le bit de Toggle
		bld		IRSup,IRNewToggle				; et le stocke dans le bit 7 de IRSup
		andi	CommandeIR,0x3F					; Enl�ve le bit de toggle de la commande

; -- Mise en route/arr�t/Bypass pour triggers

		sbrc	StatReg1,FlagPower				; Si la b�te est allum�e, on est en mode normal
		rjmp	RC5ReadCommandOn				; et on va lire la commande en RAM

		ldi		ZH,RAM_Start
		ldi		ZL,RAM_IRStandbyOn				; Commande IR Mise en route/Veille
		ld		Work,Z+							; Incr�mentation de l'adresse RAM	
		
		cp		CommandeIR,Work					; On est �teint, et c'est une commande de mise en route
		breq	RC5OnlyStart					; Alors on y va...

#if defined(BYPASS)
		ldi		ZH,RAM_Start
		ldi		ZL,RAM_IRInputBypass			; Commande IR de bypass
		ld		Work,Z+							; Incr�mentation de l'adresse RAM	
		cpse	CommandeIR,Work
		ret										; non, aucune des des deux, alors cassos...

		sbr		StatReg2,EXP2(FlagIRBypass)		; vi, c'est bypass, alors on hisse le flag
		call	IRClearIRSup					; on vide le registre gestion du volume et on arr�te le timer
#endif
		ret										; et on s'en retourne sans r�tablir les interruptions

RC5OnlyStart:
		sbr		StatReg1,EXP2(FlagPower)		; On se met en marche, 
		call	IRClearIRSup					; On vide le registre gestion du volume et on arr�te le timer
		ret										; Et on se casse, mais sans r�tablir les interruptions

RC5ReadCommandOn:
		ldi		ZH,RAM_Start
		ldi		ZL,RAM_IRStandbyOn				; Commande IR Mise en route/Veille
		ld		Work,Z+							; Incr�mentation de l'adresse RAM	

		cpse	CommandeIR,Work					; C'est cette commande ?		
		rjmp	RecMute							; 	- Non -> On teste la suivante
												; 	- Oui -> On s'en occupe

; Si c'est cette commande, c'est seulement pour �teindre, vu que l'allumage est trait� � part (cf plus haut)
		cbr		StatReg1,EXP2(FlagPower)		; Bit de status d�sactiv�
		call	IRClearIRSup					; On vide le registre gestion du volume et on arr�te le timer
		rjmp	ExitRecRC5						; et on se barre

; -- Mute

RecMute:
#if defined(BYPASS)
		sbrc	StatReg2,FlagBypass				; Si on est en mode Bypass,
		rjmp	RecInTapeOrBypass				; on ne peut recevoir qu'une commande de bypass
#endif
		ld		Work,Z+
		cpse	CommandeIR,Work					; C'est cette commande ?		
		rjmp	RecVolP							; 	- Non -> On teste la suivante
												; 	- Oui -> On s'en occupe
		ldi		ZH,RAM_Start
		ldi		ZL,RAM_MuteLevel
		ld		Work,Z							; On charge la valeur du volume de mute

		sbrs	StatReg2,FlagIRMute				; On est d�j� en mute ?
		rjmp	RC5MuteOn						; 	- Non -> Alors, quetattends ?
												; 	- Oui, alors on r�active la sortie

		cpi		Work,MuteLevelOff				; Le mute est total ?
		brne	RC5MuteOffVolume				; non, alors on remet le volume comifo

		MacroMuteOff							; Passe le relais de mute � 1 (La sortie devient active)
		cbr		StatReg1,EXP2(FlagMute)			; Signale qu'on n'est plus en mute (bit � 0)
		rjmp	RC5MuteOff						; Et on termine

RC5MuteOffVolume:

		ldi		ZH,RAM_Start					; On r�cup�re la valeur du volume avant le mute
		ldi		ZL,RAM_TempVolume
		ld		VolReg,Z
		call	SetVolume						; et on remet le volume � cette valeur

RC5MuteOffWaitMBB:
		sbrc	StatReg2,FlagMBB				; On attend la fin de la phase de MBB
		rjmp	RC5MuteOffWaitMBB

RC5MuteOff:
		cbr		StatReg2,EXP2(FlagIRMute)		; efface le bit de mute du registre IR
		cbr		StatReg2,EXP2(FlagBlink)		; et celui de blink

		ldi		Work,0							; Arr�te le timer de clignotement
		out		TCCR1B,Work		

		call	AfficheEntree					; et r�tablit l'affichage normal
		call	AfficheVolume	

		call	IRClearIRSup					; On vide le registre gestion du volume et on arr�te le timer
		rjmp	ExitRecRC5						; et on se barre

RC5MuteOn:
		cpi		Work,MuteLevelOff				; On veut un mute total ?
		breq	RC5MuteOnTotal					; 	- Oui -> On y va...

		ldi		ZH,RAM_Start					;	- Non -> On m�morise le volume actuel
		ldi		ZL,RAM_TempVolume
		st		Z,VolReg

		mov		VolReg,Work						; On remplace le volume par sa valeur de mute
		call	SetVolume						; On fixe le volume � cette valeur

RC5MuteWaitMBB:
		sbrc	StatReg2,FlagMBB				; On attend la fin de phase de MBB
		rjmp	RC5MuteWaitMBB
		rjmp	RC5MuteAffiche					; Et on affiche qu'on est en mute

RC5MuteOnTotal:
		MacroMuteOn								; Passe le relais de mute � 0 (Mut� au repos)
		sbr		StatReg1,EXP2(FlagMute)			; Signale qu'on est en mute (bit � 1)

RC5MuteAffiche:
		sbr		StatReg2,EXP2(FlagIRMute)		; Positionne le bit de mute du registre IR
		sbr		StatReg2,EXP2(FlagBlink)		
		ldi		Work,0
		call	DisplayPlaceCurseur				; Met le curseur au d�but de l'afficheur
		call	AfficheMute						; On affiche le message correspondant

		call	IRClearIRSup					; On vide le registre gestion du volume et on arr�te le timer

		ldi		Work,DeuxSecHi
		out		TCNT1H,Work
		ldi		Work,DeuxSecLo
		out		TCNT1L,Work
		ldi		Work,TimerScroll				; et relance le timer en CK/1024
		out		TCCR1B,Work						; -> Prochaine interruption dans 2 secondes				

		rjmp	ExitRecRC5						; et on se barre

; -- Augmentation de Volume	

RecVolP:
		sbrc	StatReg2,FlagIRMute				; Si on est en mute depuis l'IR, on ne traite pas les autres commandes
		rjmp	ExitRecRC5

		ld		Work,Z+
		cpse	CommandeIR,Work					; C'est cette commande ?		
		rjmp	RecVolM							; 	- Non -> On teste la suivante
												; 	- Oui -> On s'en occupe
		sbr		StatReg1,EXP2(FlagIncremente)	; On feinte en faisant comme si c'�tait l'encodeur qui venait d'�tre activ�
		
		ldi		ZH,RAM_Start					; On regarde comment est-ce qu'on a configur� le speedup 
		ldi		ZL,RAM_SpeedUp					; L'adresse du param�tre de SpeedUp en RAM
		ld		Work,Z							; R�cup�re la valeur dans Work

		cpi		Work,0							; Si on a z�ro, pas la peine de faire tout le reste,
		breq	RecDoVolP						; vu qu'on ne veut pas d'acc�l�ration de volume

	    sbrs	IRSup,IRVolUp					; C'est un premier passage ici ?
		rjmp	RecFirstPassVolP				; 	-oui, alors on positionne les bits qu'il faut

		mov		Work,IRSup						; Copie le registre dans un registre imm�diat
		andi	Work,0b11000000					; Garde les deux premiers bits
	    cpi		Work,0b11000000					; Le toggle a chang� depuis le dernier passage ? 
		breq	RecToggleSameP					; 	-nan, c'est le m�me  
		cpi		Work,0							; Toggle chang� ?
		breq	RecToggleSameP					; 	-nan, c'est le m�me  

		rjmp	RecFirstPassVolP

RecToggleSameP:
		sbrc	IRSup,IRCountOn					; Le timer avant speedup tourne-t-il ?
		rjmp	RecToggleVolUp					; 	- oui, alors on pass au reste

		ldi		Work,EXP2(IRCountOn)			; 	- non, alors on positionne le bit qui signale le timer
		or		IRSup,Work						; 	  avec ce substitut de sbr

		ldi		Work,DeuxSecHi					; et on va lancer le timer
		out		TCNT1H,Work						; pour deux secondes
		ldi		Work,DeuxSecLo
		out		TCNT1L,Work
		ldi		Work,TimerScroll				; et relance le timer en CK/1024
		out		TCCR1B,Work						; -> Prochaine interruption dans 2 secondes	

		rjmp	RecToggleVolUp					; et on va swapper le toggle
							
RecFirstPassVolP:								; Pour le premier passage ici, 
		mov		Work,IRSup						; On positionne tous les bits du registre komifo
		sbr		Work,EXP2(IRVolUp)
		cbr		Work,EXP2(IRVolDown)
		cbr		Work,EXP2(IRCountOn)
		cbr		Work,EXP2(IRCountOver)
		cbr		Work,EXP2(IRCountOverMore)
		mov		IRSup,Work

RecToggleVolUp:
		bst		IRSup,IRNewToggle				; Transf�re le bit de toggle
		bld		IRSup,IROldToggle				; dans la "vieille" valeur

RecDoVolP:
		rcall	ChangeVolume					; On change le volume,
		rjmp	ExitRecRC5						; et bye

; -- Diminution de Volume

RecVolM:
		ld		Work,Z+
		cpse	CommandeIR,Work					; C'est cette commande ?		
		rjmp	RecBalG							; 	- Non -> On teste la suivante
												; 	- Oui -> On s'en occupe
		sbr		StatReg1,EXP2(FlagDecremente)	; On feinte en faisant comme si c'�tait l'encodeur qui venait d'�tre activ�

		ldi		ZH,RAM_Start					; On regarde comment est-ce qu'on a configur� le speedup 
		ldi		ZL,RAM_SpeedUp					; L'adresse du param�tre de SpeedUp en RAM
		ld		Work,Z							; R�cup�re la valeur dans Work

		cpi		Work,0							; Si on a z�ro, pas la peine de faire tout le reste,
		breq	RecDoVolM						; vu qu'on ne veut pas d'acc�l�ration de volume

	    sbrs	IRSup,IRVolDown					; C'est un premier passage ici ?
		rjmp	RecFirstPassVolM				; 	-oui, alors on positionne les bits qu'il faut

		mov		Work,IRSup						; Copie le registre dans un registre imm�diat
		andi	Work,0b11000000					; Garde les deux premiers bits
	    cpi		Work,0b11000000					; Le toggle a chang� depuis le dernier passage ? 
		breq	RecToggleSameM					; 	-nan, c'est le m�me  
		cpi		Work,0							; Toggle chang� ?
		breq	RecToggleSameM					; 	-nan, c'est le m�me  

		rjmp	RecFirstPassVolM

RecToggleSameM:
		sbrc	IRSup,IRCountOn					; Le timer avant speedup tourne-t-il ?
		rjmp	RecToggleVolDown				; 	- oui, alors on pass au reste

		ldi		Work,EXP2(IRCountOn)			; 	- non, alors on positionne le bit qui signale le timer
		or		IRSup,Work						; 	  avec ce substitut de sbr

		ldi		Work,DeuxSecHi					; et on va lancer le timer
		out		TCNT1H,Work						; pour deux secondes
		ldi		Work,DeuxSecLo
		out		TCNT1L,Work
		ldi		Work,TimerScroll				; et relance le timer en CK/1024
		out		TCCR1B,Work						; -> Prochaine interruption dans 2 secondes	

		rjmp	RecToggleVolDown				; et on va swapper le toggle
							
RecFirstPassVolM:								; Pour le premier passage ici, 
		mov		Work,IRSup						; On positionne tous les bits du registre komifo
		sbr		Work,EXP2(IRVolDown)
		cbr		Work,EXP2(IRVolUp)
		cbr		Work,EXP2(IRCountOn)
		cbr		Work,EXP2(IRCountOver)
		cbr		Work,EXP2(IRCountOverMore)
		mov		IRSup,Work

RecToggleVolDown:
		bst		IRSup,IRNewToggle				; Transf�re le bit de toggle
		bld		IRSup,IROldToggle				; dans la "vieille" valeur

RecDoVolM:
		rcall	ChangeVolume					; On change le volume,
		rjmp	ExitRecRC5						; et bye

; -- Balance vers la Gauche

RecBalG:
		ld		Work,Z+
		cpse	CommandeIR,Work					; C'est cette commande ?		
		rjmp	RecBalD							; 	- Non -> On teste la suivante
												; 	- Oui -> On s'en occupe
		sbr		StatReg1,EXP2(FlagDecremente)	; On feinte en faisant comme si c'�tait l'encodeur qui venait d'�tre activ�
		rcall	AjusteBalance
		call	IRClearIRSup					; On vide le registre gestion du volume et on arr�te le timer
		rjmp	ExitRecRC5

; -- Balance vers la Droite	

RecBalD:
		ld		Work,Z+
		cpse	CommandeIR,Work					; C'est cette commande ?		
		rjmp	RecIn1							; 	- Non -> On teste la suivante
												; 	- Oui -> On s'en occupe
		sbr		StatReg1,EXP2(FlagIncremente)	; On feinte en faisant comme si c'�tait l'encodeur qui venait d'�tre activ�
		rcall	AjusteBalance
		call	IRClearIRSup					; On vide le registre gestion du volume et on arr�te le timer
		rjmp	ExitRecRC5

; -- Entr�e 1

RecIn1:
		ld		Work,Z+
		cpse	CommandeIR,Work					; C'est cette commande ?		
		rjmp	RecIn2							; 	- Non -> On teste la suivante
												; 	- Oui -> On s'en occupe

		call	IRClearIRSup					; On vide le registre gestion du volume et on arr�te le timer (Merci Philby :) )
												; (Sinon pb de commutation incompl�te des entr�es � cause des flags de IRSup qui sont interrog�s
												; dans l'interruption qui commande les relais des entr�es)

		ldi		Work1,0							; Le num�ro de l'entr�e � activer dans Work1
		rcall	ChangeEntreeAfterSwitches		; On change l'entr�e
		rcall	AfficheEntree					; On affiche son nom
		rjmp	ExitRecRC5						; et on se casse

; -- Entr�e 2

RecIn2:
		ld		Work,Z+
		cpse	CommandeIR,Work					; C'est cette commande ?		
		rjmp	RecIn3							; 	- Non -> On teste la suivante
												; 	- Oui -> On s'en occupe

		call	IRClearIRSup					; On vide le registre gestion du volume et on arr�te le timer (Merci Philby :) )

		ldi		Work1,1							; Le num�ro de l'entr�e � activer dans Work1
		rcall	ChangeEntreeAfterSwitches		; On change l'entr�e
		rcall	AfficheEntree					; On affiche son nom
		rjmp	ExitRecRC5						; et on se casse

; -- Entr�e 3

RecIn3:
		ld		Work,Z+
		cpse	CommandeIR,Work					; C'est cette commande ?		
		rjmp	RecIn4							; 	- Non -> On teste la suivante
												; 	- Oui -> On s'en occupe

		call	IRClearIRSup					; On vide le registre gestion du volume et on arr�te le timer (Merci Philby :) )

		ldi		Work1,2							; Le num�ro de l'entr�e � activer dans Work1
		rcall	ChangeEntreeAfterSwitches		; On change l'entr�e
		rcall	AfficheEntree					; On affiche son nom
		call	IRClearIRSup					; On vide le registre gestion du volume et on arr�te le timer
		rjmp	ExitRecRC5						; et on se casse

; -- Entr�e 4

RecIn4:
		ld		Work,Z+
		cpse	CommandeIR,Work					; C'est cette commande ?		
		rjmp	RecInTapeOrBypass				; 	- Non -> On teste la suivante
												; 	- Oui -> On s'en occupe

		call	IRClearIRSup					; On vide le registre gestion du volume et on arr�te le timer (Merci Philby :) )

		ldi		Work1,3							; Le num�ro de l'entr�e � activer dans Work1
		rcall	ChangeEntreeAfterSwitches		; On change l'entr�e
		rcall	AfficheEntree					; On affiche son nom
		rjmp	ExitRecRC5						; et on se casse

; -- Entr�e Tape/Bypass

RecInTapeOrBypass:
		ldi		ZH,RAM_Start
#if defined(BYPASS)
		ldi		ZL,RAM_IRInputBypass			; Commande IR de Bypass
#else
		ldi		ZL,RAM_IRInputTape				; Commande IR de Tape
#endif
		ld		Work,Z+							; Incr�mentation de l'adresse RAM	

		cpse	CommandeIR,Work					; C'est cette commande ?		
		rjmp	RecBrightP						; 	- Non -> On teste la suivante
												; 	- Oui -> On s'en occupe

		call	IRClearIRSup					; On vide le registre gestion du volume et on arr�te le timer (Merci Philby :) )

#if defined(BYPASS)
		rcall	BypassAfterSwitches				; On commute le bypass
#else
		ldi		Work1,4							; Le num�ro de l'entr�e � activer dans Work1
		rcall	ChangeEntreeAfterSwitches		; On change l'entr�e
		rcall	AfficheEntree					; On affiche son nom
#endif
		rjmp	ExitRecRC5						; et on se casse

; -- Augmentation de la luminosit� de l'afficheur

RecBrightP:

#if defined(BYPASS)
		sbrc	StatReg2,FlagBypass				; On ne va pas plus loin
		rjmp	ExitRecRC5						; si on est en bypass
#endif
		ld		Work,Z+
		cpse	CommandeIR,Work					; C'est cette commande ?		
		rjmp	RecBrightM						; 	- Non -> On teste la suivante
												; 	- Oui -> On s'en occupe
		call	IncreaseBrightness				; 	  en augmentant la luminosit�
		call	IRClearIRSup					; On vide le registre gestion du volume et on arr�te le timer
		rjmp	ExitRecRC5						; et on se casse
						
; -- Diminution de la luminosit� de l'afficheur

RecBrightM:
		ld		Work,Z+
		cpse	CommandeIR,Work					; C'est cette commande ?		
		rjmp	RecContrastP					; 	- Non -> On teste la suivante
												; 	- Oui -> On s'en occupe
		call	DecreaseBrightness				; 	  en diminuant la luminosit�
		call	IRClearIRSup					; On vide le registre gestion du volume et on arr�te le timer
		rjmp	ExitRecRC5						; et on se casse

; -- Augmentation du contraste de l'afficheur

RecContrastP:
		ld		Work,Z+
		cpse	CommandeIR,Work					; C'est cette commande ?		
		rjmp	RecContrastM					; 	- Non -> On teste la suivante
												; 	- Oui -> On s'en occupe
#if defined (LCD)
		call	DecreaseContrast				; 	  en augmentant le contraste (diminution de la valeur)
		call	IRClearIRSup					; On vide le registre gestion du volume et on arr�te le timer
#endif
		rjmp	ExitRecRC5						; et on se casse

; -- Diminution du contraste de l'afficheur

RecContrastM:
		ld		Work,Z+
		cpse	CommandeIR,Work					; C'est cette commande ?		
		rjmp	ExitRecRC5						; 	- Non -> On s'en va
												; 	- Oui -> On s'en occupe
#if defined(LCD)
		call	IncreaseContrast				; 	  en augmentant le contraste (diminution de la valeur)
		call	IRClearIRSup					; On vide le registre gestion du volume et on arr�te le timer
#endif
		rjmp	ExitRecRC5						; et on se casse

ExitRecRC5:

        ldi     Work,0b00000011                 ; On r�autorise seulement les 2 interruptions externes INT 1 et INT 0
        out     EIMSK,Work                      ; (Enable Interrupt Mask)

		call	StartIdle						; on relance le timer de "fout rien"
		ret

; ================================================
; === Routine de r�ception des commandes RC5   ===
; === L'adresse syst�me est dans SystemIR      ===
; === et la commande elle-m�me dans CommandeIR ===
; ===                                          ===
; === En cas de mauvaise r�ception, ces deux   ===
; === registres contiennent 0xFF               ===
; ================================================

IRDetect:
		clr		IntTemp						; R�initialise les registres de timing
		clr		TimerIR_H

IRDetect1:
		clr		TimerIR_L

IRDetect2:
		cpi		TimerIR_H,8					; Teste si le signal ne reste pas inactif pendant 131ms (8 x 256 x 256 / 4e6)
		brlo	IRDelay1					; Si c'est le cas, on passe � la suite
		rjmp	IRFault						; Sinon on s'en va

IRDelay1:
		cpi		TimerIR_L,55				; Si le signal est � l'�tat bas pendant au moins 3.5ms	(55x256/4e6)
		brge	IRStart1					; Alors on va attendre le Start Bit

		sbis	PinsRC5,InRC5				; Si le signal est :
		rjmp	IRDetect1					;   bas  - Saute � IRDetect1
		rjmp	IRDetect2					;   haut - Saute � IRDetect2


IRStart1:		
		cpi		TimerIR_H,8					; Si le Start Bit n'a pas �t� d�tect�
		brge	IRFault						; durant les 130ms, alors bye

		sbic	PinsRC5,InRC5				; Attendons le Start Bit
		rjmp	IRStart1

		clr		TimerIR_L					; Mesure la dur�e du Start Bit
		
IRStart2:
		cpi		TimerIR_L,20				; Si le Start Bit dure plus de 1.1ms (17 x 256 / 4e6)
		brge	IRFault						; on se casse

		sbis	PinsRC5,InRC5				; Si le signal passe � 1 -> Flanc positif sur le premier Start Bit -> On passe � la suite
		rjmp	IRStart2					; sinon on continue d'attendre


		mov		Work3,TimerIR_L				; Le timer contient la dur�e correspondante � 1/2 bit
		clr		TimerIR_L					; et on sauvegarde �a dans un registre temporaire

		mov		Ref1,Work3
		lsr		Ref1
		mov		Ref2,Ref1
		add		Ref1,Work3					; Ref1 contient maintenant la dur�e de 3/4 bit
		lsl		Work3
		add		Ref2,Work3					; et Ref2 la dur�e de 5/4 bit

IRStart3:
		cp		TimerIR_L,Ref1				; Si le signal (Second Start bit)  reste haut pendant plus de 3/4 bit
		brge	IRFault						; on se casse

		sbic	PinsRC5,InRC5				; Sinon, on attend le front descendant du Start Bit 2
		rjmp	IRStart3

		clr		TimerIR_L

		ldi		Work2,12					; On a 12 bits � recevoir
		clr		CommandeIR					; Et on efface les registres de sortie
		clr		SystemIR

IRSample:
		cp		TimerIR_L,Ref1				; On �chantillonne le signal IR � 1/4 bit
		brlo	IRSample

		sbic	PinsRC5,InRC5
		rjmp	IRBit_Is_A_1				; Saute si le signal vaut 1


IRBit_Is_A_0:	

		clc									; Stocke un '0'
		rol		CommandeIR
		rol		SystemIR

											; Synchronise les timings
IRBit_Is_A_0a:	
		cp		TimerIR_L,Ref2				; Si on n'a pas eu de changement d'�tat pendant la dur�e de 3/4 bit
		brge	IRFault						; pas la peine de poursuivre
		sbis	PinsRC5,InRC5				; Sinon, on attend un flanc montant
		rjmp	IRBit_Is_A_0a				; au milieu du bit

		clr		TimerIR_L
		rjmp	IRNextBit

IRBit_Is_A_1:
		sec									; Stocke un '1'
		rol		CommandeIR
		rol		SystemIR
											; Synchronise les timings
IRBit_Is_A_1a:	
		cp		TimerIR_L,Ref2				; Si on n'a pas eu de changement d'�tat pendant la dur�e de 3/4 bit
		brge	IRFault						; on se casse
		sbic	PinsRC5,InRC5				; Sinon, on attend un flanc descendant
		rjmp	IRBit_Is_A_1a				; au milieu du bit

		clr		TimerIR_L

IRNextBit:
		dec		Work2						; Tant qu'on n'a pas re�u les 12 bits
		brne	IRSample					; on continue de recevoir


; On a bien re�u tous les bits 

		mov		Work3,CommandeIR			; On place les bits d'adresse dans "SystemIR"
		rol		Work3
		rol		SystemIR
		rol		Work3
		rol		SystemIR

		bst		SystemIR,5					; Positionne le bit de Toggle
		bld		CommandeIR,6				; dans le registre "CommandeIR"

; Efface les bits restant

		andi	CommandeIR,0b01111111
		andi	SystemIR,0x1F

		ret									; et oualou...

IRFault:		
		ser		CommandeIR					; Les deux registres contiennet 0xFF
		ser		SystemIR					; pour indiquer une mauvaise r�ception
		ret									; et zou...

; =================================================================
; == Arr�t du timer de speedup volume et mise � z�ro du registre ==
; =================================================================

IRClearIRSup:
	    sbrs	IRSup,IRCountOn				; Le timer est en train de tourner ?
		rjmp	IRDoClear					; 	- nan, alors on saute l'arr�t forc�

		ldi		Work,TimerStop				; 	- Oui, alors on arr�te le Timer
		out		TCCR1B,Work

IRDoClear: 
		clr		IRSup						; efface tout le registre
		ret									; and bye
