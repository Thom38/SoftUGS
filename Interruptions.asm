; =======================================================
; == Routine d'interrupt 0 pour le switch de Stanby/On ==
; =======================================================

Power:	
		push	Work								; Sauvegarde les registres dans la pile
		in		Work,SREG
		push	Work

		sbrs	StatReg2,FlagWait					; Si le flag d'attente n'est pas positionn�
		rjmp	PowNormal							; c'est un mode normal
													; Sinon on est en mode d'attente au d�marrage,
		clr		Work								; Dans ce cas, le timer 3 est en train de tourner,			
		sts		TCCR3B,Work							; alors on l'arr�te
		cbr		StatReg2,EXP2(FlagWait)				; Et on efface le flag d'attente qui signale le second appui sur le bouton
		ldi		ZH,RAM_Start
		ldi		ZL,RAM_Tempo						; On signale le second appui
		ldi		Work,255							; par une valeur non nulle en RAM
		st		Z,Work

PowT:	sbic    PinSwitchOn,SwitchOn				; Reteste le bouton de power on
		rjmp	ExitPower							; Relach� ? -> on se casse
		rjmp    PowT								; Boucle

; -- Fonctionnement normal (hors attente)
PowNormal:
		sbic    PinSwitchOn,SwitchOn				; Reteste le bouton de power on
		rjmp    Pow2								; Relach� ? -> On passe � la suite
#if defined (BYPASS)
PowBy:	sbic	PinsSwitches,SwitchTapeOrBypass		; On a appuy� en m�me temps sur le bouton Bypass (actif � 0) ?
		rjmp	PowNormal							; Relach� ? -> On reteste le bouton de power on
		sbrc	StatReg1,FlagPower					; si le biniou est allum�, on ne tient pas compte d'un appui �ventuel sur le bypass		
		rjmp	PowNormal

		sbr		StatReg2,EXP2(FlagIRBypass)			; les deux boutons sont appuy�s, le biniou est �t�int, alors on hisse le drapeau de bypass/triggers
PowWaitSB:
		sbic 	PinsSwitches,SwitchTapeOrBypass		; Reteste le bouton de bypass
		rjmp	ExitPower							; Relach� ? -> on se casse
		rjmp    PowWaitSB							; Sinon on boucle
#endif
		rjmp	PowNormal

Pow2:
		sbrs	StatReg1,FlagPower              	; Etait-on arr�t� ?
        rjmp    PowerOn                        		; Non --> On d�marre
        
; -- Arr�t du biniou
		cbr     StatReg1,EXP2(FlagPower)			; Si on �tait en marche
		rjmp    ExitPower							; On passe le flag � 0 pour dire qu'on arr�te, et on sort pour passer � la phase d'arr�t

; Mise en route de la machine

PowerOn:
		sbr     StatReg1,EXP2(FlagPower)        	; On garde en m�moire qu'on a allum� le biniou
	
ExitPower:				        					; Sortie de l'interruption
		clr     Work			        			; On va inhiber les interruptions INT0 et INT1 pour
		out     EIMSK,Work							; �viter de les red�clencher au retour de l'interruption

		pop		Work								; On r�cup�re le registre �ventuellement modifi�
		out		SREG,Work							; R�cup�re le Status Register
		pop		Work								; 

		reti				        				; et bye-bye

; ========================================================
; == Routine d'interrupt 1 pour le r�cepteur InfraRouge ==
; ========================================================

IRRecInt:

		push	Work								; Sauvegarde les registres dans la pile
		in		Work,SREG
		push	Work

		sbr		StatReg2,EXP2(FlagIRRec)			; Passe le Flag de r�ception IR � 1
	
		clr     Work			        			; On va inhiber les interruptions externes pour
		out     EIMSK,Work							; �viter de les red�clencher au retour de l'interruption

		pop		Work								; On r�cup�re le registre �ventuellement modifi�
		out		SREG,Work							; R�cup�re le Status Register
		pop		Work								; 

		reti										; Et fin d'interruption

; ==========================================================
; == Routine Interrupt Overflow sur le timer 0 (8 bits)   ==
; == Utilis� pour le d�lai de MBB sur le relais de volume ==
; ==========================================================

