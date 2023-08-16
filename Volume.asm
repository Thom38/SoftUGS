; =====================================================================
; ==                                                                 ==
; == Routines pour le contr�le du volume et de la balance par relais ==
; ==                                                                 ==
; =====================================================================

; ===========================================================
; === L'encodeur a dit qu'il fallait changer le volume... ===
; ===========================================================

ChangeVolume:

        sbrc	StatReg1,FlagIdle					; Si le timer d'Idle �tait en train de tourner,
		rcall	StopIdle							; alors on l'arr�te
		rcall	RestoreBrightness					; Sinon, onn remet l'afficheur en pleine luminosit�

VolumeDansQuelSens:
		sbrc	StatReg1,FlagIncremente				; Doit ton mettre la zique plus fort ?
		rjmp	AugmenteVolume						; oui, c'est �a
		sbrc	StatReg1,FlagDecremente				; Tu me dis de mettre moins fort ?
		rjmp	DiminueVolume						; b� oui

		rjmp	ExitChangeVolume					; sinon on se barre

AugmenteVolume:
		ldi		Work,VolumeMaxi						; on est d�j� au max ?
		cp		VolReg,Work
		breq	ExitChangeVolume					; Oui, alors on ne fait rien...
		inc		VolReg								; sinon on augmente le volume

		sbrs	IRSup,IRCountOver					; A-t-on termin� p�riode de speedup ?
		rjmp	TermineChangeVolume					; 	- Nan, alors on fait comme d'hab

		sbrs	IRSup,IRVolUp						; C'�tait un Speedup pour une augmentation de volume ?
		rjmp	TermineChangeVolume					; 	- Nan, alors on fait comme d'hab
		
		ldi		Work,VolumeMaxi						; sinon, on reteste : on est d�j� au max ?
		cpse	VolReg,Work
		inc		Volreg								; Non, pas encore on max, alors on augmente d'un cran

		sbrs	IRSup,IRCountOverMore				; Acc�l�rer encore ?
		rjmp	TermineChangeVolume					; Non, �a suffit

		ldi		Work,VolumeMaxi						; sinon, on reteste : on est d�j� au max ?
		cpse	VolReg,Work
		inc		Volreg								; Non, pas encore on max, alors on augmente d'un cran

		ldi		Work,VolumeMaxi						; Et on reteste encore : on est d�j� au max ?
		cpse	VolReg,Work
		inc		Volreg								; Non, pas encore on max, alors on augmente d'un cran


		rjmp	TermineChangeVolume					; et on va aller actualiser tout �a

DiminueVolume:
		clr		Work								; Volume d�j� au mini ?
		cp		VolReg,Work
		breq	ExitChangeVolume					; Oui, alors on ne fait rien...
		dec		VolReg								; sinon on baisse le son

		sbrs	IRSup,IRCountOver					; Est-on en p�riode de speedup ?
		rjmp	TermineChangeVolume					; 	- Nan, alors on fait comme d'hab

		sbrs	IRSup,IRVolDown						; C'�tait un Speedup pour une diminution de volume ?
		rjmp	TermineChangeVolume					; 	- Nan, alors on fait comme d'hab

		clr		Work								; sinon, on reteste : on est d�j� au min ?
		cpse	VolReg,Work
		dec		Volreg								; Non, pas encore on min, alors on baisse d'un cran suppl�mentaire

		sbrs	IRSup,IRCountOverMore				; Acc�l�rer encore ?
		rjmp	TermineChangeVolume					; Non, �a suffit

		clr		Work								; sinon, on reteste : on est d�j� au min ?
		cpse	VolReg,Work
		dec		Volreg								; Non, pas encore on min, alors on baisse d'un cran suppl�mentaire

		clr		Work								; Et on reteste encore : on est d�j� au min ?
		cpse	VolReg,Work
		dec		Volreg								; Non, pas encore on min, alors on baisse d'un cran suppl�mentaire

TermineChangeVolume:
		rcall 	AfficheVolume						; Affiche la nouvelle valeur du volume 
		rcall	SetVolume							; Met les relais � jour
		rcall	StartIdle							; On relance le timer de "fout rien"

ExitChangeVolume:									; Plus rien � faire ici
		cbr		StatReg1,EXP2(FlagIncremente)		; On met � z�ro
		cbr		StatReg1,EXP2(FlagDecremente)		; les flags pour l'encodeur
		ret											; et on s'en va

; ======================================================
; === Calcul de la valeur du volume sur chaque canal ===
; === et activation des relais de volume             ===
; ======================================================

SetVolume:		

