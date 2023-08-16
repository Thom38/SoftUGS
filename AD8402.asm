; =================================================
; === Protocoles de communication avce l'AD8402 ===
; =================================================

; --------------------------------------------------------------------
; --- Ajuste le potar de contraste                                 ---
; --- C'est le potar RDAC1, et la valeur est dans le registre Work ---
; --------------------------------------------------------------------

SetContrast:

		cbi		PortAD8402,CLK_AD8402					; L'horloge d�marre � 0
		nop

		cbi		PortAD8402,CS_AD8402					; Passe /CS � 0 pour dire � l'AD8402 de se mettre � l'�coute
		nop												; Laisse au chip le temps de dig�rer l'info

		cbi		PortAD8402,SDI_AD8402					; Le premier bit � passer (A1), c'est toujours 0
		nop												; On attend un cht'i peu

		sbi  	PortAD8402,CLK_AD8402					; Front montant d'horloge
		nop
		cbi		PortAD8402,CLK_AD8402					; Et l'horloge redescend

		sbi		PortAD8402,SDI_AD8402					; Bit A0 d'adresse
		nop												; C'est le RDAC1, donc adresse 1

		sbi  	PortAD8402,CLK_AD8402					; Front montant d'horloge
		nop
		cbi		PortAD8402,CLK_AD8402					; Et l'horloge redescend

; Et on envoie maintenant la valeur du potar

		push	Work									; On sauvegarde Work pour s'en servir apr�s
		ldi		Work2,8	 								; il faut envoyer 8 bits en s�rie, MSB first

BoucleContrast:

		sbi		PortAD8402,SDI_AD8402					; Par d�faut, on va transf�rer un "un"
		sbrs	Work,7									; Le 7�me bit de Work est � un ?
		cbi		PortAD8402,SDI_AD8402					; non -> On met le bit � transf�rer � 0
				 
		nop
		sbi  	PortAD8402,CLK_AD8402					; Front montant d'horloge
		cbi		PortAD8402,CLK_AD8402					; Et l'horloge redescend

		lsl		Work									; On d�cale le registre d'un bit vers la gauche
														; pour mettre le bit suivant en 7eme position
														
		dec 	Work2									; D�compte les bits qui ont �t� envoy�s
		cpi		Work2,0									; C'est le dernier ?
		brne	BoucleContrast							; Nan, alors on continue...

														; Sinon c'est fini
		sbi		PortAD8402,CS_AD8402					; Alors on repasse /CS � 1 pour remettre l'AD8402 hors circuit,

		pop 	Work									; On r�cup�re le registre Work
		ret												; et on se barre

; --------------------------------------------------------------------
; --- Ajuste le potar de Backlight                                 ---
; --- C'est le potar RDAC0, et la valeur est dans le registre Work ---
; --------------------------------------------------------------------

SetBrightness:

		cbi		PortAD8402,CLK_AD8402					; L'horloge d�marre � 0
		nop

		cbi		PortAD8402,CS_AD8402					; Passe /CS � 0 pour dire � l'AD8402 de se mettre � l'�coute
		nop												; Laisse au chip le temps de dig�rer l'info

		cbi		PortAD8402,SDI_AD8402					; Le premier bit � passer (A1), c'est toujours 0
		nop	
														; On attend un cht'i peu
		sbi  	PortAD8402,CLK_AD8402					; Front montant d'horloge
		nop
		cbi		PortAD8402,CLK_AD8402					; Et l'horloge redescend

		cbi		PortAD8402,SDI_AD8402					; Bit A0 d'adresse
		nop												; C'est le RDAC0, donc adresse 0
		
		sbi  	PortAD8402,CLK_AD8402					; Front montant d'horloge
		nop
		cbi		PortAD8402,CLK_AD8402					; Et l'horloge redescend

; Et on envoie maintenant la valeur du potar

		push	Work									; Sauvegarde le registre Work (on en a besoin au retour de la routine)

		ldi		Count1,8								; il faut envoyer 8 bits en s�rie, MSB first

BoucleBackLight:

		sbi		PortAD8402,SDI_AD8402					; Par d�faut, on va transf�rer un "un"
		sbrs	Work,7									; Le 7�me bit de Work est � un ?
		cbi		PortAD8402,SDI_AD8402					; non -> On met le bit � transf�rer � 0
				 
		nop
		sbi  	PortAD8402,CLK_AD8402					; Front montant d'horloge
		cbi		PortAD8402,CLK_AD8402					; Et l'horloge redescend

		lsl		Work									; On d�cale le registre d'un bit vers la gauche
														; pour mettre le bit suivant en 7eme position
														
		dec 	Count1									; D�compte les bits qui ont �t� envoy�s
		cpi		Count1,0								; C'est le dernier ?
		brne	BoucleBackLight							; Nan, alors on continue...

														; Sinon c'est fini
		sbi		PortAD8402,CS_AD8402					; Alors on repasse /CS � 1 pour remettre l'AD8402 hors circuit,

		pop		Work									; Restaure le registre Work

		ret												; et on se barre

; ----------------------------------------------------------------------
; -- Passage de la luminosit� de l'afficheur � la valeur de mode Idle -- 
; ----------------------------------------------------------------------