DelayRelayMBB:

		push	Work								; Sauvegarde les registres de travail dans la pile
		push	Work1								; Ca permet de ne pas perdre leur valeur si jamais on �tait en train de les utiliser
		push	Work2
		push	Count1
		in		Work,SREG							; Sauvegarde le Status Register
		push	Work

		ldi		Work,TimerStop						; On arr�te le Timer 0 pour �viter de repartir sur une interruption
		out		TCCR0,Work

		mov		Work,VolRegG						; Copie le volume de gauche dans un registre temporaire
		ldi		Work1,0b10000000					; Ce qui sera transf�r� sur le port des relais de volume
		ldi		Work2,0b00000001					; Le registre qui va servir � savoir quel bit activer
ShiftVolG:
		sbrs	Work,0								; Le premier bit est � 1 ?
		rjmp	DoShiftVolG							; Nan, c'est un z�ro, on se contente de d�caler le registre Work
		
		or		Work1,Work2							; On met un "1" � la bonne place dans le registre de sortie
		out		PortVolume,Work1					; On met le r�sultat sur le port de volume
		sbi		PortLatchVolG,LE_VolG				; Une impulsion pour le latch
		cbi		PortLatchVolG,LE_VolG

		mov		Count1,SeqMBB						; R�cup�re la valeur du d�lai de r�activation
W1MBB:	dec		Count1								; |
		nop											; | Cette boucle dure 1 �s � 4Mhz
		nop											; |
		brne	W1MBB								; |

DoShiftVolG:
		lsr		Work								; On met le bit suivant en position z�ro -> D�calage vers la droite
		lsl		Work2								; La position du prochain bit � activer	 -> D�calage vers la gauche
		sbrs	Work2,7								; Est-on arriv� au dernier bit (le bit 7 de Work2 passe-t-il � 1 ) ? 
		rjmp	ShiftVolG							; 	- Nan, alors on boucle
												 	; 	- Oui, alors on passe au volume de droite en faisant la m�me chose

		mov		Work,VolRegD						; Copie le volume de droite dans un registre temporaire
		ldi		Work1,0b10000000					; Ce qui sera transf�r� sur le port des relais de volume
		ldi		Work2,0b00000001					; Le registre qui va servir � savoir quel bit activer
ShiftVolD:
		sbrs	Work,0								; Le premier bit est � 1 ?
		rjmp	DoShiftVolD							; Nan, c'est un z�ro, on se contente de d�caler le registre Work
		
		or		Work1,Work2							; On met un "1" � la bonne place dans le registre de sortie
		out		PortVolume,Work1					; On met le r�sultat sur le port de volume
		sbi		PortLatchVolD,LE_VolD				; Une impulsion pour le latch
		cbi		PortLatchVolD,LE_VolD

		mov		Count1,SeqMBB						; R�cup�re la valeur du d�lai de r�activation
W2MBB:	dec		Count1								; |
		nop											; | Cette boucle dure 1 �s � 4Mhz
		nop											; |
		brne	W2MBB								; |

DoShiftVolD:
		lsr		Work								; On met le bit suivant en position z�ro -> D�calage vers la droite
		lsl		Work2								; La position du prochain bit � activer	 -> D�calage vers la gauche
		sbrs	Work2,7								; Est-on arriv� au dernier bit (le bit 7 de Work2 passe-t-il � 1 ) ? 
		rjmp	ShiftVolD							; 	- Nan, alors on boucle
													; 	- Oui -> Alors on se casse...
		cbr		StatReg2,EXP2(FlagMBB)				; Efface le bit de MBB du registre de status

		sbrc	StatReg1,FlagMenu					; Si on est en mode menu,
		rjmp	ExitDelayRelayMBB					; on n'affiche rien et on sort

		sbrs	StatReg1,FlagBalance				; Si on n'est pas en modification de balance
		call 	AfficheVolume						; on r�affiche le volume

ExitDelayRelayMBB:
		pop		Work								; On r�cup�re les contenu des registre de travail 
		out		SREG,Work							; et le status register
		pop		Count1
		pop		Work2
		pop		Work1
		pop		Work

		reti										; et c'est fini

