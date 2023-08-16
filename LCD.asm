; ===============================================
; === Routines de contrôle de l'affichage LCD ===
; ===============================================

; ---------------------------------------------
; --- Envoie une commande au LCD            ---
; --- La commande est dans le registre Work ---
; ---------------------------------------------

LCDSendCommand:

		cbi		PortCmdLCD,RW_LCD					; Ecriture dans le LCD -> R/W à 0

		cbi		PortCmdLCD,RS_LCD					; Envoie un zéro sur Register Select pour sélectionner le registre de commande
		sts		PortDataLCD,Work					; Envoie la commande sur le bus (c'est le port F, donc on emploie STS au lieu de OUT)
		sbi		PortCmdLCD,E_LCD					; Active l'Enable
		nop											; Il faut que le Enable reste stable pendant au moins 500ns
		nop											; donc on attend un peu
;		nop											; celui-là est peut-être inutile...

		cbi		PortCmdLCD,E_LCD					; On repasse Enable à zéro
		nop											; mais faut là-aussi attendre un peu
;		nop											; (le cycle d'enable doit faire plus de 1400ns)
;		nop											; peut-être inutile aussi

		ret											; et on a fini

; ----------------------------------------------
; --- Envoie un octet de données au LCD      ---
; --- Les données sont dans le registre Char ---
; ----------------------------------------------

LCDSendData:

		cbi		PortCmdLCD,RW_LCD					; Ecriture dans le LCD -> R/W à 0

		sbi		PortCmdLCD,RS_LCD					; Envoie un 1 sur Register Select pour sélectionner le registre de données
		sts		PortDataLCD,Char					; Envoie les données sur le bus (c'est le port F, donc on emploie STS au lieu de OUT)
		sbi		PortCmdLCD,E_LCD					; Active l'Enable
		nop											; Il faut que le Enable reste stable pendant au moins 500ns
		nop											; donc on attend un peu
;		nop											; celui-là est peut-être inutile...

		cbi		PortCmdLCD,E_LCD					; On repasse Enable à zéro
		cbi		PortCmdLCD,RS_LCD					; Et aussi RS
		nop											; mais faut là-aussi attendre un peu
;		nop											; (le cycle d'enable doit faire plus de 1400ns)

		ret											; et on a fini

; ------------------------------------------------------------------------------------------
; --- Teste le Flag "Busy" du LCD                                                        ---
; --- et par la même occasion récupère le registre d'adresse (bits 6-0 du registre Work) ---
; ------------------------------------------------------------------------------------------

LCDTestBusyFlag:

		cbi		PortCmdLCD,RS_LCD					; 0 sur le Register Select pour sélectionner le registre de commande
		sbi		PortCmdLCD,RW_LCD					; 1 sur R/W pour passer en lecture sur le LCD
		sbi		PortCmdLCD,E_LCD					; Front montant d'enable

													; Les instructions suivantes, outre leur utilité propre, 
													; permettent d'assurer les temps de cycle d'enable (1200ns) sans pb

		clr		Work   	  							; On met 0 dans le registre de direction
		sts		DataDirLCD,Work						; pour passer le port de données du LCD en entrée
		out		PinsDataLCD,Work					; Met les broches d'entrée à 0 		
		in		Work,PinsDataLCD					; Récupère les données du LCD
		
		cbi		PortCmdLCD,E_LCD					; Front descendant d'Enable

		push	Work								; Sauvegarde le registre dans la pile
		ser		Work								; Repasse les broches en sortie
		sts		DataDirLCD,Work						; en mettant des 1 dans le registre de direction
		cbi		PortCmdLCD,RW_LCD					; Repasse R/W à 0
		pop		Work								; récupère le contenu du registre qui avait été sauvegardé

		sbrc	Work,7								; Le Busy Flag est il à 1 (l'afficheur est occupé) ?
		rjmp	LCDTestBusyFlag						; nan -> On reboucle et on attend

		ret											; oui -> On s'en va

; --------------------------------------
; -- Routine d'initialisation du LCD ---
; --------------------------------------

DisplayInit:

		ldi 	Work,0b00111000						; Function set : Interface 8 bits, 2 lignes, caractère 5x7
		rcall	LCDSendCommand						; Et on envoie la commande

		ldi 	Work,54								; Petite boucle d'attente comme on ne peut pas encore tester le Busy Flag
WaitLCD1:
		dec		Work								; 54 itérations de 3 cycles
		brne	WaitLCD1							; soit environ 40µs

		ldi 	Work,0b00111000						; On refait le même Function set (comme indiqué dans le datasheet... Ne pas chercher à comprendre...)
		rcall	LCDSendCommand						; Et on envoie la commande

		ldi 	Work,54								; Petite boucle d'attente comme on ne peut pas encore tester le Busy Flag
WaitLCD2:
		dec		Work								; 54 itérations de 3 cycles
		brne	WaitLCD2							; soit environ 40µs

		ldi		Work,0b00001100						; Display On, Cursor Off, Blink Off
		rcall 	LCDSendCommand						; et on envoie la commande
		rcall 	LCDTestBusyFlag						; Attend la fin de commande

		ldi		Work,0b00000001						; Display Clear
		rcall 	LCDSendCommand						; et on envoie la commande
		rcall 	LCDTestBusyFlag						; Attend la fin de commande (1.5ms)

		ldi		Work,0b00000110						; Incrémentation automatique du curseur, pas de shift du display
		rcall 	LCDSendCommand						; et on envoie la commande
		rcall 	LCDTestBusyFlag						; Attend la fin de commande

		ret											; et c'est terminé pour l'initialisation

; -----------------------------------------------------------------------
; --- Ecrit un caractère utilisateur dans la RAM graphique du LCD     ---
; --- L'adresse en EEPROM du début du caractère est placée dans Work1 ---
; --- L'adresse du caractère en CGRam est dans le registre Work2      ---
; -----------------------------------------------------------------------

DisplayWriteCGRAM:

		clr		Count1
		out		EEARH,Count1

		ldi 	Count1,8							; 8 lignes à écrire

LCDBoucleCar:
		
		mov		Work,Work2							; Copie l'adresse CGRAM dans Work
		sbr		Work,0b01000000						; Pour indiquer une adresse CGRAM, met le bit 6 à 1
		cbr		Work,0b10000000						; et le bit 7 à zéro
		rcall	LCDSendCommand						; Envoie l'instrucution au LCD
		rcall 	LCDTestBusyFlag						; et attend la fin de commande

LoopCGWFEE:
		sbic	EECR,EEWE							; Si EEWE n'est pas à 0
		rjmp	LoopCGWFEE							; on attend

        out     EEARL,Work1                     	; On charge "l'adresse" de la ligne de caractère pour l'EEPROM
        sbi     EECR,EERE                       	; On prépare l'EEPROM à la lecture
        in      Char,EEDR                     		; On lit la valeur stokée en EEPROM et on la met dans le registre Char

		rcall	LCDSendData							; On envoie la valeur à l'afficheur
		rcall 	LCDTestBusyFlag						; et on attend la fin de commande

		inc		Work1								; incrémente l'adresse de l'EEPROM pour la ligne suivante
		inc		Work2								; Incrémente l'adresse en CGRAM
		dec		Count1								; décrémente le compteur de ligne 
		brne	LCDBoucleCar						; C'est la dernière ligne du caractère ? 

;		sei											; Oui -> Alors on rétabilt les interruptions
		ret											; On a fini

; -----------------------------------------------------------------------------
; --- Pour écrire un caractère sur l'afficheur,
; --- Lui donner la position (rcall DisplayPlaceCurseur)
; --- puis envoyer le caractère (rcall LCDWriteChar)
; ---
; --- Pour des écriture successives, comme le curseur bouge tout seul
; --- après chaque écriture, seul un appel à LCDWriteChar est nécessaire
; -----------------------------------------------------------------------------

; -------------------------------------------------------
; --- Met le "curseur" à une certaine position        ---
; --- La position (adresse) est dans le registre Work ---
; -------------------------------------------------------

DisplayPlaceCurseur:

		sbr		Work,0b10000000						; Pour indiquer une adresse DDRAM, met le bit 7 à 1
		rcall	LCDSendCommand						; Envoie l'instrucution au LCD
		rcall 	LCDTestBusyFlag						; et attend la fin de commande

		ret											; et on a fini

; ------------------------------------------
; --- Ecrit un caractère sur l'afficheur --- 
; --- Le caractère est dans Char         ---
; ------------------------------------------

DisplayWriteChar:

;		rcall	LCDTesteChar
		rcall	LCDSendData							; On envoie la valeur à l'afficheur
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
; --- Et remet le curseur au début ---
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
; --- Affichage d'une chaine de caractères sur le LCD ---
; --- La chaine est dans la mémoire programme...      ---
; -------------------------------------------------------

DisplayAfficheChaine:

		push	Char								; Sauvegarde le registre caractère
		push	ZL									; Sauvegarde l'adresse de début de la chaîne
		push	ZH									; pour pouvoir s'en reservir à la sortie 

LCDNextChar:
		lpm		Char,Z+								; Charge le caractère à l'adresse contenue dans le registre char,
													; et on incrémente l'adresse mémoire dans Z
		cpi		Char,FinChaine						; Est-ce que c'est un caractère de fin de chaîne ?
		breq	ExitLCDAfficheChaine				; 	- Oui, alors on sort
		cpi		Char,FinLigne						; 	- Non, mais est-ce un saut de ligne ?
		breq	LCDNewLine							;		- Oui, alors on saute à la ligne
		rcall	DisplayWriteChar					; 		- Non, alors on écrit le caractère
		rjmp	LCDNextChar							; 		  et on passe au caractère suivant

LCDNewLine:
		ldi		Work,0x40							; Place le curseur au début de la seconde ligne
		rcall 	DisplayPlaceCurseur						;
		rjmp	LCDNextChar							; et passe au caractère suivant

ExitLCDAfficheChaine:

		pop		ZH									; Récupère l'adresse de début de chaîne
		pop		ZL									; qu'on avait stockée au début
		pop 	Char								; Restaure le registre Char

		ret											; et on s'en va

; -------------------------------------------------------
; --- Affichage d'une chaine de caractères sur le LCD ---
; --- La chaine est en RAM...                         ---
; -------------------------------------------------------

DisplayAfficheChaineRAM:

		push	Char								; Sauvegarde le registre caractère
		push	ZL									; Sauvegarde l'adresse de début de la chaîne
		push	ZH									; pour pouvoir s'en reservir à la sortie 

LCDNextCharRAM:
		ld		Char,Z+								; Charge le caractère à l'adresse contenue dans le registre char,
													; et on incrémente l'adresse mémoire dans Z
		cpi		Char,FinChaine						; Est-ce que c'est un caractère de fin de chaîne ?
		breq	ExitLCDAfficheChaineRAM				; 	- Oui, alors on sort
		cpi		Char,FinLigne					; 	- Non, mais est-ce un saut de ligne ?
		breq	LCDNewLineRAM						;		- Oui, alors on saute à la ligne
		rcall	DisplayWriteChar					; 		- Non, alors on écrit le caractère
		rjmp	LCDNextCharRAM						; 		  et on passe au caractère suivant

LCDNewLineRAM:
		ldi		Work,0x40							; Place le curseur au début de la seconde ligne
		rcall 	DisplayPlaceCurseur						;
		rjmp	LCDNextCharRAM							; et passe au caractère suivant

ExitLCDAfficheChaineRAM:

		pop		ZH									; Récupère l'adresse de début de chaîne
		pop		ZL									; qu'on avait stockée au début
		pop 	Char								; Restaure le registre Char
		ret											; et on s'en va

; ---------------------------------------------------------------
; -- Effacement de la première ou seconde ligne de l'afficheur --
; ---------------------------------------------------------------

DisplayEffacePremiereLigne:

		clr		Work								; Curseur en début de première ligne
		rjmp	LCDEfface							; et efface la ligne

LCDEffaceSecondeLigne:								; Point d'entrée pour l'effacement de la seconde ligne

		ldi		Work,0x40							; se place en début de seconde ligne

LCDEfface:
		push	Work								; sauvegarde l'adresse du début de ligne
		rcall 	DisplayPlaceCurseur						; Place le curseur en début de ligne

		ldi		Char,32								; Un blanc pour l'effacement
		ldi		Count1,0
LoopLine:
		rcall 	DisplayWriteChar					; écrit le blanc
		inc		Count1
		cpi		Count1,DisplaySize					; fin de ligne ?
		brne	LoopLine							; nan

		pop		Work								; On récupère l'adresse du début de ligne
		call	DisplayPlaceCurseur					; Et on replace le curseur en début de ligne

		ret											; fin de routine

; -----------------------------------------
; -- Affiche les flèches pour l'encodeur --
; -----------------------------------------

DisplayArrow:

		ldi		Work,0x40							; Première position
		rcall	DisplayPlaceCurseur					; seconde ligne

		ldi		Char,5								; Flèche vers la gauche
		rcall	DisplayWriteChar

		ldi		Work,0x40							; Seconde ligne
		subi	Work,-(DisplaySize-1)
		rcall	DisplayPlaceCurseur					; dernière position

		ldi		Char,4								; Flèche vers la droite
		rcall	DisplayWriteChar		

		ret											; finito

; ------------------------------------------------
; -- Ecriture des caractères accentués en CGRAM --
; ------------------------------------------------

DisplayCGRamDefaut:

; -- Le "é" --

		ldi		Work1,EE_Eaigu						; L'adresse en EEPROM de la définition du caractère
		ldi 	Work2,CGRam_Eaigu					; L'adresse en CGRAM pour l'afficheur (ici 1)
		call	DisplayWriteCGRAM					; et on envoie le bins dans l'afficheur


; -- Le "è" --

		ldi		Work1,EE_Egrave						; L'adresse en EEPROM de la définition du caractère
		ldi 	Work2,CGRam_Egrave					; L'adresse en CGRAM pour l'afficheur (ici 2)
		call	DisplayWriteCGRAM					; et on envoie le bins dans l'afficheur


; -- Le "ë" --

		ldi		Work1,EE_Etrema						; L'adresse en EEPROM de la définition du caractère
		ldi 	Work2,CGRam_Etrema					; L'adresse en CGRAM pour l'afficheur (ici 3)
		call	DisplayWriteCGRAM					; et on envoie le bins dans l'afficheur

; -- La flèche vers la droite --

		ldi		Work1,EE_FDroite					; L'adresse en EEPROM de la définition du caractère
		ldi 	Work2,CGRam_FDroite					; L'adresse en CGRAM pour l'afficheur (ici 4)
		call	DisplayWriteCGRAM					; et on envoie le bins dans l'afficheur


; -- La flèche vers la gauche --

		ldi		Work1,EE_FGauche					; L'adresse en EEPROM de la définition du caractère
		ldi 	Work2,CGRam_FGauche					; L'adresse en CGRAM pour l'afficheur (ici 5)
		call	DisplayWriteCGRAM					; et on envoie le bins dans l'afficheur


; -- Le "à" --

		ldi		Work1,EE_Agrave						; L'adresse en EEPROM de la définition du caractère
		ldi 	Work2,CGRam_Agrave					; L'adresse en CGRAM pour l'afficheur (ici 6)
		call	DisplayWriteCGRAM					; et on envoie le bins dans l'afficheur


; -- Le Smiley --

		ldi		Work1,EE_Smile						; L'adresse en EEPROM de la définition du caractère
		ldi 	Work2,CGRam_Smile					; L'adresse en CGRAM pour l'afficheur (ici 7)
		call	DisplayWriteCGRAM					; et on envoie le bins dans l'afficheur

		ret

; -----------------------------------------------------------------------
; --- Ecrit un caractère utilisateur dans la RAM graphique du LCD     ---
; --- à l'adresse 0 pour le BarGraph                                  ---
; --- La valeur est dans le registre Char                             ---
; -----------------------------------------------------------------------

DisplayWriteBarGraph:

		push	Work2								; Sauvegarde Work2

		ldi 	Count1,8							; 8 lignes à écrire
		ldi		Work2,0								; Adresse 0 en CGRAM

		ldi		ZH,RAM_Bar_H
		ldi		ZL,RAM_Bar_L

LCDBoucleCarBG:
		ld		Char,Z+
		mov		Work,Work2							; Copie l'adresse CGRAM dans Work
		sbr		Work,0b01000000						; Pour indiquer une adresse CGRAM, met le bit 6 à 1
		cbr		Work,0b10000000						; et le bit 7 à zéro
		rcall	LCDSendCommand						; Envoie l'instrucution au VFD
		rcall 	LCDTestBusyFlag						; et attend la fin de commande

		rcall	LCDSendData							; On envoie la valeur à l'afficheur
		rcall 	LCDTestBusyFlag						; et on attend la fin de commande

		inc		Work2								; Incrémente l'adresse en CGRAM
		dec		Count1								; décrémente le compteur de ligne 
		cpi		Count1,0							; Derdesder ?	
		breq	ExitLCDWriteBG						;   Vi, on sort
		rjmp	LCDBoucleCarBG						;   Nan, on boucle 

ExitLCDWriteBG:
		pop		Work2								; Restore Work2
		ldi		ZH,RAM_Start
		ret											; On a fini