SetIdleBrightness:							

		ldi		ZH,RAM_Start							; On r�cup�re la valeur de luminosit� actuelle en RAM
		ldi		ZL,RAM_StartBrightness
		ld		Work1,Z


		ldi		ZH,RAM_Start							; On r�cup�re la valeur de luminosit� actuelle en RAM
		ldi		ZL,RAM_StartBrightness
		ld		Work1,Z

		ldi		ZH,RAM_Start							; On r�cup�re la valeur de luminosit� Idle en RAM
		ldi		ZL,RAM_IdleBrightness
		ld		Work2,Z

BoucleIdleBrightness:
		mov		Work,Work1								; Transf�re dans le bon registre
		rcall 	SetBrightness							; et envoie �a sur le potar num�rique

		ldi		Count1,WaitBrightEnd
		rcall	MyWait									; Petite temporisation

		dec		Work1									; D�cr�mente la luminosit�
		cp		Work1,Work2								; et tant qu'on n'est pas arriv� � la luminosit� d'idle,
		brne	BoucleIdleBrightness					; On la diminue				

		ret

; ----------------------------------------------------------------- 
; -- Retour de la luminosit� de l'afficheur � sa valeur nominale --
; ----------------------------------------------------------------- 

RestoreBrightness:

; Les deux lignes suivantes pour �viter le bug du r�veil de l'afficheur..
		ldi 	Work,0b00000100
		sts		ETIMSK,Work							; r�autorise les interruptions par overflow sur le timer 3

		sbi		PortLedOn,LedOn						; Eventuellement, rallumer la Led

		ldi		ZH,RAM_Start						; On r�cup�re la caleur de luminosit� normale en RAM
		ldi		ZL,RAM_StartBrightness
		ld		Work,Z

		rcall	SetBrightness

		ret

; -------------------------------------------------------
; -- Augmentation de la luminosit� par une commande IR --
; -------------------------------------------------------

IncreaseBrightness:

		ldi		ZH,RAM_Start						; Octet de poids fort de l'adresse de d�but en RAM 
		ldi		ZL,RAM_StartBrightness				; L'adresse de la luminosit� en RAM
		ld		Work,Z								; R�cup�re la valeur stock�e en RAM 

		cpi		Work,255							; On est au max ?
		breq	ExitADIncB							;   vi -> on s'en va

		cpi		Work,245
		brsh	ExitADIncB

;		inc		Work								; sinon, on augmente la luminosit�
		subi	Work,-10

		ldi		ZH,RAM_Start						; Et on restocke la nouvelle valeur en RAM 
		ldi		ZL,RAM_StartBrightness				; 
		st		Z,Work								;  

		rcall	SetBrightness						; de mani�re effective ;)

ExitADIncB:
		ret

; -----------------------------------------------------
; -- Diminution de la luminosit� par une commande IR --
; -----------------------------------------------------

DecreaseBrightness:

		ldi		ZH,RAM_Start						; Octet de poids fort de l'adresse de d�but en RAM 
		ldi		ZL,RAM_StartBrightness				; L'adresse de la luminosit� en RAM
		ld		Work,Z								; R�cup�re la valeur stock�e en RAM 

		cpi		Work,0								; On est au min ?
		breq	ExitADDecB							;   vi -> on s'en va

		cpi		Work,10
		brlo	ExitADDecB
		subi	Work,10

		ldi		ZH,RAM_Start						; Et on restocke la nouvelle valeur en RAM 
		ldi		ZL,RAM_StartBrightness				; 
		st		Z,Work								;  

		rcall	SetBrightness						; de mani�re effective ;)

ExitADDecB:
		ret

; -------------------------------------------------
; -- Diminution du contraste par une commande IR --
; -------------------------------------------------

IncreaseContrast:

		ldi		ZH,RAM_Start						; Octet de poids fort de l'adresse de d�but en RAM 
		ldi		ZL,RAM_StartContrast				; L'adresse du contraste en RAM
		ld		Work,Z								; R�cup�re la valeur stock�e en RAM 

		cpi		Work,ContrasteMaxi					; On est au max ?
		breq	ExitADIncC							;   vi -> on s'en va

		inc		Work								; sinon, on diminue le contraste

		ldi		ZH,RAM_Start						; Et on restocke la nouvelle valeur en RAM 
		ldi		ZL,RAM_StartContrast				; 
		st		Z,Work								;  

		rcall	SetContrast							; de mani�re effective ;)

ExitADIncC:
		ret

; ---------------------------------------------------
; -- Augmentation du contraste par une commande IR --
; ---------------------------------------------------

DecreaseContrast:

		ldi		ZH,RAM_Start						; Octet de poids fort de l'adresse de d�but en RAM 
		ldi		ZL,RAM_StartContrast				; L'adresse de la luminosit� en RAM
		ld		Work,Z								; R�cup�re la valeur stock�e en RAM 

		cpi		Work,0								; On est au min ?
		breq	ExitADDecC							;   vi -> on s'en va

		dec		Work								; sinon, on diminue le contraste

		ldi		ZH,RAM_Start						; Et on restocke la nouvelle valeur en RAM 
		ldi		ZL,RAM_StartContrast				; 
		st		Z,Work								;  

		rcall	SetContrast							; de mani�re effective ;)

ExitADDecC:
		ret