; ==========================================================
; == Routine Interrupt Overflow sur le timer 1 (16 bits)  ==
; == Utilis� pour :                                       ==
; ==      - Le timing des relais d'entr�e/mute            ==
; ==      - Une attente en mode menu		              ==
; ==	  - Le d�lai avant speedup de la telco volume     ==
; ==      - Le clignotement de l'afficheur mode en mute   ==
; ==========================================================

RelayTimer:
		push	Work								; Sauvegarde dans la pile des registres utilis�s dans la routine d'interruption
		push	Work1
		push	Char
		in		Work,SREG
		push 	Work

		ldi		Work,TimerStop						; On arr�te le Timer
		out		TCCR1B,Work

		sbrc	StatReg2,FlagIRMute					; Si on est en Mute via le RC5
		rjmp	MuteInterrupt						; on s'en occupe

		sbrc	StatReg1,FlagMenu					; Si on est en mode menu
		rjmp	WaitForMenu							; c'est juste un flag � changer

		sbrc	IRSup,IRCountOn						; Si on est en timer de Speedup,
		rjmp	IRSpeedUp							; On s'en occupe

; Sinon fonctionnement normal pour les relais d'I/O

		sbrc	StatReg2,FlagWait					; Si ce flag est � 1,
		rjmp	RelanceRelayTimer					; on est au premier passage
													; sinon, on active la sortie du pr�amp :
