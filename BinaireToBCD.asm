;==================================================                         
;===                                            ===
;=== Conversion 8 bits binaires -> 2 digits BCD ===
;===                                            ===
;=== Le nombre � convertir est dans LSDVol et   ===
;=== le r�sultat est dans MSDVol et LSDVol      ===
;===                                            ===
;==================================================

BinaireToBCD:
        clr		MSDVol		        				; MSD � Z�ro par d�faut
BinToBCD_1:
		subi	LSDVol,10	        				; input = input - 10
		brcs	BinToBCD_2					        ; On s'en va si on a une retenue, non mais, on n'est plus au lyc�e, quoi
		inc		MSDVol					        	; On vient de retrancher 10, et il me reste qqchose -> on incr�mente les dizaines
		rjmp	BinToBCD_1		   				    ; et on reboucle

BinToBCD_2:
		subi	LSDVol,-10	        				; On a fait une soustraction de trop, Hombre. Faut l'annuler

		subi    LSDVol,-48              			; On passe le r�sultat en ASCII pour affichage
        subi    MSDVol,-48              			; (Valeur + 48) 
        ret											; Et ouala. Magique, non ?

; ==========================================================
; ==                                                      ==
; == Conversion mot de 16 bits binaires en 5 chiffres BCD ==
; ==                                                      ==
; == Le mot binaire est dans (Work1:Work)                 ==
; == Le r�sultat est dans (Work3:MSDVol:LSDVol)           ==
; == par groupes de nibbles.                              ==
; == Comme on a besoin que de 4 chiffres, on se fiche     ==
; == un peu du registre Work3...                          ==
; ==                                                      ==
; ==========================================================

BinaireToBCD16:

	ldi		Count1,16								; Initialisation du compteur de boucle	
	clr		Work3 									; Met les 3 registres de r�sultat � Z�ro 
	clr		MSDVol		
	clr		LSDVol		

Bin2BCD16_1:

	lsl		Work									; Shift la valeur d'entr�e
	rol		Work1									; pour tous les octets
	rol		LSDVol									;
	rol		MSDVol
	rol		Work3
	dec		Count1									; D�cr�mente le compteur de boucle
	brne	Bin2BCD16_2								; Si on n'est pas arriv� � z�ro -> un peu de math
	ret												; sinon on s'en va

Bin2BCD16_2:

	mov		Work2,Work3								; R�cup�re le contenu du MMSD dans Work2 
	subi	Work2,-$03								; Ajoute 0x03
	sbrc	Work2,3									; Si le bit 3 est positionn�
	mov		Work3,Work2								; 	on restocke en MMSD
	mov		Work2,Work3								; Sinon, on r�cup�re la valeur initiale
	subi	Work2,-$30								; Ajoute 0x30
	sbrc	Work2,7									; Si le bit 7 est positionn�
	mov		Work3,Work2								;	on restocke 

	mov		Work2,MSDVol							; R�cup�re le contenu du MSD dans Work2 
	subi	Work2,-$03								; Ajoute 0x03
	sbrc	Work2,3									; Si le bit 3 est positionn�
	mov		MSDVol,Work2							;	on restocke en MSD
	mov		Work2,MSDVol							; Sinon, on r�cup�re la valeur initiale
	subi	Work2,-$30								; Ajoute 0x30
	sbrc	Work2,7									; Si le bit 7 est positionn�
	mov		MSDVol,Work2							;	on restocke

	mov		Work2,LSDVol							; R�cup�re le contenu du LSD dans Work2 
	subi	Work2,-$03								; Ajoute 0x03
	sbrc	Work2,3									; Si le bit 3 est positionn�
	mov		LSDVol,Work2							;	on restocke en LSD
	mov		Work2,LSDVol							; Sinon, on r�cup�re la valeur initiale
	subi	Work2,-$30								; Ajoute 0x30
	sbrc	Work2,7									; Si le bit 7 est posiStionn�
	mov		LSDVol,Work2							;	on restocke

	rjmp	Bin2BCD16_1		

