; ===============================================
; === Routines de contr�le de l'affichage LCD ===
; ===============================================

; ---------------------------------------------
; --- Envoie une commande au LCD            ---
; --- La commande est dans le registre Work ---
; ---------------------------------------------

LCDSendCommand:

		cbi		PortCmdLCD,RW_LCD					; Ecriture dans le LCD -> R/W � 0

		cbi		PortCmdLCD,RS_LCD					; Envoie un z�ro sur Register Select pour s�lectionner le registre de commande
		sts		PortDataLCD,Work					; Envoie la commande sur le bus (c'est le port F, donc on emploie STS au lieu de OUT)
		sbi		PortCmdLCD,E_LCD					; Active l'Enable
		nop											; Il faut que le Enable reste stable pendant au moins 500ns
		nop											; donc on attend un peu
;		nop											; celui-l� est peut-�tre inutile...

		cbi		PortCmdLCD,E_LCD					; On repasse Enable � z�ro
		nop											; mais faut l�-aussi attendre un peu
;		nop											; (le cycle d'enable doit faire plus de 1400ns)
;		nop											; peut-�tre inutile aussi

		ret											; et on a fini

; ----------------------------------------------
; --- Envoie un octet de donn�es au LCD      ---
; --- Les donn�es sont dans le registre Char ---
; ----------------------------------------------

LCDSendData:

		cbi		PortCmdLCD,RW_LCD					; Ecriture dans le LCD -> R/W � 0

		sbi		PortCmdLCD,RS_LCD					; Envoie un 1 sur Register Select pour s�lectionner le registre de donn�es
		sts		PortDataLCD,Char					; Envoie les donn�es sur le bus (c'est le port F, donc on emploie STS au lieu de OUT)
		sbi		PortCmdLCD,E_LCD					; Active l'Enable
		nop											; Il faut que le Enable reste stable pendant au moins 500ns
		nop											; donc on attend un peu
;		nop											; celui-l� est peut-�tre inutile...

		cbi		PortCmdLCD,E_LCD					; On repasse Enable � z�ro
		cbi		PortCmdLCD,RS_LCD					; Et aussi RS
		nop											; mais faut l�-aussi attendre un peu
;		nop											; (le cycle d'enable doit faire plus de 1400ns)

		ret											; et on a fini

; ------------------------------------------------------------------------------------------
; --- Teste le Flag "Busy" du LCD                                                        ---
; --- et par la m�me occasion r�cup�re le registre d'adresse (bits 6-0 du registre Work) ---
; ------------------------------------------------------------------------------------------

LCDTestBusyFlag:

		cbi		PortCmdLCD,RS_LCD					; 0 sur le Register Select pour s�lectionner le registre de commande
		sbi		PortCmdLCD,RW_LCD					; 1 sur R/W pour passer en lecture sur le LCD
		sbi		PortCmdLCD,E_LCD					; Front montant d'enable

													; Les instructions suivantes, outre leur utilit� propre, 
													; permettent d'assurer les temps de cycle d'enable (1200ns) sans pb

		clr		Work   	  							; On met 0 dans le registre de direction
		sts		DataDirLCD,Work						; pour passer le port de donn�es du LCD en entr�e
		out		PinsDataLCD,Work					; Met les broches d'entr�e � 0 		
		in		Work,PinsDataLCD					; R�cup�re les donn�es du LCD
		
		cbi		PortCmdLCD,E_LCD					; Front descendant d'Enable

		push	Work								; Sauvegarde le registre dans la pile
		ser		Work								; Repasse les broches en sortie
		sts		DataDirLCD,Work						; en mettant des 1 dans le registre de direction
		cbi		PortCmdLCD,RW_LCD					; Repasse R/W � 0
		pop		Work								; r�cup�re le contenu du registre qui avait �t� sauvegard�

		sbrc	Work,7								; Le Busy Flag est il � 1 (l'afficheur est occup�) ?
		rjmp	LCDTestBusyFlag						; nan -> On reboucle et on attend

		ret											; oui -> On s'en va

; --------------------------------------
; -- Routine d'initialisation du LCD ---
; --------------------------------------

DisplayInit:

		ldi 	Work,0b00111000						; Function set : Interface 8 bits, 2 lignes, caract�re 5x7
		rcall	LCDSendCommand						; Et on envoie la commande

		ldi 	Work,54								; Petite boucle d'attente comme on ne peut pas encore tester le Busy Flag
WaitLCD1:
		dec		Work								; 54 it�rations de 3 cycles
		brne	WaitLCD1							; soit environ 40�s

		ldi 	Work,0b00111000						; On refait le m�me Function set (comme indiqu� dans le datasheet... Ne pas chercher � comprendre...)
		rcall	LCDSendCommand						; Et on envoie la commande

		ldi 	Work,54								; Petite boucle d'attente comme on ne peut pas encore tester le Busy Flag
WaitLCD2:
		dec		Work								; 54 it�rations de 3 cycles
		brne	WaitLCD2							; soit environ 40�s

		ldi		Work,0b00001100						; Display On, Cursor Off, Blink Off
		rcall 	LCDSendCommand						; et on envoie la commande
		rcall 	LCDTestBusyFlag						; Attend la fin de commande

		ldi		Work,0b00000001						; Display Clear
		rcall 	LCDSendCommand						; et on envoie la commande
		rcall 	LCDTestBusyFlag						; Attend la fin de commande (1.5ms)

		ldi		Work,0b00000110						; Incr�mentation automatique du curseur, pas de shift du display
		rcall 	LCDSendCommand						; et on envoie la commande
		rcall 	LCDTestBusyFlag						; Attend la fin de commande

		ret											; et c'est termin� pour l'initialisation

; -----------------------------------------------------------------------
; --- Ecrit un caract�re utilisateur dans la RAM graphique du LCD     ---
; --- L'adresse en EEPROM du d�but du caract�re est plac�e dans Work1 ---
; --- L'adresse du caract�re en CGRam est dans le registre Work2      ---
; -----------------------------------------------------------------------

DisplayWriteCGRAM:

		clr		Count1
		out		EEARH,Count1

		ldi 	Count1,8							; 8 lignes � �crire

LCDBoucleCar:
		
		mov		Work,Work2							; Copie l'adresse CGRAM dans Work
		sbr		Work,0b01000000						; Pour indiquer une adresse CGRAM, met le bit 6 � 1
		cbr		Work,0b10000000						; et le bit 7 � z�ro
		rcall	LCDSendCommand						; Envoie l'instrucution au LCD
		rcall 	LCDTestBusyFlag						; et attend la fin de commande

LoopCGWFEE:
		sbic	EECR,EEWE							; Si EEWE n'est pas � 0
		rjmp	LoopCGWFEE							; on attend

        out     EEARL,Work1                     	; On charge "l'adresse" de la ligne de caract�re pour l'EEPROM
        sbi     EECR,EERE                       	; On pr�pare l'EEPROM � la lecture
        in      Char,EEDR                     		; On lit la valeur stok�e en EEPROM et on la met dans le registre Char

		rcall	LCDSendData							; On envoie la valeur � l'afficheur
		rcall 	LCDTestBusyFlag						; et on attend la fin de commande

		inc		Work1								; incr�mente l'adresse de l'EEPROM pour la ligne suivante
		inc		Work2								; Incr�mente l'adresse en CGRAM
		dec		Count1								; d�cr�mente le compteur de ligne 
		brne	LCDBoucleCar						; C'est la derni�re ligne du caract�re ? 

;		sei											; Oui -> Alors on r�tabilt les interruptions
		ret											; On a fini

; -----------------------------------------------------------------------------
; --- Pour �crire un caract�re sur l'afficheur,
; --- Lui donner la position (rcall DisplayPlaceCurseur)
; --- puis envoyer le caract�re (rcall LCDWriteChar)
; ---
; --- Pour des �criture successives, comme le curseur bouge tout seul
; --- apr�s chaque �criture, seul un appel � LCDWriteChar est n�cessaire
; -----------------------------------------------------------------------------

; -------------------------------------------------------
; --- Met le "curseur" � une certaine position        ---
; --- La position (adresse) est dans le registre Work ---
; -------------------------------------------------------

DisplayPlaceCurseur:

		sbr		Work,0b10000000						; Pour indiquer une adresse DDRAM, met le bit 7 � 1
		rcall	LCDSendCommand						; Envoie l'instrucution au LCD
		rcall 	LCDTestBusyFlag						; et attend la fin de commande

		ret											; et on a fini

; ------------------------------------------
; --- Ecrit un caract�re sur l'afficheur --- 
; --- Le caract�re est dans Char         ---
; ------------------------------------------

DisplayWriteChar:

;		rcall	LCDTesteChar
		rcall	LCDSendData							; On envoie la valeur � l'afficheur
		rcall 	LCDTestBusyFlag						; et on attend la fin de commande

		ret											; et on se casse

LCDTesteChar:

		cpi		Char,'g'
		brne	S1
		ldi		Char,0xE7
		ret
S1:		cpi		Char,'j'
		brne	S2
		ldi		Char,0xEA
		ret
S2:		cpi		Char,'p'
		brne	S3
		ldi		Char,0xF0
		ret
S3:		cpi		Char,'q'
		brne	S4
		ldi		Char,0xF1'
		ret
S4:		cpi		Char,'y'
		brne	S5
		ldi		Char,0xF9
		ret
S5:
		ret

; ------------------------------------
; --- Efface l'afficheur           ---
; --- Et remet le curseur au d�but ---
; ------------------------------------

DisplayClear:

		ldi 	Work,1								; Commande d'effacement
		rcall 	LCDSendCommand						; et on envoie la commande
		rcall 	LCDTestBusyFlag						; Attend la fin de commande (1.5ms)


LCDHome:

		ldi		Work,0b00000010						; Return Home
		rcall 	LCDSendCommand						; et on envoie la commande
		rcall 	LCDTestBusyFlag						; Attend la fin de commande (1.5ms)

		ret											; et cassos


; ----------------------------
; --- Affichage du curseur ---
; ----------------------------

DisplayCursorOn:

		ldi		Work,0b00001110						; Display On, Cursor On, Blink Off
		rcall 	LCDSendCommand						; et on envoie la commande
;		rcall 	LCDTestBusyFlag						; Attend la fin de commande
		ret											; et bye

; -----------------------------
; --- Effacement du curseur ---
; -----------------------------

DisplayCursorOff:

		ldi		Work,0b00001100						; Display On, Cursor Off, Blink Off
		rcall 	LCDSendCommand						; et on envoie la commande
		rcall 	LCDTestBusyFlag						; Attend la fin de commande
		ret											; et bye

; --------------------------------
; -- Curseur en bloc clignotant --
; --------------------------------

DisplayCursorBlock:
		ldi		Work,0b00001111						; Display On, Cursor On, Blink On
		rcall 	LCDSendCommand						; et on envoie la commande
		rcall 	LCDTestBusyFlag						; Attend la fin de commande
		ret											; et bye

; ---------------------------------
; --- Extinction de l'afficheur ---
; ---------------------------------

DisplayOff:

		ldi		Work,0b00001000						; Display Off, Cursor Off, Blink Off
		rcall 	LCDSendCommand						; et on envoie la commande
		rcall 	LCDTestBusyFlag						; Attend la fin de commande

		ret

; -------------------------------------------------------
; --- Affichage d'une chaine de caract�res sur le LCD ---
; --- La chaine est dans la m�moire programme...      ---
; -------------------------------------------------------

DisplayAfficheChaine:

		push	Char								; Sauvegarde le registre caract�re
		push	ZL									; Sauvegarde l'adresse de d�but de la cha�ne
		push	ZH									; pour pouvoir s'en reservir � la sortie 

LCDNextChar:
		lpm		Char,Z+								; Charge le caract�re � l'adresse contenue dans le registre char,
													; et on incr�mente l'adresse m�moire dans Z
		cpi		Char,FinChaine						; Est-ce que c'est un caract�re de fin de cha�ne ?
		breq	ExitLCDAfficheChaine				; 	- Oui, alors on sort
		cpi		Char,FinLigne						; 	- Non, mais est-ce un saut de ligne ?
		breq	LCDNewLine							;		- Oui, alors on saute � la ligne
		rcall	DisplayWriteChar					; 		- Non, alors on �crit le caract�re
		rjmp	LCDNextChar							; 		  et on passe au caract�re suivant

LCDNewLine:
		ldi		Work,0x40							; Place le curseur au d�but de la seconde ligne
		rcall 	DisplayPlaceCurseur						;
		rjmp	LCDNextChar							; et passe au caract�re suivant

ExitLCDAfficheChaine:

		pop		ZH									; R�cup�re l'adresse de d�but de cha�ne
		pop		ZL									; qu'on avait stock�e au d�but
		pop 	Char								; Restaure le registre Char

		ret											; et on s'en va

; -------------------------------------------------------
; --- Affichage d'une chaine de caract�res sur le LCD ---
; --- La chaine est en RAM...                         ---
; -------------------------------------------------------

DisplayAfficheChaineRAM:

		push	Char								; Sauvegarde le registre caract�re
		push	ZL									; Sauvegarde l'adresse de d�but de la cha�ne
		push	ZH									; pour pouvoir s'en reservir � la sortie 

LCDNextCharRAM:
		ld		Char,Z+								; Charge le caract�re � l'adresse contenue dans le registre char,
													; et on incr�mente l'adresse m�moire dans Z
		cpi		Char,FinChaine						; Est-ce que c'est un caract�re de fin de cha�ne ?
		breq	ExitLCDAfficheChaineRAM				; 	- Oui, alors on sort
		cpi		Char,FinLigne					; 	- Non, mais est-ce un saut de ligne ?
		breq	LCDNewLineRAM						;		- Oui, alors on saute � la ligne
		rcall	DisplayWriteChar					; 		- Non, alors on �crit le caract�re
		rjmp	LCDNextCharRAM						; 		  et on passe au caract�re suivant

LCDNewLineRAM:
		ldi		Work,0x40							; Place le curseur au d�but de la seconde ligne
		rcall 	DisplayPlaceCurseur						;
		rjmp	LCDNextCharRAM							; et passe au caract�re suivant

ExitLCDAfficheChaineRAM:

		pop		ZH									; R�cup�re l'adresse de d�but de cha�ne
		pop		ZL									; qu'on avait stock�e au d�but
		pop 	Char								; Restaure le registre Char
		ret											; et on s'en va

; ---------------------------------------------------------------
; -- Effacement de la premi�re ou seconde ligne de l'afficheur --
; ---------------------------------------------------------------

DisplayEffacePremiereLigne:

		clr		Work								; Curseur en d�but de premi�re ligne
		rjmp	LCDEfface							; et efface la ligne

LCDEffaceSecondeLigne:								; Point d'entr�e pour l'effacement de la seconde ligne

		ldi		Work,0x40							; se place en d�but de seconde ligne

LCDEfface:
		push	Work								; sauvegarde l'adresse du d�but de ligne
		rcall 	DisplayPlaceCurseur						; Place le curseur en d�but de ligne

		ldi		Char,32								; Un blanc pour l'effacement
		ldi		Count1,0
LoopLine:
		rcall 	DisplayWriteChar					; �crit le blanc
		inc		Count1
		cpi		Count1,DisplaySize					; fin de ligne ?
		brne	LoopLine							; nan

		pop		Work								; On r�cup�re l'adresse du d�but de ligne
		call	DisplayPlaceCurseur					; Et on replace le curseur en d�but de ligne

		ret											; fin de routine

; -----------------------------------------
; -- Affiche les fl�ches pour l'encodeur --
; -----------------------------------------

DisplayArrow:

		ldi		Work,0x40							; Premi�re position
		rcall	DisplayPlaceCurseur					; seconde ligne

		ldi		Char,5								; Fl�che vers la gauche
		rcall	DisplayWriteChar

		ldi		Work,0x40							; Seconde ligne
		subi	Work,-(DisplaySize-1)
		rcall	DisplayPlaceCurseur					; derni�re position

		ldi		Char,4								; Fl�che vers la droite
		rcall	DisplayWriteChar		

		ret											; finito

; ------------------------------------------------
; -- Ecriture des caract�res accentu�s en CGRAM --
; ------------------------------------------------

DisplayCGRamDefaut:

; -- Le "�" --

		ldi		Work1,EE_Eaigu						; L'adresse en EEPROM de la d�finition du caract�re
		ldi 	Work2,CGRam_Eaigu					; L'adresse en CGRAM pour l'afficheur (ici 1)
		call	DisplayWriteCGRAM					; et on envoie le bins dans l'afficheur


; -- Le "�" --

		ldi		Work1,EE_Egrave						; L'adresse en EEPROM de la d�finition du caract�re
		ldi 	Work2,CGRam_Egrave					; L'adresse en CGRAM pour l'afficheur (ici 2)
		call	DisplayWriteCGRAM					; et on envoie le bins dans l'afficheur


; -- Le "�" --

		ldi		Work1,EE_Etrema						; L'adresse en EEPROM de la d�finition du caract�re
		ldi 	Work2,CGRam_Etrema					; L'adresse en CGRAM pour l'afficheur (ici 3)
		call	DisplayWriteCGRAM					; et on envoie le bins dans l'afficheur

; -- La fl�che vers la droite --

		ldi		Work1,EE_FDroite					; L'adresse en EEPROM de la d�finition du caract�re
		ldi 	Work2,CGRam_FDroite					; L'adresse en CGRAM pour l'afficheur (ici 4)
		call	DisplayWriteCGRAM					; et on envoie le bins dans l'afficheur


; -- La fl�che vers la gauche --

		ldi		Work1,EE_FGauche					; L'adresse en EEPROM de la d�finition du caract�re
		ldi 	Work2,CGRam_FGauche					; L'adresse en CGRAM pour l'afficheur (ici 5)
		call	DisplayWriteCGRAM					; et on envoie le bins dans l'afficheur


; -- Le "�" --

		ldi		Work1,EE_Agrave						; L'adresse en EEPROM de la d�finition du caract�re
		ldi 	Work2,CGRam_Agrave					; L'adresse en CGRAM pour l'afficheur (ici 6)
		call	DisplayWriteCGRAM					; et on envoie le bins dans l'afficheur


; -- Le Smiley --

		ldi		Work1,EE_Smile						; L'adresse en EEPROM de la d�finition du caract�re
		ldi 	Work2,CGRam_Smile					; L'adresse en CGRAM pour l'afficheur (ici 7)
		call	DisplayWriteCGRAM					; et on envoie le bins dans l'afficheur

		ret

; -----------------------------------------------------------------------
; --- Ecrit un caract�re utilisateur dans la RAM graphique du LCD     ---
; --- � l'adresse 0 pour le BarGraph                                  ---
; --- La valeur est dans le registre Char                             ---
; -----------------------------------------------------------------------

DisplayWriteBarGraph:

		push	Work2								; Sauvegarde Work2

		ldi 	Count1,8							; 8 lignes � �crire
		ldi		Work2,0								; Adresse 0 en CGRAM

		ldi		ZH,RAM_Bar_H
		ldi		ZL,RAM_Bar_L

LCDBoucleCarBG:
		ld		Char,Z+
		mov		Work,Work2							; Copie l'adresse CGRAM dans Work
		sbr		Work,0b01000000						; Pour indiquer une adresse CGRAM, met le bit 6 � 1
		cbr		Work,0b10000000						; et le bit 7 � z�ro
		rcall	LCDSendCommand						; Envoie l'instrucution au VFD
		rcall 	LCDTestBusyFlag						; et attend la fin de commande

		rcall	LCDSendData							; On envoie la valeur � l'afficheur
		rcall 	LCDTestBusyFlag						; et on attend la fin de commande

		inc		Work2								; Incr�mente l'adresse en CGRAM
		dec		Count1								; d�cr�mente le compteur de ligne 
		cpi		Count1,0							; Derdesder ?	
		breq	ExitLCDWriteBG						;   Vi, on sort
		rjmp	LCDBoucleCarBG						;   Nan, on boucle 

ExitLCDWriteBG:
		pop		Work2								; Restore Work2
		ldi		ZH,RAM_Start
		ret											; On a fini