#if defined(BYPASS)
		sbrs	StatReg2,FlagBypass					; Si on n'est pas en train de passer en Bypass,
		rjmp	DemuteNormal						; c'est le fonctionnement normal,
													; sinon on va relacher le relais de bypass (c'est bypass� au repos)
		lds		Work,PortAutresRelais				; R�cup�re l'�tat des autres relais
		cbr		Work,EXP2(RelaisBypass)				; Et met le relais de bypass au repos
		sts		PortAutresRelais,Work				; On envoie �a sur le port concern�
		rjmp	ExitRelayTimer						; et on se casse
#endif

DemuteNormal:
		MacroMuteOff
		cbr		StatReg1,EXP2(FlagMute)				; Signale qu'on n'est plus en mute (bit � 0)

		call	SetVolumeNoMin						; Et on remet le volume � sa valeur en activant le MBB
				
		rjmp	ExitRelayTimer						; et on s'en va


; On est au premier passage, alors on active le relais de l'entr�e s�lectionn�e
; et on relance le timer pour une demi-seconde supll�mentaire

RelanceRelayTimer:

		cbr		StatReg2,EXP2(FlagWait)				; Met � z�ro le flag d'attente

		call	ActiveRelaisEntree					; et va activer le relais de l'entr�e s�lectionn�e

		ldi		Work,UneDemiSecHi					; On charge dedans
		out		TCNT1H,Work							; une deuxi�me demi-seconde
		ldi		Work,UneDemiSecLo					; pour avoir le d�lai entre l'activation 
		out 	TCNT1L,Work							; du relais de masse et le relais de signal
		ldi		Work,TimerDiv						; Lance le Timer 1 en Ck/1024
		out 	TCCR1B,Work	
		rjmp	ExitRelayTimer						; et on s'en va

; --------------------------------------------------------------
; -- 2nd Use : Clignotement de l'afficheur en mode mute       --
; --------------------------------------------------------------

MuteInterrupt:

		sbrs	StatReg2,FlagBlink					; Bit de blink � 1 ?
		rjmp	MuteIAffiche						; non -> On va afficher le message

		call	DisplayClear						; Sinon, on efface l'afficheur
		cbr		StatReg2,EXP2(FlagBlink)			; Passe le flag de blink � 0

		ldi		Work,UneSecHi						; On relance le Timer 1
		out		TCNT1H,Work							; avec la bonne p�riode
		ldi		Work,UneSecLo
		out		TCNT1L,Work
		ldi		Work,TimerScroll
		out		TCCR1B,Work				
		rjmp	ExitRelayTimer						; et on se barre

MuteIAffiche:
		ldi		Work,0
		call	DisplayPlaceCurseur
		call	AfficheMute							; On affiche le message de mute
		sbr		StatReg2,EXP2(FlagBlink)			; Passe le flag de blink � 1

		ldi		Work,DeuxSecHi						; On relance le Timer 1
		out		TCNT1H,Work							; avec la bonne p�riode
		ldi		Work,DeuxSecLo
		out		TCNT1L,Work
		ldi		Work,TimerScroll
		out		TCCR1B,Work				
		rjmp	ExitRelayTimer						; et on se barre

; -------------------------------------------------
; -- 3rd use : D�lai avant speedup sur le volume --
; -------------------------------------------------

IRSpeedUp:

		sbrc	IRSup,IRCountOver					; Le premier timeout est pass� ?					; 
		rjmp	IRSpeedUpUp							; Oui, on est sur le second timeout

		mov 	Work,IRSup
		sbr		Work,EXP2(IRCountOver)				; on positionne le flag pour le premier TimeOut
		mov		IRSup,Work

		ldi		ZH,RAM_Start						; On regarde si il faut relancer le speedup pour un seconde acc�l�ration 
		ldi		ZL,RAM_SpeedUp						; L'adresse du param�tre de SpeedUp en RAM
		ld		Work,Z								; R�cup�re la valeur dans Work

		cpi		Work,2								; Il faut relancer le timer pour un second Timeout ? (valeur = 1 -> Un seul speedup)
		brne	ExitRelayTimer						; Non, on a fini -> Cassos

		ldi		Work,DeuxSecHi						; On relance le Timer 1
		out		TCNT1H,Work							; sur deux secondes
		ldi		Work,DeuxSecLo
		out		TCNT1L,Work
		ldi		Work,TimerScroll
		out		TCCR1B,Work				

		rjmp	ExitRelayTimer						; et on se barre

IRSpeedUpUp :										; Pour signaler qu'on va encore acc�l�rer
		mov		Work,IRSup
		cbr		Work,EXP2(IRCountOn)
		sbr		Work,EXP2(IRCountOverMore)
		mov		IRSup,Work

		rjmp	ExitRelayTimer						; et on se barre

; -------------------------------------------
; -- 4th use : Flag d'attente en mode menu --
; -------------------------------------------

WaitForMenu:										; Juste un flag � changer pour l'attente en mode menu
		cbr		StatReg2,EXP2(FlagWait)				; et c'est tout...
		
ExitRelayTimer:
		pop		Work
		out		SREG,Work
		pop		Char								; R�cup�re les registres sauvegard�s dans la pile
		pop		Work1
		pop		Work

		reti										; et c'est fini

; ========================================================
; == Routine Interrupt Overflow sur le timer 2 (8 bits) ==
; == Utilis� pour les timings du RC5                    ==
; == L'interruption d'overflow incr�mente "TimerIR_L"   ==
; == et "TimerIR_H" toutes les 64�s et 16.384ms         ==
; == Timings pour un Quartz � 4 MHz                     ==
; ========================================================

IRTimer:
		push	Work
		in		Work,SREG							; Sauvegarde le Status Register
		push	Work

		inc		TimerIR_L							; Incr�ment� toutes les 64�s (256/4e6=64�s)
		inc		IntTemp								; jusqu'� ce que �a repasse � 0 
		brne	ExitIRTimer
		inc		TimerIR_H							; toutes les 16.384ms

ExitIRTimer:
		pop		Work
		out		SREG,Work							; R�cup�re le Status Register
		pop		Work

		reti

; =================================================================
; == Routine Interrupt Overflow sur le timer 3 (16 bits) 	     ==
; ==                                                             ==
; == Plusieurs utilisations pour ce timer :                      ==
; ==   - En mode menu pour le clignotement de la LED On          ==
; ==   - Affichage de la valeur de la balance pendant 5 s        ==
; ==   - Pour les deux secondes d'attente au d�marrage           ==
; ==   - Pour le mode Idle										 ==
; =================================================================

MultiDelay:

		push	Work								; Sauvegarde le contenu de Work
		push	Work1								; et celui de Work1
		in		Work,SREG
		push	Work

		clr		Work
		sts		TCCR3B,Work							; Arr�te le timer

		sbrc	StatReg1,FlagMenu					; Si on est en mode menu
		rjmp	ClignoteLed							; On fait clignoter la led...

		sbrc	StatReg1,FlagBalance				; Si on est en mode balance
		rjmp	FinAfficheBalance

		sbrc	StatReg1,FlagIdle					; Si on se pr�pare au mode Idle...
		rjmp	IdleTiming

; --------------------------------------------------------
; -- 1st Use : Les deux secondes d'attente au d�marrage --
; --------------------------------------------------------

		cbr		StatReg2,EXP2(FlagWait)				; efface le flag d'attente
		rjmp	ExitMultiDelay

; --------------------------------------
; -- 2nd Use : L'attente en mode Idle --
; --------------------------------------

IdleTiming:

		dec		IdleCounter							; Le compteur d'Idle est-il arriv� � z�ro ?
		brne	RelanceIdleTimer					; non, on le relance

		clr		Work
		sts		TCCR3B,Work							; Arr�te le timer
		cbr		StatReg1,EXP2(FlagIdle)				; On efface le Flag

; Les deux lignes suivantes inhibent les interruptions par overflow sur le timer 3
; pour �viter le bug inexpliqu� de l'afficheur qui se r�veille tout seul...
; Cette interruption est r�activ�e dans la routine RestoreBrightness (AD8402.asm)

		clr 	Work
		sts		ETIMSK,Work							; Interdit les interruptions par overflow sur le timer 3

		call    SetIdleBrightness					; On met l'afficheur en luminosit� r�duite

		ldi		ZH,RAM_Start						; Octet de poids fort de l'adresse de d�but en RAM 
		ldi		ZL,RAM_IdleLed						; L'adresse de ce param�tre en RAM
		ld		Work,Z								; R�cup�re la valeur stock�e en RAM dans MenuReg1

		cpi		Work,0								; Faut �galement �teindre la Led ?
		brne	IdleLedOff							;   - vi, alors on y va
		rjmp	ExitMultiDelay						;   - nan, et c'est tout

IdleLedOff:
		cbi		PortLedOn,LedOn						; Extinction des feux
		rjmp	ExitMultiDelay						; et cassos


RelanceIdleTimer:
        ldi     Work,QuinzeSecHi					; Quinze secondes de timeout pour le timer3
        sts     TCNT3H,Work							
		ldi		Work,QuinzeSecLo
        sts     TCNT3L,Work
        ldi     Work,TimerDiv		        		; On d�marre le Timer avec CK/1024
        sts     TCCR3B,Work                     	; et il va compter pendant � peu pr�s 15 secondes avant l'overflow

		rjmp	ExitMultiDelay

; ---------------------------------------------
; -- 3rd Use : Fin d'affichage de la balance --
; ---------------------------------------------

FinAfficheBalance:					

		cbr		StatReg1,EXP2(FlagBalance)			; Remet le flag de balance en inactif
		call	AfficheEntree						; et remet l'affichage
		call 	AfficheVolume						; dans l'�tat initial
		call 	StartIdle							; Et on relance l'idleTimer
		rjmp	ExitMultiDelay						; et yo

; --------------------------------------------------------------
; -- 4th Use : Clignotement de la LED On/StandBy en mode menu --
; --------------------------------------------------------------

ClignoteLed:

		in		Work,PortLedOn						; r�cup�re l'�tat du port
		ldi		Work1,EXP2(LedOn)
		eor		Work,Work1							; inverse le bit de LedOn
		out		PortLedOn,Work						

		ldi		Work,UneSecHi
		sts		TCNT3H,Work
		ldi		Work,UneSecLo
		sts		TCNT3L,Work
		ldi		Work,TimerLed						; et relance le timer en CK/64, si bien qu'il va compter 16 fois plus vite que pour CK/1024
		sts		TCCR3B,Work							; -> Prochaine interruption dans 1/16 de seconde (contre les 1 s � CK/1024)				
		rjmp	ExitMultiDelay						; et yo


ExitMultiDelay:
		pop		Work
		out		SREG,Work							; R�cup�re le Status Register
		pop		Work1								; Restaure Work1
		pop		Work								; Restaure Work

		reti