; On commence par mettre le volume au minimum (c'est ce qui est fait ici),
; et au bout du d�lai de MBB, on commence � activer les relais qui doivent l'�tre.
; On les active dans l'ordre croissant (du LSB vers le MSB), et c'est fait
; dans la routine d'interruption du timer de MBB

		in		Work,PortVolume						; R�cup�re l'�tat des relais mute et volume
		andi	Work,0b10000000						; et on met tous le volume � z�ro (att�nuation max) sans toucher au relais de mute	
		out		PortVolume,Work 					; On remet ce registre � disposition sur le port de volume
		sbi		PortLatchVolG,LE_VolG				; Une impulsion pour le latch
		cbi		PortLatchVolG,LE_VolG
		sbi		PortLatchVolD,LE_VolD				; Une impulsion pour le latch
		cbi		PortLatchVolD,LE_VolD

SetVolumeNoMin:										; Lance le MBB sans passer par le volume au minimum (point d'entr�e pour la commutation des entr�es)

; -- On prend en compte la balance entre canaux

		rcall 	SetBalance

		sbr		StatReg2,EXP2(FlagMBB)				; Signale dans un registre de status qu'on va �tre en phase de MBB

		out		TCNT0,DelayPot						; Copie la valeur du d�lai dans le registre du Timer 0

		ldi		Work,Timer0Div						; Pour mettre le prescaler du timer 0
		out		TCCR0,Work							; sur clk/64 -> 16�s par it�ration du compteur et le timer est lanc�

		ret											; On a fini pour le moment, la fin dans DelayRelayMBB ;)		
		 
; =============================================================================================
; == Volume � la mise en route -> Pas besoin du make before break ni de v�rifier le mute ... ==
; =============================================================================================

SetStartVolume:

		out		PortVolume,VolRegG					; Le volume de la voie gauche sur le port des relais
		sbi		PortLatchVolG,LE_VolG				; Une impulsion pour le latch
		cbi		PortLatchVolG,LE_VolG

		out		PortVolume,VolRegD					; Le volume de la voie droite sur le port des relais
		sbi		PortLatchVolD,LE_VolD				; Une impulsion pour le latch
		cbi		PortLatchVolD,LE_VolD

		ret											; et c'est tout

; ======================================================================== 
; == Ajuste la balance des deux canaux                                  ==
; == 9 dB de d�battement � droite et � gauche 		   	                == 
; == Le bit 7 du registre contient l'info de signe :                    ==
; ==  0 -> plus � gauche et moins � droite                              ==
; ==  1 -> moins � gauche et plus � droite								==
; ========================================================================

SetBalance:

		mov		VolRegG,VolReg						; Pour l'instant,
		mov		VolRegD,VolReg						; Volume identique sur les deux canaux

ComputeBalance:

		mov		Work,BalanceReg
		cpi		Work,0								; Si la balance est au milieu, pas besoin d'aller plus loin
		breq	ExitBalance

		mov 	Work,BalanceReg						; Sinon, stockage temporaire

		andi	Work,MasqueBalance					; On ne garde que les 4 premiers bits

		sbrs	BalanceReg,7						; Rep�re le signe de la balance			; 
		rjmp	PlusAGauche							; 0 -> Plus � gauche
		rjmp	PlusADroite							; 1 -> Plus � droite

; -- Volume plus fort � gauche --

PlusAGauche:

;		cp		VolReg,Work							; On compare le volume et la balance
;		brlo	DroiteMini							; Si le volume est plus petit que la balance, le volume de droite est minimal

;		sub		VolRegD,Work						; sinon, on soustrait la balance du volume de droite
;		rjmp	PlusAGaucheCauche					; et on s'occupe du volume de gauche

;DroiteMini:
;		clr		VolRegD								; Volume de droite au minimum
		
PlusAGaucheCauche:			
		add		VolRegG,Work						; Ajoute la balance au volume de gauche
		sbrs	VolRegG,7							; Si le 8�me bit de volume passe � 1, c'est qu'on est trop haut, alors on fixe le volume au maxi
		rjmp 	ExitBalance							; sinon, on s'en va

		ldi		Work,VolumeMaxi
		mov		VolRegG,Work						; passe le volume de gauche au maxi
		rjmp	ExitBalance

; -- Volume plus fort � droite --

PlusADroite:

;		cp		VolReg,Work							; On compare le volume et la balance
;		brlo	GaucheMini							; Si le volume est plus petit que la balance, le volume de gauche est minimal

;		sub		VolRegG,Work						; sinon, on soustrait la balance du volume de gauche
;		rjmp	PlusADroiteDroite					; et on s'occupe du volume de droite

;GaucheMini:
;		clr		VolRegG								; Volume de gauche au minimum
		
PlusADroiteDroite:			
		add		VolRegD,Work						; Ajoute la balance au volume de droite
		sbrs	VolRegD,7							; Si le 8�me bit de volume passe � 1, c'est qu'on est trop haut, alors on fixe le volume au maxi
		rjmp 	ExitBalance							; sinon, on s'en va

		ldi		Work,VolumeMaxi
		mov		VolRegD,Work						; passe le volume de droite au maxi

ExitBalance:

		ret											; c'est fini

;=========================================
; == Routine d'ajustement de la balance ==
;=========================================

AjusteBalance:

		mov		Work,BalanceReg						; Copie l'ancienne valeur de balance
		andi	Work,MasqueBalance					; on ne garde que les 4 premiers bits de valeur

		sbrc	StatReg1,FlagDecremente				; On d�cr�mente la balance ?
		rjmp	AjusteBalanceG						; 	- Oui -> Action
		sbrc	StatReg1,FlagIncremente				; 	- Non -> On l'augmente ?
		rjmp	AjusteBalanceD						;		- Oui -> Action
		rjmp	ExitAjusteBalance					; 		- Non -> Cassos

; -- On modifie la balance vers le canal gauche

AjusteBalanceG:											
		sbrs	BalanceReg,7						; La balance �tait � doite ?
		rjmp	BalGAugmente						; 	- Non -> On augmente la valeur
		rjmp	BalGDiminue							; 	- Oui -> Faut diminuer la valeur

BalGAugmente:										; La balance �tait du c�t� gauche -> On augmente la valeur si on peut
		cpi		Work,BalanceMaxi					; On est d�j� au max ?
		breq	BalOnlyDisp							; 	- Oui -> On affiche juste
		inc		BalanceReg							; 	- Non -> on augmente											
		rjmp	ActualiseBalance					; et on actualise la valeur

BalGDiminue:										; La balance �tait du c�t� droit -> il faut diminuer
		cpi		Work,1								; On est juste avant la balance au centre ?
		breq	BalanceAuCentre						; 	- Oui -> Faut changer le bit 7
		
		dec		BalanceReg							; 	- Non -> On d�cr�mente juste
		rjmp	ActualiseBalance					; et on actualise la valeur

; -- On modifie la balance vers le canal droit

AjusteBalanceD:
		sbrs	BalanceReg,7						; La balance �tait � doite ?
		rjmp	BalDDiminue							; 	- Non -> On diminue la valeur
		rjmp	BalDAugmente						; 	- Oui -> Faut augmenter la valeur

BalDAugmente:										; La balance �tait du c�t� gauche -> il faut diminuer, mais attention si on �tait au centre (bit 7 � 0)
		cpi		Work,BalanceMaxi					; On est d�j� au max ?
		breq	BalOnlyDisp							; 	- Oui -> On affiche juste
	
		inc		BalanceReg							; 	- Non -> on augmente											
		rjmp	ActualiseBalance					; et on actualise la valeur

BalDDiminue:										;  La balance �tait d�j� du c�t� droit -> On augmente la valeur si on peut
		cpi		Work,1								; On est juste avant la balance au centre ?
		breq	BalanceAuCentre						; 	- Oui -> on la passe au centre

		cpi		Work,0								; Attention si la balance �tait au centre...
		breq	SortDuCentre

		dec		BalanceReg							; 	- Non -> On icr�mente juste
		rjmp	ActualiseBalance					; et on actualise la valeur

SortDuCentre:										; Cas particulier : la balance �tait au centre, et on va vers la droite 
		ldi		Work,0b10000001						; -> Faut passer le bit 7 � 1, et mettre 1 comme valeur de balance
		mov		BalanceReg,Work
		rjmp	ActualiseBalance					; et on actualise la valeur

BalanceAuCentre:
		clr		BalanceReg							; On remet la balance � 0

ActualiseBalance:									; On stocke la nouvelle valeur de la balance en RAM

		ldi		ZH,RAM_Start
		ldi		ZL,RAM_Balance						; Adresse de la valeur en RAM
		st		Z,BalanceReg						; et on met la valeur en RAM

		sbrs	StatReg1,FlagMenu					; Si on est pas en mode Menu
		rcall	AfficheBalance						; on affiche normalement
		sbrc	StatReg1,FlagMenu					; sinon on affiche
		rcall 	AfficheBalanceNoClear				; sans effacer tout l'afficheur

		call	SetVolume							; On transmet �a aux relais de volume (avec prise en compte de la balance)

		rjmp	ExitAjusteBalance					; et on s'en va

BalOnlyDisp:
		sbrs	StatReg1,FlagMenu					; Si on est pas en mode Menu
		rcall	AfficheBalance						; on affiche normalement
		sbrc	StatReg1,FlagMenu					; sinon on affiche
		rcall 	AfficheBalanceNoClear				; sans effacer tout l'afficheur

		
ExitAjusteBalance:
		cbr		StatReg1,EXP2(FlagDecremente)		; On remet les Flags � 0	
		cbr		StatReg1,EXP2(FlagIncremente)		
		 
		ret											; et Bye


