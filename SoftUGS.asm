; =============================
; ==                         ==
; == Le coeur du cerveau :o) ==
; ==                         ==
; =============================

;#define FLAT							; -- Pour bibi : ATMega64, Optrex et pas de bypass
;#define ATMEGA64_OPTREX				; -- Pour Marco & Alex : ATMega64, Optrex et bypass
;#define ATMEGA64_CRYSTALFONTZ			; -- Pour la majorit� : ATMega64, CrystalFontz et bypass
;#define ATMEGA64_CRYSTALFONTZ_ALDO		; -- Pour Aldo : comme au-dessus, mais petite modif telco
;#define ATMEGA64_CRYSTALFONTZ_MFC		; -- Pour Manu : Petite modif sur des pinoches d'entr�e sortie
#define ATMEGA128_CRYSTALFONTZ			; -- Pour Trung : Un ATMega128 � la place du 64
;#define ATMEGA64_VFD					; -- ATMega64 et afficheur VFD Noritake, avec Bypass
;#define ATMEGA64_VFD_NEWHAVEN			; -- ATMega64 et afficheur VFD Newhaven, avec Bypass
;#define ATMEGA64_VFD_ALDO				; -- Le m�me, avec modif t�l�commande pour Aldo
;#define ATMEGA128_VFD					; -- N'existe pas encore, mais ATMega128, Afficheur VFD et Bypass
;#define ATMEGA128_VFD_NEWHAVEN			; -- N'existe pas encore, mais ATMega128, Afficheur VFD Newhaven et Bypass



; -- Pour bibi : ATMega64, Optrex et pas de bypass

#if defined(FLAT)

#define M64								; Pour un ATmega64
#define LCD

#endif

; -- Pour Marco & Alex : ATMega64, Optrex et bypass

#if defined(ATMEGA64_OPTREX)

#define M64								; Pour un ATmega64
#define LCD
#define BYPASS

#endif

; -- Pour la majorit� : ATMega64, CrystalFontz et bypass

#if defined(ATMEGA64_CRYSTALFONTZ)

#define M64								; Pour un ATmega64
#define LCD
#define CRYSTALFONTZ
#define BYPASS

#endif

; -- Pour Aldo : comme au-dessus, masi petite modif telco

#if defined(ATMEGA64_CRYSTALFONTZ_ALDO)

#define M64								; Pour un ATmega64
#define LCD
#define CRYSTALFONTZ
#define BYPASS
#define ALDO							; Sp�cial Landes

#endif

; -- Pour Manu : Petite modif sur des pinoches d'entr�e sortie

#if defined(ATMEGA64_CRYSTALFONTZ_MFC)

#define M64								; Pour un ATmega64
#define LCD
#define CRYSTALFONTZ
#define BYPASS
#define MFC

#endif

; -- Pour Trung : Un ATMega128 � la place du 64

#if defined(ATMEGA128_CRYSTALFONTZ)

#define M128							; Pour un ATmega128
#define LCD
#define CRYSTALFONTZ
#define BYPASS

#endif

#if defined(ATMEGA64_VFD)

#define M64								; Pour un ATmega64
#define VFD								; Afficheur VFD
#define NORITAKE						; de type Noritake
#define BYPASS

#endif

#if defined(ATMEGA64_VFD_ALDO)

#define M64								; Pour un ATmega64
#define VFD								; Afficheur VFD
#define NORITAKE						; de type Noritake
#define BYPASS
#define ALDO

#endif

#if defined(ATMEGA64_VFD_NEWHAVEN)

#define M64								; Pour un ATmega64
#define VFD								; Afficheur VFD
#define NEWHAVEN						; de type Newhaven
#define BYPASS

#endif

#if defined(ATMEGA128_VFD)

#define M128							; Pour un ATmega128
#define VFD								; Afficheur VFD
#define NORITAKE						; de type Noritake
#define BYPASS

#endif

#if defined(ATMEGA128_VFD_NEWHAVEN)

#define M128							; Pour un ATmega128
#define VFD								; Afficheur VFD
#define NEWHAVEN
#define BYPASS

#endif

; == Les d�finitions pour l'ATmega64 (ou 128)

#if defined(M64)
#pragma AVRPART ADMIN PART_NAME ATmega64
#pragma AVRPART MEMORY INT_SRAM SIZE 4096
#pragma AVRPART MEMORY EEPROM 2048
#pragma AVRPART MEMORY PROG_FLASH 65536
.include "m64def.inc"
#endif
#if defined(M128)
#pragma AVRPART ADMIN PART_NAME ATmega128
#pragma AVRPART MEMORY INT_SRAM SIZE 4096
#pragma AVRPART MEMORY EEPROM 4096
#pragma AVRPART MEMORY PROG_FLASH 131072
.include "m128def.inc"
#endif


; == Les diff�rentes d�finitions dont on a besoin (registres, constantes, adresses, etc...)

.include "Definitions.asm"

; == Quelques Macro-Instructions

.MACRO MacroMuteOn
#if defined(MFC)
		lds		Work,PortRelaisMute
		cbr		Work,EXP2(RelaisMute)				; Passe le relais de mute � 0 (c'est mut� au repos)
		sts		PortRelaisMute,Work
#else
		cbi		PortRelaisMute,RelaisMute			; Passe le relais de mute � 0 (c'est mut� au repos)
#endif
.ENDM

.MACRO MacroMuteOff
#if defined(MFC)
		lds		Work,PortRelaisMute
		sbr		Work,EXP2(RelaisMute)				; Passe le relais de mute � 1 (La sortie devient active)
		sts		PortRelaisMute,Work
#else
		sbi		PortRelaisMute,RelaisMute			; Passe le relais de mute � 1 (La sortie devient active)
#endif
.ENDM

; ------------------------------
; --- Le contenu de l'EEPROM ---
; ------------------------------

.eseg                                   ; Segment en EEPROM           
.org 0                                  ; Commencer � l'adresse $0000 de l'EEPROM

;*** Table de conversion des nibbles du compteur, stock�e en EEPROM ***
;*** La valeur est en r�alit� l'adresse d'une valeur dans l'EEPROM  ***

tableconv:
; valeur en entr�e 0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
; Action           N  I  D  E  D  N  E  I  I  E  N  D  E  D  I  N
              .db  0, 1, 2, 3, 2, 0, 3, 1, 1, 3, 0, 2, 3, 2, 1, 0	; La valeur convertie
; N  = la position n'a pas chang� (0)
; I  = Incr�menter la position    (1)
; D  = D�cr�menter la position    (2)
; E  = Erreur, les deux bits ont chang� en m�me temps (3)

; **********************************************************
; ***                                                    ***
; *** Les adresses suivantes en EEPROM (commencent � 16) ***
; *** contiennent les pr�f�rences de l'utilisateur       ***
; ***                                                    ***
; *** en 16 -> Comportement des entr�es au d�marrage     ***
; ***          =0 Entr�e pr�d�finie                      ***
; ***          =1 Derni�re entr�e activ�e                ***
; ***                                                    ***
; *** en 17 -> Num�ro de l'entr�e � activer au Power On  ***
; ***                                                    ***
; *** en 18 -> Num�ro de l'entr�e � activer au repos     ***
; ***                                                    ***
; *** en 19 -> Comportement du volume au d�marrage :     ***
; ***          =0       -> Volume au minimum             ***
; ***          =1       -> Preset de volume              ***
; ***          =2       -> Dernier volume enregistr�     ***
; ***                                                    ***
; *** en 20 -> Soit la valeur du preset de volume,       ***
; ***          soit la valeur du dernier volume          ***
; ***                                                    ***
; *** en 21 -> Mode d'affichage du volume :              ***
; ***          0 ->Affichage en dB                       ***
; ***          1 ->Affichage en d�cimal (de 0 � 127)     ***
; ***          2 ->Affichage en binaire                  ***
; ***                                                    ***
; *** en 22 -> D�lai sur les relais de volume            ***
; ***                                                    ***
; *** en 23 -> D�lai de recollage des relais de volume   ***
; ***                                                    ***
; *** en 24 -> Valeur du Volume en Mute                  ***
; ***                                                    ***
; *** en 25 -> Valeur de la Balance (0 au centre)        ***
; ***                                                    ***
; *** en 26 -> Luminosit� de l'afficheur au d�marrage    ***
; ***                                                    ***
; *** en 27 -> Contraste de l'afficheur au d�marrage     ***
; ***                                                    ***
; *** en 28 -> Luminosit� de l'afficheur en mode idle    ***
; ***                                                    ***
; *** en 29 -> Valeur du TimeOut d'Idle                  ***
; ***                                                    ***
; *** en 30 -> Envoi (autre) ou non (0) d'un trigger     ***
; ***          sur la t�l�commande de l'entr�e 1         ***
; ***                                                    ***
; *** en 31 -> Envoi (autre) ou non (0) d'un trigger     ***
; ***          sur la t�l�commande de l'entr�e 2         ***
; ***                                                    ***
; *** en 32 -> Envoi (autre) ou non (0) d'un trigger     ***
; ***          sur la t�l�commande de l'entr�e 3         ***
; ***                                                    ***
; *** en 33 -> Envoi (autre) ou non (0) d'un trigger     ***
; ***          sur la t�l�commande de l'entr�e 4         ***
; ***                                                    ***
; *** en 34 -> Envoi (autre) ou non (0) d'un trigger     ***
; ***          sur la t�l�commande de l'entr�e 5         ***
; ***                                                    ***
; *** en 35 -> Envoi (autre) ou non (0) d'un trigger     ***
; ***          sur la t�l�commande des amplis            ***
; ***                                                    ***
; *** en 36 -> Envoi (autre) ou non (0) d'un trigger     ***
; ***          sur la t�l�commande de l'ampli casque     ***
; ***                                                    ***
; *** en 37 -> Entr�e 1 en XLR(0) ou RCA (autre)         ***
; ***                                                    ***
; *** en 38 -> Entr�e 2 en XLR(0) ou RCA (autre)         ***
; ***                                                    ***
; *** en 39 -> Entr�e 3 en XLR(0) ou RCA (autre)         ***
; ***                                                    ***
; *** en 40 -> Entr�e 4 en XLR(0) ou RCA (autre)         ***
; ***                                                    ***
; *** en 41 -> Entr�e 5 en XLR(0) ou RCA (autre)         ***
; ***                                                    ***
; *** en 42 -> Si Entr�e 1 en RCA,.......................***
; ***          augmenter vol de 6dB (1) ou Non (0)       ***
; ***                                                    ***
; *** en 43 -> Si Entr�e 2 en RCA, ......................***
; ***          augmenter vol de 6dB (1) ou Non (0)       ***
; ***                                                    ***
; *** en 44 -> Si Entr�e 3 en RCA,.......................***
; ***          augmenter vol de 6dB (1) ou Non (0)       ***
; ***                                                    ***
; *** en 45 -> Si Entr�e 4 en RCA,.......................***
; ***          augmenter vol de 6dB (1) ou Non (0)       ***
; ***                                                    ***
; *** en 46 -> Si Entr�e 5 en RCA,.......................***
; ***          augmenter vol de 6dB (1) ou Non (0)       ***
; ***                                                    ***
; *** en 47 -> Correction de volume sur entr�e 1         ***
; ***                                                    ***
; *** en 48 -> Correction de volume sur entr�e 2         ***
; ***                                                    ***
; *** en 49 -> Correction de volume sur entr�e 3         ***
; ***                                                    ***
; *** en 50 -> Correction de volume sur entr�e 4         ***
; ***                                                    ***
; *** en 51 -> Correction de volume sur entr�e 5         ***
; ***                                                    ***
; *** en 52 -> Acc�l�ration du volume � la t�l�comande   ***
; ***                                                    ***
; *** en 53 -> Nombre de pulses de l'encodeur            ***
; ***          avant une action effective                ***
; ***                                                    ***
; *** en 54 -> Extinction (autre) ou non (0)             ***
; ***          de la led "on" en mode Idle               ***
; ***                                                    ***
; **********************************************************

#if defined(LCD)
#if defined(CRYSTALFONTZ)
;   16 17 18 19 20 21 22  23 24  25 26  27 28 29 30 31
.db 0, 1 ,4, 1 ,63,0 ,195,32,128,0 ,222,14, 0,2 ,0 ,0
#else
;   16 17 18 19 20 21 22  23 24  25 26  27 28 29 30 31
.db 0, 1 ,4, 1 ,63,0 ,195,32,128,0 ,222,2, 21,1, 0 ,0
#endif
#endif

#if defined(VFD)
;   16 17 18 19 20 21 22  23 24  25 26 27 28 29 30 31
.db 0, 1 ,4, 1 ,63,0 ,195,32,128,0 ,3 ,0, 0, 1, 0 ,0
#endif

;   32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47
.db 0, 0, 0, 0, 1, 0, 0 ,0 ,1 ,1 ,1 ,1 ,1, 1, 1 ,0

;   48 49 50 51 52  53   54 55 56 57 58 59 60 61 62 63
.db 0, 0, 0, 0, 1, StEc, 0, 0, 0, 0 ,0 ,0 ,0 ,0 ,0 ,0 

; Les valeurs suivantes (commencent � l'adresse 64 en EEProm) contiennent les commandes IR RC5

;   64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79
#if defined (ALDO)
.db 5,12,54,16,17,33,32, 1, 2 ,3 ,4 ,5,52,50,28,36
#else
.db 16,12,13,16,17,27,26, 1, 2 ,3 ,4 ,56,32,33,7,0
#endif

; les valeurs des octets pour d�finir les caract�res accentu�s (Commence en 80)

; ASCII 0 (80)	(du vide condamn� � �tre remplac�) 
.db 0,0,0,0,0,0,0,0	

; ASCII 1 (88)
.db 0b00000010,0b00000100,0b00001110,0b00010001,0b00011111,0b00010000,0b00001110,0				; E accent aigu

; ASCII 2 (96)
.db 0b00001000,0b00000100,0b00001110,0b00010001,0b00011111,0b00010000,0b00001110,0				; E accent grave

#if defined (CRYSTALFONTZ)
; ASCII 3 (104)
.db 0b00001110,0b00001010,0b00001110,0b00000000,0b00000000,0b00000000,0b00000000,0				; Le caract�re "�"
#else
; ASCII 3 (104)
.db 0b00001000,0b00000100,0b00001110,0b00000001,0b00001111,0b00010001,0b00001111,0				; A accent grave
#endif

#if defined(LCD)
; ASCII 4 (112)
.db 0b00011000,0b00011100,0b00011110,0b00011111,0b00011111,0b00011110,0b00011100,0b00011000		; Fl�che vers la droite

; ASCII 5 (120)
.db 0b00000011,0b00000111,0b00001111,0b00011111,0b00011111,0b00001111,0b00000111,0b00000011		; Fl�che vers la gauche
#endif

#if defined(VFD)
; ASCII 4 (112)
.db 0b00011000,0b00011100,0b00011110,0b00011111,0b00011110,0b00011100,0b00011000,0				; Fl�che vers la droite

; ASCII 5 (120)
.db 0b00000011,0b00000111,0b00001111,0b00011111,0b00001111,0b00000111,0b00000011,0				; Fl�che vers la gauche
#endif

#if defined (CRYSTALFONTZ)
; ASCII 6 (128)
.db 0b00011111,0b00011111,0b00011111,0b00011111,0b00011111,0b00011111,0b00011111,0b00011111		; Le charact�re "Block"
#else
; ASCII 6 (128)
.db 0b00001010,0b00000000,0b00001110,0b00010001,0b00011111,0b00010000,0b00001110,0				; E tr�ma
#endif

; ASCII 7 (136)
.db 0b00000000,0b00001010,0b00000000,0b00000100,0b00010001,0b00001110,0b00000000,0				; Un petit Smiley ;)


; Les 5 lignes suivantes contiennent les intitul�s des entr�es (12 caract�res Max)
; Ils sont stock�s en EEPROM pour pouvoir �tre modifi�s
; 144 0123456789ABCDEF
.db  "Grammophone     "													; Entr�e 1
; 160 0123456789ABCDEF
.db  "Compact Disc    "													; Entr�e 2
; 176
.db  "DAC             "													; Entr�e 3
; 192
.db  "T.S.F.          "													; Entr�e 4
#if defined (BYPASS)
; 208
;   0123456789ABCDEF0123
.db  "Input N Bypassed"													; Bypass du preamp
#else
; 208
.db  "Tape Input      "													; Entr�e Tape
#endif

; Le message de bienvenue 

.org 0x0100
;    0123456789ABCDEF0123
.db "  UGS Preamp V2.01  ",FinLigne										; Ligne 1
;    0123456789ABCDEF0123
.db	"   Thanks Nelson   ",7,FinChaine									; Ligne 2

.org 0x0130
; Le message de fin 
;    0123456789ABCDEF0123
.db "  O mo thruaighe !  ",FinLigne										; Ligne 1
;    0123456789ABCDEF0123
.db " Tiaraidh an drasda ",FinChaine									; Ligne 2

.org 0x0160
;Le Message de Mute 
;    0123456789ABCDEF0123
.db "Ce silence est aussi",FinLigne
#if defined(CRYSTALFONTZ)
.db "sponsoris",130," par NP..",7,FinChaine
#else
.db "sponsoris",1," par NP..",7,FinChaine
#endif

; ===============================
; La zone de r�glages "User1" ;)
; ===============================

.org 0x0200
.db Vide											; Vide (0x0F) indique que rien n'a �t� sauv� ici 
													; il faut recopier l'EEPROM dans cette zone
													; pour sauvegarder les r�glages "utilisateurs"

; ===============================
; La zone de r�glages "User2" ;)
; ===============================

.org 0x0400
.db Vide											; Vide (0x0F) indique que rien n'a �t� sauv� ici 
													; il faut recopier l'EEPROM dans cette zone
													; pour sauvegarder les r�glages "utilisateurs"

; ==================================
; La zone de r�glages "Usine" ;)
; ==================================

.org 0x0600
.db Vide											; Vide (0x0F) indique qu'� la premi�re mise sous tension,
													; il faut recopier l'EEPROM dans cette zone
													; pour sauvegarder les r�glages "usine"
; ----------------------------
; --- Le code commence ici ---
; ----------------------------

.cseg
.org 0

; Les diff�rents Handlers d'interruption

		rjmp	Init								; Routine de reset

.org INT0addr
		rjmp	Power								; Routine pour l'interruption INT0 (Appui sur le bouton power)

.org INT1addr
		rjmp	IRRecInt							; Routine pour l'interruption INT1 (R�ception d'un ordre IR d'allumage)

.org INT2addr
		reti										; Routine pour l'interruption INT2

.org INT3addr
		reti										; Routine pour l'interruption INT3

.org INT4addr
		reti										; Routine pour l'interruption INT4

.org INT5addr
		reti										; Routine pour l'interruption INT5

.org INT6addr
		reti										; Routine pour l'interruption INT6

.org INT7addr
		reti										; Routine pour l'interruption INT7

.org OC2addr
		reti										; Timer 2 compare (unused)

.org OVF2addr
		rjmp	IRTimer								; Timer 2 overflow : Les timings de la r�c�ption RC5

.org ICP1addr
		reti										; Timer 1 capture (unused)

.org OC1Aaddr
		reti										; Timer 1 compare A (unused)

.org OC1Baddr
		reti										; Timer 1 compare B (unused)

.org OVF1addr
		rjmp	RelayTimer							; Timer 1 overflow : Le timing des relais d'entr�e et de mute

.org OC0addr
		reti										; Timer 0 compare (unused)

.org OVF0addr
		rjmp	DelayRelayMBB						; Timer 0 overflow : Le d�lai de MBB pour les relais de volume

.org SPIaddr
		reti										; SPI transfer complete (unused)

.org URXC0addr
		reti										; USART 0 RX complete (unused)

.org UDRE0addr
		reti										; USART 0 UDR empty (unused)

.org UTXC0addr
		reti										; USART 0 TX complete (unused)

.org ADCCaddr
		reti										; ADC complete (unused)

.org ERDYaddr
		reti										; EEPROM ready (unused)

.org ACIaddr
		reti										; Analog comparator (unused)

.org OC1Caddr
		reti										; Timer 1 compare C (unused)

.org ICP3addr
		reti										; Timer 3 capture (unused)

.org OC3Aaddr
		reti										; Timer 3 compare A (unused)

.org OC3Baddr
		reti										; Timer 3 compare B (unused)

.org OC3Caddr
		reti										; Timer 3 compare C (unused)

.org OVF3addr
		rjmp	MultiDelay							; Timer 3 overflow : Plusieurs utilisations

.org URXC1addr
		reti										; USART 1 RX complete (unused)

.org UDRE1addr
		reti										; USART 1 UDR empty (unused)

.org UTXC1addr
		reti										; USART 1 TX complete (unused)

.org TWIaddr
		reti										; Two-Wire serial interface (unused)

.org SPMRaddr
		reti										; SPM ready (unused)


.include "Interruptions.asm"


; =====================================
; == Routine d'interruption de reset ==
; =====================================

Init:

; --- Stack Pointer ---

        ldi     Work,low(RAMEND)            	    ; Charge le premier octet de l'adresse de fin de RAM dans Work
        out     SPL,Work                       		; Met cette valeur dans le stack pointer
        ldi     Work,high(RAMEND)               	; Charge le second octet
        out     SPH,Work                        	; 

; --- L'adresse haute (dont on ne sert pas - pour l'instant) de l'EEPROM ---

        clr     Work
        out     EEARH,Work
        
; --- Port A : Donn�es de volume + Mute ---

        ldi     Work,$FF                        	; Toutes les pins sont des sorties
        out     DDRA,Work                       	; 
		clr		VolRegG								; On met le volume au minimum
		out		PortVolume,VolRegG					; Le mute en profite �galement

; --- Port B : Switches et  encodeur -> C'est tout des entr�es ---

        clr     Work			                	; Tout le port B est en entr�e
        out     DDRB,Work                       	; 
        out     PORTB,Work                      	; et on profite pour d�sactiver les pull-ups sur les entr�es

; --- Port G : Relais bal/unbal,relais tape/bypass et alim -> tout des sorties ---
; --- On commence par celui-l� pour �viter les ronflettes

        ldi     Work,$FF                        	; Toutes les pins sont des sorties
		sts		DDRG,Work							; Syntaxe un peu sp�ciale (sts au lieu de out) car c'est un port �tendu (m�me chose pour le port F)

#if defined(BYPASS)
	    clr		Work								; Tout d�sactiv�,
		sbr		Work,EXP2(RelaisBypass)				; sauf le relais de bypass pour commencer
		sts		PortAutresRelais,Work				; (Bypass d�sactiv� quand le relais est activ�)
#endif

; --- Port C : Les relais des entr�es ---

        ldi     Work,$FF                        	; Toutes les pins sont des sorties
        out     DDRC,Work                       	; 
		ldi		Work,RelaisAllGND					; On active tous les relais de masse des entr�es
		out		PortRelaisIn,Work					; pour �viter de ronfler (enfin on esp�re)


; --- Port D : Switch On, R�ception RC5, et lecture trigger en entr�e ---
; ---          Latches Volume Droite et trigger out, et commande AD8402 en sortie ---

		ldi 	Work,0b11101100						; 1 pour les sorties, 0 pour les entr�es
		out		DDRD,Work
		clr		Work								; et on d�sactive les pullups
		out		PORTD,Work							; sur les entr�es de ce port
		
; --- Port E : Les 2 premiers bits en entr�e (MOSI et MISO sont sur un bateau),
; ---          les 3 lignes de commande de l'afficheur en sortie,
; ---          le switch de menu en entr�e, et le latch de volume et la loupiote de On en sortie
        
		ldi		Work,0b11011100						; 1 pour les sorties, 0 pour les entr�es
		out 	DDRE,Work							
		clr		Work
		out		PORTE,Work							; et pas de pullups

; --- Port F : Les bits de donn�es de l'afficheur -> Entr�es/Sorties, mais pour l'instant, juste des sorties ---

		ldi		Work,$FF							; Syntaxe un peu sp�ciale pour les ports F et G de l'ATmega64
		sts		DDRF,Work							; utiliser sts/lds au lieu de out/in

; --- Pour les interruptions INT 0 et INT 1 ---

        clr     Work                            	; On inhibe les interruptions externes.....
        out     EIMSK,Work                      	; par mesure de pr�caution avant de changer leur mode de d�clenchement

		clr		Work								; Configure les interuptions pour un niveau 0 
		sts 	EICRA,Work							; pour les deux (sts au lieu de out)

        ldi     Work,0b00010000                 	; Autorise le Sleep Mode en PowerDown 
        out     MCUCR,Work                      	; + les interruptions externes
 
        ldi     Work,0b00000011                 	; On r�autorise seulement les 2 interruptions externes INT 1 et INT 0
        out     EIMSK,Work                      	; (Enable Interrupt Mask)

; --- Pour les timers ---

        ldi     Work,TimerStop
        out     TCCR0,Work                      	; On arr�te le timer 0
        out     TCCR1A,Work                     	; On arr�te le timer 1
        out     TCCR1B,Work
        sts     TCCR1C,Work
        out     TCCR2,Work                      	; On arr�te le timer 2
        sts     TCCR3A,Work                     	; On arr�te le timer 3
        sts     TCCR3B,Work
        sts     TCCR3C,Work

        
        ldi     Work,0b01000101                 	; On autorise les interruptions par overflow
        out     TIMSK,Work                      	; sur les timers 0,1 & 2
		ldi 	Work,0b00000100						; et aussi sur le timer 3
		sts		ETIMSK,Work

		clr		Work								; Interdit le mode asynchrone
		out		ASSR,Work							; sur les timers

; --- Switch off le comparateur ---

        sbi     ACSR,ACD            	            ; Eteint le comparateur analogique pour �conomiser l'�nergie
		cbi		ACSR,ACIE							; C'est vrai, �a... Pas la peine de faire chauffer la b�te inconsid�r�ment :o)

; --- M�me chose pour le convertisseur A/D ---

#if defined(M64)
		cbi		ADCSRA,ADEN							; Eteint le convertisseur Analogique/digital
		cbi		ADCSRA,ADIE
#endif

#if defined(M128)
		cbi		ADCSR,ADEN							; Eteint le convertisseur Analogique/digital
		cbi		ADCSR,ADIE
#endif

		sbi		PortAD8402,CS_AD8402				; D�sactive le ChipSelect de l'AD8402

	    clr		IRSup								; Vide le registre IR sb�zial

; -- On r�cup�re les �lements en EEPROM qui vont permettre de r�veiller la bestiole par IR

RC5EEReadID:
		sbic	EECR,EEWE
		rjmp	RC5EEReadID
        clr     Work
        out     EEARH,Work
		ldi		Work1,EE_IRSytemID					; Ce qu'on cherche � atteindre en EEPROM
		out		EEARL,Work1							; 
	    sbi		EECR,EERE							; Pr�pare l'EEPROM � la lecture
		in		Work2,EEDR							; lit la valeur en EEPROM et la met dans un registre

		ldi		ZH,RAM_Start
		ldi		ZL,RAM_IRSytemID					; ID RC5 du syst�me
		st		Z,Work2								; sauvegard�e pour le r�veil

RC5EEReadOn:
		sbic	EECR,EEWE
		rjmp	RC5EEReadOn

        clr     Work
        out     EEARH,Work
		ldi		Work1,EE_IRStandbyOn				; Ce qu'on cherche � atteindre en EEPROM
		out		EEARL,Work1							; 
	    sbi		EECR,EERE							; Pr�pare l'EEPROM � la lecture
		in		Work2,EEDR							; lit la valeur en EEPROM et la met dans un registre

		ldi		ZH,RAM_Start
		ldi		ZL,RAM_IRStandbyOn					; Sauvergarde aussi
		st		Z,Work2								; la commande IR de mise en route

#if defined (BYPASS)
RC5EEReadBp:
		sbic	EECR,EEWE
		rjmp	RC5EEReadBp

        clr     Work
        out     EEARH,Work
		ldi		Work1,EE_IRInputBypass				; Ce qu'on cherche � atteindre en EEPROM
		out		EEARL,Work1							; 
	    sbi		EECR,EERE							; Pr�pare l'EEPROM � la lecture
		in		Work2,EEDR							; lit la valeur en EEPROM et la met dans un registre

		ldi		ZH,RAM_Start						; Et si besoin,
		ldi		ZL,RAM_IRInputBypass				; sauvergarde aussi
		st		Z,WOrk2								; la commande IR de bypass
#endif

; =======================================================================================
; == A la premi�re mise sous tension, recopie des param�tres "usine" stock�s en EEPROM ==
; == On recopie toute l'EEPROM de 0x0000 � 0x01FF en 0x0400-0x5FF                      ==
; =======================================================================================

; D�but de la zone d'�criture (0x0600)
		ldi		ZH,Default							; Adresse haute 
		clr 	ZL									; Adresse basse

; Lit d'abord le contenu de la premi�re adresse destin�e � l'�criture

CheckEEprom:
		sbic	EECR,EEWE							; Si EEWE n'est pas � 0
		rjmp	CheckEEprom							; on attend

		out     EEARL,ZL	  	                    ; On charge "l'adresse" pour l'EEPROM
		out		EEARH,ZH

		sbi		EECR,EERE							; Signale � l'EEPROM qu'on veut lire
													; (4 cycles d'horloge)
		in		Work,EEDR							; r�cup�re la donn�e

		cpi		Work,Vide							; Si l'adresse 0x0200 contient "Vide" (0x0F)
		brne	Main								; c'est qu'elle n'a pas �t� recopi�e				
													; On va donc le faire
; D�but de la zone de lecture (0x0000)
		clr		YL									; Adresse basse de lecture
		clr		YH									; Adresse haute de lecture

; Lecture de l'EEPROM

LoopReadEEpromInit:
		sbic	EECR,EEWE							; Si EEWE n'est pas � 0
		rjmp	LoopReadEEpromInit					; on attend

		out     EEARL,YL	  	                    ; On charge "l'adresse" pour l'EEPROM
		out		EEARH,YH
		sbi		EECR,EERE							; Signale � l'EEPROM qu'on veut lire
													; (4 cycles d'horloge)
		in		Work,EEDR							; r�cup�re la donn�e

; Ecriture dans la zone haute de l'EEPROM

	    cli											; inhibe les interruptions
LoopWriteEEpromInit:
        sbic    EECR,EEWE                   	    ; On attend que l'EEprom soit pr�te pour l'�criture
        rjmp    LoopWriteEEpromInit
        
		out     EEARL,ZL		                    ; On charge "l'adresse" pour l'EEPROM
		out		EEARH,ZH
		out     EEDR,Work	                        ; ainsi que la donn�e
        
        sbi     EECR,EEMWE                         	; Master Write Enable
        sbi     EECR,EEWE                         	; On �crit dans l'EEPROM (arr�te le CPU pendant 2 cycles)
	    sei											; R�autorise les interruptions

		adiw	YL,0x01								; Incr�mente les adresses de lecture
		adiw	ZL,0x01								; et d'�criture

		cpi		YH,Memory1							; Tant qu'on n'a pas atteint la fin de la zone de lecture
		brne	LoopReadEEpromInit					; On continue la boucle

LoopWriteEEpromInitEnd:
        sbic    EECR,EEWE                   	    ; On attend que l'EEprom soit pr�te pour l'�criture
        rjmp    LoopWriteEEpromInitEnd

; -- Termin� pour les initialisations

; *************************************************
; ***                                           ***
; *** Routine principale : Mise en route        ***
; ***                      T�l�commande externe ***
; ***                      Boucle principale    ***
; ***                      Arr�t du biniou      ***
; ***                                           ***
; *************************************************

Main:   cli                        	    	        ; Pour d�marrer, on interdit les interruptions
		clr		StatReg1							; Efface les deux registres d'�tat
		clr		StatReg2							; 
		sei											; Autorise les interruptions

#if defined(BYPASS)
		call	StartOrByeBypass					; On va configurer le relais de Bypass et l'entr�e bypass�e au repos
#endif

; -----------------------
; -- Boucle somnolente --
; -----------------------

Dodo :
		sbrs	StatReg2,FlagIRRec					; On a re�u une commande IR ?
		rjmp	WakeOnPowerSwitch					; 	- Non, alors on va voir si c'est le bouton On/StandBy qui nous a r�veill� 

													; 	- Oui, alors on va voir si c'�tait pour se r�veiller...
		ldi 	Work,1								; Pour la r�ception IR, on est oblig� de red�marrer le Timer 2 pour effectuer le d�codage
		out		TCCR2,Work							; D�marre le Timer 2 � CK (pas de prescaler) -> 1 cycle de comptage dure 250ns

		call	RecRC5								; On va voir quelle commande c'�tait

WakeOnPowerSwitch:

		sbrc    StatReg1,FlagPower	            	; On m'a r�veill� pour allumer le biniou ?
													; (On a appuy� sur le bouton de mise en route ou on a recu une commande infrarouge qui a r�veill� la b�te)
		rjmp	AllezDebout							; Ben oui, alors faut y aller, p�vre mortel..
#if defined (BYPASS)
		sbrc	StatReg2,FlagIRBypass				; Nan, c'est pas du power on, mais est-ce du bypass pour les triggers ?
		call	TrigAmps							; ben vi, alors on va lancer les triggers
PowRelease:											; Si jamais "le triggage" �tait command� par les boutons 
		sbis    PinSwitchOn,SwitchOn				; on attend le rel�chement du bouton de power on
		rjmp    PowRelease							; Sinon on boucle

#endif
													; Ben non, rien de tout �a, alors on retourne se coucher... Chouette.
		clr		Work								; Au cas o� on l'aurait d�marr�
		out		TCCR2,Work							; on arr�te le timer 2

		clr		StatReg1							; Efface les deux registres d'�tat
		clr		StatReg2							; 

        ldi     Work,0b00000011 	                ; On r�autorise seulement les 2 interruptions externes INT 1 et INT 0
        out     EIMSK,Work          	            ; (Enable Interrupt Mask)

		rjmp	Dodo								; et se rendort aussi sec...

; -----------------------------------------
; -- Le plus dur : la phase de r�veil... --
; -----------------------------------------

AllezDebout:

; -- On se r�veille en douceur

		ldi     Work,50		        				; On attend un petit peu avant de se lancer
Wait1:	dec     Work
		brne    Wait1

; ----------------------------------------------------------
; -- Pendant 2 secondes, on teste si on a un second appui --
; -- sur le bouton PowerOn, pour savoir si on allume les  --
; -- amplis ou bien seulement l'ampli casque              --
; ----------------------------------------------------------

		clr		Work
		ldi		ZH,RAM_Start
		ldi		ZL,RAM_Tempo
		st      Z,Work			        			; Stocke 0 en Ram (indicateur d'un second appui) 

        ldi     Work,DeuxSecHi                 	 	; On commence par fixer la p�riode de 2 secondes 
        sts     TCNT3H,Work	                		; 
        ldi     Work,DeuxSecLo                  	; Pour l'instant, les interruptions INT0 et INT1 sont inhib�es,
        sts     TCNT3L,Work                     	; on ne les autorisera qu'une fois les 2 secondes �coul�es

        sbr		StatReg2,EXP2(FlagWait)				; On met a 1 le flag d'attente dans le registre d'etat
                                                	; c'est lui qui va nous servir a tester la fin des 2 secondes

        ldi     Work,TimerDiv		     	    	; On d�marre le Timer 3 avec CK/1024
        sts     TCCR3B,Work                     	; et il va compter pendant 2 secondes
                                                	; le temps de voir si on appuie une seconde fois sur
                                                	; le bouton Power On
        
; -- On n'oublie pas d'autoriser les interruptions externes --

        ldi     Work,0b00000011                 	; On autorise les interruptions externes INT 0 et INT1 
        out     EIMSK,Work                      	; (Enable Interrupt Mask)

; --------------------------------------------------------------------------------------
; -- On commence par fixer la luminosit� au minimum avant l'alimentation du backlight --
; -- pour �viter un "flash" au d�marrage                                              --
; --------------------------------------------------------------------------------------

#if defined(LCD)
		ldi		Work,ContrasteMaxi					; Contraste au mini
		call	SetContrast							; On envoie �a 

		ldi		Work,0								; Luminosit� � 0
		call	SetBrightness						; On envoie �a au potar num�rique
#endif
		 
; -- On alimente les relais et la Led de Power On

		lds		Work,PortRelaisAlim
		sbr		Work,EXP2(RelaisAlim)				; C'est un port �tendu, alors on utilise la m�thode alternative...
		sts		PortRelaisAlim,Work					; On fait attention de conserver le bypass en �tat (il est sur ce port)

		rcall	Attendre							; On attend qq dizaines de ms avant de passer � la suite
#if defined(VFD)
	    rcall	Attendre
#endif
		sbi		PortLedOn,LedOn						; Et on allume la Led

#if defined(BYPASS)
;		clr		Work								; On fait passer tous les relais d'entr�e
;		out		PortRelaisIn,Work					; au repos (on coupe tout) pour annuler le bypass
;
;		call	Attendre							; L�g�re attente...
;
;		lds		Work,PortAutresRelais				; R�cup�re l'�tat des autres relais
;		sbr		Work,EXP2(RelaisBypass)				; et d�sactive le relais de bypass
;		sts		PortAutresRelais,Work				; (Bypass d�sactiv� quand le relais est activ�)
#endif

; ================================
; === D�marrage de l'afficheur ===
; ================================

; --- On initialise l'afficheur

	    call	DisplayInit

; -- On �crit dans la RAM de l'afficheur pour d�finir les caract�res accentu�s

		call 	DisplayCGRamDefaut

; ==============================================================================================
; == Ensuite, on recopie en RAM les valeurs de config et les commandes RC5 qui sont en EEPROM ==
; ==============================================================================================

		call	EEPromToRam

; =====================================================
; == Son et lumi�re.... Mise en route de l'afficheur ==
; =====================================================

; -- On fixe le contraste

#if defined (LCD)
		ldi		Work,ContrasteMaxi					; R�cup�re la valeur stock�e en RAM dans Work
		call 	SetContrast							; et envoie �a sur le potar num�rique
#endif

; -- La lumi�re � z�ro --

#if defined(VFD)
		call	DisplayOff
#endif

		ldi		Work,0								; On commence � Z�ro
		call 	SetBrightness						; et envoie �a sur le potar num�rique
#if defined(VFD)
		call 	Attendre
#endif

; -- On affiche le message de bienvenue          --
; -- La luminosit� est au minimum pour l'instant --

		ldi		Work,0
		call	DisplayPlaceCurseur
		ldi		ZH,Ram_Start
		ldi		ZL,RAM_Welcome_M
		call	DisplayAfficheChaineRAM

		ldi		Work,0								; On commence � Z�ro
		call 	SetBrightness						; et envoie �a sur le potar num�rique

#if defined(VFD)
		call 	Attendre
		call 	DisplayOn
#endif

#if defined(LCD)
; -- On augmente progressivement le contraste

		ldi		ZH,RAM_Start						; Octet de poids fort de l'adresse de d�but en RAM 
		ldi		ZL,RAM_StartContrast				; L'adresse de ce param�tre en RAM

		ld		Work1,Z								; R�cup�re la valeur stock�e en RAM dans Work1
		ldi		Work,ContrasteMaxi					; Contraste minimum

BoucleStartContrast:
		call 	SetContrast							; et envoie �a sur le potar num�rique

		ldi		Count1,WaitBright
		rcall	MyWait								; Petite temporisation

		dec		Work								; Tant qu'on n'est pas arriv� au contraste final
		cpse	Work1,Work
		brne	BoucleStartContrast					; On boucle			
#endif

; -- On fixe la luminosit� du backlight de l'afficheur - La valeur est en RAM
; -- On d�marre de la luminosit� minimale pour augmenter vers la valeur finale

		ldi		ZH,RAM_Start						; Octet de poids fort de l'adresse de d�but en RAM 
		ldi		ZL,RAM_StartBrightness				; L'adresse de ce param�tre en RAM

		ld		Work1,Z								; R�cup�re la valeur stock�e en RAM dans Work1
		ldi		Work,0								; On commence � Z�ro

BoucleStartBrightness:
		call 	SetBrightness						; et envoie �a sur le potar num�rique

	    cpi		Work1,0								; Si Le brightness est � z�ro au d�part
		breq	SetStartBalance						; pas besoin d'augmenter... (Merci Philby ;) )

#if defined(LCD)
		mov		Count1,Work1
		sub		Count1,Work
		rcall	MyWait								; Petite temporisation
#endif
#if defined(VFD)
		ldi		Work2,VFDBrightDelayS
WaitVFD:
		rcall	Attendre							; Petite temporisation
		dec		Work2
		brne	WaitVFD
#endif

		inc		Work								; Tant qu'on n'est pas arriv� � la valeur finale,
		cpse	Work,Work1							; on augmente la luminosit�
		rjmp	BoucleStartBrightness				

		rcall 	SetBrightness						; et on a finalement atteint le max

; ==========================================================================================
; == Balance de volume et d�lai de MBB r�cup�r�s depuis la RAM et mis dans des registres  ==
; ==========================================================================================

SetStartBalance:

; --- On copie dans un registre la valeur de la balance qui est en RAM. Ca sera plus rapide pour la suite

		ldi		ZH,RAM_Start
		ldi		ZL,RAM_Balance						; Adresse de la valeur en RAM
		ld		BalanceReg,Z						; et on met la valeur dans le register BalanceReg

; --- Copie dans des registres des d�lais de potar pour le Make Before Break

		ldi		ZL,RAM_DelaiVolume					; Pointe sur la bonne adresse de Ram
		ld		DelayPot,Z							; et met �a dans le registre
		ldi		ZL,RAM_DelaiRecolleVol				; Pointe sur la bonne adresse de Ram
		ld		SeqMBB,Z							; et met �a dans le registre

; ===================================
; == Valeur du volume au d�marrage ==
; ===================================

; -- D'abord, initialisation de l'encodeur (Stockage de sa position initiale) ---

		call 	InitEncodeur

		ldi		ZH,RAM_Start
		ldi		ZL,RAM_StartVolume					; Adresse pour le comportement du volume au d�marrage
		ld		Work,Z								; et on r�cup�re la valeur

		cpi		Work,0								; Volume au minimum ?
		brne	VolTest								; 	- Non, alors on teste les autres possibilit�s
		clr		VolReg								; 	- Oui, alors on met le registre de volume au minimum
		rjmp	StartIns							; et passe � la suite

VolTest:
		ldi		ZH,RAM_Start
		ldi		ZL,RAM_VolumePreset					; Si on arrive l�, de toute fa�on, il faut consulter la valeur stock�e
		ld		VolReg,Z							; dans la valeur de preset (c'est soit un preset, soit la derni�re valeur de volume)
		
; ==================================================
; == Entr�e active au d�marrage et t�l�commandage ==
; ==================================================

StartIns: 

; -- On r�cup�re en RAM le num�ro de l'entr�e � activer � l'allumage
; -- Puis on envoie un trigger sur la t�l�commande de cette entr�e si n�cessaire
; -- Et finalement, on active le relais d'entr�e correspondant dans le preamp

		ldi		ZH,Ram_Start
		ldi		ZL,RAM_StartInput					; R�cup�re la valeur en RAM
		ld		Work1,Z

		ldi		ZH,RAM_Start
		ldi		ZL,RAM_AncienneEntreeActive			; On feinte pour les triggers
		ldi		Work,4								; en faisant croire que c'�tait l'entr�e tape/bypass qui �tait activ�e
		st		Z,Work								; et on met �a en RAM

		call	StartRelays
		call	Attendre							; Attend un peu avant de coller le relais de signal
		call	ActiveRelaisEntree					; et va activer le relais de l'entr�e s�lectionn�e

		call	SetBalance							; Modifie les registres droits et gauche en fonction de la balance
		call 	SetStartVolume						; et fixe le volume


; -------------------------------------------------------------------------------
; -- On va maintenant attendre l'overflow du Timer 3 (bit T de SREG passe � 0) --
; -- tout en testant si on a appuy� une deuxi�me fois sur le bouton Power On   --
; -------------------------------------------------------------------------------

WaitForT:
		sbrc	StatReg2,FlagWait					; Si le flag d'attente est � z�ro, on passe � la suite
        rjmp    WaitForT           		 	        ; Sinon, on continue la boucle

; ---------------------------------------------------               
; -- Les 2 secondes fatidiques sont �coul�es.      --
; -- On va donc t�l�commander l'ampli si besoin,   --
; -- activer le relais de sortie et finalement se  --
; -- lancer dans la boucle de scrutation           --
; ---------------------------------------------------               

InitTriggers:
		ldi		ZH,RAM_Start
		ldi		ZL,RAM_Tempo
        ld      Work3,Z						        ; On teste si on a appuy� deux fois
        cpi     Work3,0
        breq    TrigLesAmplis      		        	; Non, on t�l�commande l'ampli
		call	TrigLeCasque						; Oui, alors on adresse l'ampli casque				
		rjmp 	EnRoute

TrigLesAmplis:
	    call 	TrigAmps

; -- Derniers trucs avant la mise en route --

EnRoute:
		call	AfficheVolume						; Affichage du volume	 
		call	AfficheEntree						; Affichage de l'intitul� de l'entr�e

		clr		IdleCounter							; initialise le compteur d'Idle

		MacroMuteOff								; Passe le relais de mute � 1 (La sortie devient active)
		cbr		StatReg1,EXP2(FlagMute)				; Signale qu'on n'est plus en mute (bit � 0)

; -- On lance le timer 2 pour les timings IR

		ldi 	Work,1
		out		TCCR2,Work							; D�marre le Timer 2 � CK (pas de prescaler) -> 1 cycle de comptage dure 250ns

; -- Et puis le timer 3 pour le passage en mode Idle --

		call	StartIdle

; -- On n'oublie pas d'autoriser les interruptions externes --

        ldi     Work,0b00000011                 	; On autorise les interruptions externes INT 0 et INT1 
        out     EIMSK,Work                      	; (Enable Interrupt Mask)

		cbr		StatReg2,EXP2(FlagIRRec)			; R�initialise le Flag de r�ception IR	

		clr		IRSup								; Efface le registre de speedup

; ======================================================
; == Et c'est parti mon kiki...                       ==
; == La boucle principale qu'on va parcourir sans fin ==
; ======================================================

MainLoop:

; -- On v�rifie d'abord qu'on ne doit pas s'arr�ter --

        sbrs    StatReg1,FlagPower             		 ; Bit 0 de StatReg1 � 0 ?
        rjmp    FallAsleep                     		 ; Oui, alors on arr�te le biniou

; -- Si le flag de r�ception IR est positionn�, c'est qu'on a re�u une commande Infra-Rouge

		sbrc	StatReg2,FlagIRRec					; Flag de r�ception IR � 1 ?
		call	RecRC5								; 	- B� oui, alors on va ouar ce que c'est

        sbrs    StatReg1,FlagPower             		 ; Si jamais l'ordre IR �tait d'arr�ter le biniou
        rjmp    FallAsleep                     		 ; on y va imm�diatement

; -- Faut traiter les autres possibilit�s ?

#if defined (BYPASS)
		sbrc	StatReg2,FlagBypass					; Si on est en bypass, on ne peut pas faire autre chose
		rjmp	TestBypass							; que d'attendre un appui sur le bouton Bypass
#endif
		sbrc	StatReg2,FlagIRMute					; On ne peut faire les autres actions que si on n'a pas re�u une commande IR de Mute
		rjmp	Mainloop							; sinon, pas la peine d'aller plus loin

; -- Veut-on passer en mode menu ? --

		sbis	PinMenu,SwitchMenu					; Un appui sur le bouton de menu ?
		call	Menu								; Oui -> Alors on passe en mode menu
		sbrc	StatReg1,FlagMenu					; Revient-on d'une balade dans le menu ?
		rjmp	AfterMenu							; 	- Oui -> On finit le travail

; -- A-t-on appuy� sur un des boutons des entr�es ? --

		sbis	PinsSwitches,SwitchIn1				; On a appuy� sur l'entr�e 1 (actif � 0) ?
		rcall	ChangeEntree						; Oui, alors on y va

		sbis	PinsSwitches,SwitchIn2				; On a appuy� sur l'entr�e 2 (actif � 0) ?
		rcall	ChangeEntree						; Oui, alors on y va

		sbis	PinsSwitches,SwitchIn3				; On a appuy� sur l'entr�e 3 (actif � 0) ?
		rcall	ChangeEntree						; Oui, alors on y va

		sbis	PinsSwitches,SwitchIn4				; On a appuy� sur l'entr�e 4 (actif � 0) ?
		rcall	ChangeEntree						; Oui, alors on y va

TestBypass:
		sbis	PinsSwitches,SwitchTapeOrBypass		; On a appuy� sur le bouton Tape/Bypass (actif � 0) ?
#if defined (BYPASS)
		rcall	BypassOnOff							; Oui, alors on va voir le bypass o� qu'il en est
#else
		rcall	ChangeEntree						; Oui, alors on va chager d'entr�e pour tape
#endif

#if defined (BYPASS)
		sbrc	StatReg2,FlagBypass					; Si on est en bypass,
		rjmp	Mainloop							; on ne peut pas non plus toucher au volume
#endif

; -- On a touch� au volume ? --

		rcall 	LectureEncodeur						; Lecture de l'encodeur
		sbrs	StatReg1,FlagIncremente				; doit-on incr�menter le volume
		sbrc	StatReg1,FlagDecremente				; ou le d�cr�menter ?
		rcall	ChangeVolume						; l'un des deux...

		rjmp 	MainLoop							; et on boucle

; -- On remet tout comifo apr�s un passage dans le menu --

AfterMenu:
		cbr		StatReg1,EXP2(FlagMenu)				; On n'est plus en mode menu
		rcall	AfficheEntree						; alors on remet l'affichage
		rcall	AfficheVolume						; en mode normal,
		rcall	StartIdle							; On relance le timer de "fout rien"
		rjmp	MainLoop							; et on reboucle � l'envie

; ----------------------------------------- 
; -- On se pr�pare � arr�ter la bestiole --
; ----------------------------------------- 

FallAsleep:
        clr     Work			                 	; On inhibe les interruptions externes le temps de s'arr�ter
        out     EIMSK,Work                      	; (Enable Interrupt Mask)

        sbrc	StatReg1,FlagIdle					; Si le timer d'Idle �tait en train de tourner,
		rcall	StopIdle							; alors on l'arr�te
		rcall	RestoreBrightness					; Sinon, on remet l'afficheur en pleine luminosit�

GoToBed:

; -- On arr�te tous les timers

		ldi		Work,TimerStop
		out		TCCR0,Work							; On arr�te le Timer 0
		out		TCCR1B,Work							; On arr�te le Timer 1
		out		TCCR2,Work							; On arr�te le Timer 2
		sts		TCCR3B,Work							; On arr�te le Timer 3

; -- On affiche le message de fin --

		call	DisplayClear
		ldi		ZH,RAM_Start
		ldi		ZL,RAM_Bye_M
		call	DisplayAfficheChaineRAM

; -- On met le volume au minimum, puis on coupe la sortie --

		ldi		Work,0b10000000						; Pour ne pas couper la sortie (relais de mute reste activ�)

		out		PortVolume,Work						; Le volume sur le port des relais
		sbi		PortLatchVolG,LE_VolG				; Une impulsion pour le latch
		cbi		PortLatchVolG,LE_VolG

		out		PortVolume,Work						; Le volume de la voie droite sur le port des relais
		sbi		PortLatchVolD,LE_VolD				; Une impulsion pour le latch
		cbi		PortLatchVolD,LE_VolD

		rcall	Attendre							; on attend un petit peu
		MacroMuteOn									; Passe le relais de mute � 0 (Mut� au repos)
		rcall	Attendre

; -- On coupe les relais de Tape/Bypass et d'entr�e asym�trique

		lds		Work,PortRelaisAsym				
		cbr		Work,EXP2(RelaisAsym)
#if ! defined(BYPASS)
		cbr		Work,EXP2(RelaisTape)
#endif
		sts		PortRelaisAsym,Work

; -- On diminue progressivement la luminosit� de l'afficheur

		ldi		ZH,RAM_Start						; Octet de poids fort de l'adresse de d�but en RAM 
		ldi		ZL,RAM_StartBrightness				; L'adresse de ce param�tre en RAM

		ld		Work1,Z								; R�cup�re la valeur stock�e en RAM dans Work1

BoucleEndBrightness:
		mov		Work,Work1							; Transf�re dans le bon registre
		rcall 	SetBrightness						; et envoie �a sur le potar num�rique

		ldi		Count1,WaitBrightEnd
#if defined(LCD)
		rcall	MyWait								; Petite temporsiation
#endif
#if defined(VFD)
		ldi		Work2,VFDBrightDelay
WaitVFDBye:
		rcall	Attendre							; Petite temporisation
		dec		Work2
		brne	WaitVFDBye
#endif

		dec		Work1								; Tant qu'on n'est pas arriv� � une luminosit� de 0,
		brne	BoucleEndBrightness					; On la diminue				

		ldi		Work,0
		call	SetBrightness						; pour finalement arriver � 0

#if defined(LCD)
; -- On diminue progressivement le contraste

		ldi		ZH,RAM_Start						; Octet de poids fort de l'adresse de d�but en RAM 
		ldi		ZL,RAM_StartContrast				; L'adresse de ce param�tre en RAM

		ld		Work1,Z								; R�cup�re la valeur stock�e en RAM dans Work1

BoucleEndContrast:
		mov		Work,Work1							; Transf�re dans le bon registre
		rcall 	SetContrast							; et envoie �a sur le potar num�rique

		ldi		Count1,WaitBrightEnd
		rcall	MyWait								; Petite temporisation

		inc		Work1								; Tant qu'on n'est pas arriv� � un contrast min,
		cpi		Work1,ContrasteMaxi
		brne	BoucleEndContrast					; On la diminue				
#endif

; -- On va �teindre tous les appareils si ils �taient allum�s

		clr		Work								; Comptage des trigs � partir de 0
NextRC:
		rcall 	Attendre							; Petite attente pour la stabilit�
		out		PortAdresTrig,Work					; Met l'adresse des amplis sur le "bus"
		nop											; Petite attente de 500ns
		nop											; pour que tout soit stable
		sbis	PinTriggerIn,LectureTrigIn			; Si l'appareil �tait d�j� allum�,
		rjmp	FinRC								; Pas besoin de le refaire...
		sbi		PortTriggers,LatchTrigOut			; Sinon, on envoie un pulse de latch sur le 74HC238 de la t�l�commande

	    ldi		Work1,8
WaitByRC:
		call	Attendre							; Le temps que l'impulsion fasse effet
		dec 	Work1
		brne	WaitByRC

		cbi		PortTriggers,LatchTrigOut			; et toutes les sorties du HC238 retombent � z�ro
FinRC:
		inc		Work								; Incr�mente l'adresse
		cpi		Work,8								; Dernier appareil ?
		brne	NextRC								; 	- Non, on continue la boucle

; -- Si la politique de volume au d�marrage �tait de stocker le dernier volume, on va le faire --

		ldi		ZH,RAM_Start
		ldi		ZL,RAM_StartVolume
		ld		Work,Z								; R�cup�re cette politique 

		cpi		Work,2								; Faut stocker le volume ?
		brne	StoreInput							; 	- Non -> on va voir si il faut stocker l'entr�e

		sbrs	StatReg2,Flag6dB					;   - Oui, mais est-ce que ce volume �tait augment� de 6dB pour une entr�e asym�trique ? 
		rjmp	WriteEndVolume						; 		- Non, alors on le stocke directement

		ldi		Work,SixdBMore						; 		- Oui, alors faut les enlever
		cp		VolReg,Work							; 	  		si on peut...
		brge	Substract6dBEndVol					;     		et l�, on peut.
		clr		VolReg								; 			sinon on le met au min
		rjmp	WriteEndVolume						; 			et on passe � la suite

Substract6dBEndVol:
		sub		VolReg,Work							; On retranche les 6dB

WriteEndVolume:
		mov		Work2,VolReg						; On r�cup�re la valeur de volume dans Work2	
		ldi		Work,EE_VolumePreset				; et l'adresse en EEPROM
		rcall	WriteEEprom					

; -- Y Faut-y stocker l'entr�e active ?

StoreInput:

		ldi		ZH,RAM_Start
		ldi		ZL,RAM_StartInputBehave
		ld		Work,Z								; R�cup�re le comportement de l'entr�e au d�marrage 
	
		cpi		Work,0								; C'est une entr�e fixe ?
		breq	ByeBye								; 	- Oui -> On finit de finir

		ldi		ZH,RAM_Start						; 	- Nan -> On stocke l'entr�e actuellement en cours
		ldi		ZL,RAM_EntreeActive
		ld		Work2,Z								; Elle est l�

#ifndef BYPASS
		cpi		Work2,4								; C'est l'entr�e Bypass ?
		breq	ByeBye								; Vi, alors on stocke pas
#endif
		ldi		Work,EE_StartInput
		rcall	WriteEEprom							; Et on la met en EEPROM

; - On �teint l'afficheur et on coupe l'alim des relais --
 
ByeBye:
		call	DisplayOff

; -- Et finalement, on coupe le relais d'alim  et la led "On" --

		lds		Work,PortRelaisAlim				
		cbr		Work,EXP2(RelaisAlim)
		sts		PortRelaisAlim,Work

		cbi		PortLedOn,LedOn

; -- Et finalement, soit on s'occupe du bypass ou on coupe toutes les entr�es

#if defined (BYPASS)
		ldi		Work,RelaisAllGND					; On active tous les relais de masse des entr�es
		out		PortRelaisIn,Work					; pour �viter de ronfler (enfin on esp�re)
		call	StartOrByeBypass					; et on met le bypass si besoin
#else
		clr		Work
		out		PortRelaisIn,Work					; toutes les sorties � 0
#endif

; -- Et on s'endort compl�tement

FaisDodo:
	    clr		IRSup								; Vide le registre IR sp�cial

		clr		StatReg1							; efface les registres d'�tat
		clr		StatReg2							; 
        ldi     Work,0b00000011                 	; On r�autorise seulement les 2 interruptions externes INT 1 et INT 0
        out     EIMSK,Work                      	; (Enable Interrupt Mask)

		rjmp	Dodo								; Et on s'endort compl�tement...

; -- Chhhhhhhhhhuuuuuuutttttttt............

; ================================================================================================================================

; ==============================
; == Petites routines annexes ==
; ==============================

; -----------------------------------------------------
; - Envoi de triggers sur les amplis ou ampli casques - 
; -----------------------------------------------------
 
TrigAmps:

; -- Allumage de l'ampli ou de l'ampli casque --

; -- Avant d'envoyer l'impulsion d'allumage,
; -- on va interroger les amplis au cas o� ils seraient d�j� allum�s
; -- Si c'est le cas, pas la peine d'envoyer l'impulsion, sinon �a les �teindrait 

		ldi		Work, AdresseAmpliG					; Adresse de l'ampli de gauche
		out		PortAdresTrig,Work					; Met l'adresse des amplis sur le "bus"
		nop											; Petite attente de 500ns
		nop											; pour que tout soit stable
#if defined (BYPASS)
		sbrs    StatReg1,FlagPower	            	; Est-ce que le biniou est �teint ?
		rjmp	SendTAG								; Oui -> On n'interroge pas, on commute directement
#endif
		sbic	PinTriggerIn,LectureTrigIn			; Si l'ampli �tait d�j� allum�,
		rjmp	NextAmp								; Pas besoin de le refaire...
SendTAG:
		sbi		PortTriggers,LatchTrigOut			; Sinon, on envoie un pulse de latch sur le 74HC238 de la t�l�commande
		call 	Attendre
		cbi		PortTriggers,LatchTrigOut			; et toutes les sorties du HC238 retombent � z�ro

NextAmp:
		ldi		Work, AdresseAmpliD					; Adresse de l'ampli de droite
		out		PortAdresTrig,Work					; Met l'adresse des amplis sur le "bus"
		nop											; Petite attente de 500ns
		nop											; pour que tout soit stable
#if defined (BYPASS)
		sbrs    StatReg1,FlagPower	            	; Est-ce que le biniou est �teint ?
		rjmp	SendTAD								; Oui -> On n'interroge pas, on commute directement
#endif
		sbic	PinTriggerIn,LectureTrigIn			; Si l'ampli �tait d�j� allum�,
		ret											; Pas besoin de le refaire...
SendTAD:
		sbi		PortTriggers,LatchTrigOut			; Sinon, on envoie un pulse de latch sur le 74HC238 de la t�l�commande
		call 	Attendre
		cbi		PortTriggers,LatchTrigOut			; et toutes les sorties du HC238 retombent � z�ro

		ret											; et on passe � la suite

TrigLeCasque:
		ldi		Work, AdresseCasque					; Adresse de l'ampli casque
		out		PortAdresTrig,Work					; Met l'adresse des amplis sur le "bus"
		nop											; Petite attente de 500ns
		nop											; pour que tout soit stable
		sbic	PortTriggers,LectureTrigIn			; Si l'ampli �tait d�j� allum�,
		ret											; Pas besoin de le refaire...
		sbi		PortTriggers,LatchTrigOut			; Sinon, on envoie un pulse de latch sur le 74HC238 de la t�l�commande
		call 	Attendre
		cbi		PortTriggers,LatchTrigOut			; et toutes les sorties du HC238 retombent � z�ro

		ret

; -----------------------------------------------------------------------------
; -- D�marrage du Timer 3 pour la temporisation avant de passer en mode Idle --
; -----------------------------------------------------------------------------

StartIdle:

		sbrc	StatReg2,FlagIRMute					; Si on vient de passer en Mute, on ne lance pas l'Idle
		ret

		sbrc	StatReg1,FlagBalance				; Si on �tait en train de modifier la balance
		ret											; on ne le lance pas non plus

 		sbrs	StatReg1,FlagPower					; Si la bestiole �tait �teinte ou va s'�teindre, on ne s'occupe pas de l'Idle
		ret

		ldi		ZH,RAM_Start						; R�cup�re la dur�e du d�lai avant timeout
		ldi		ZL,RAM_IdleTimeOut					; 
		ld		Work,Z								; Et met �a dans un registre 

		cpi		Work,0								; Si la valeur n'est pas z�ro,
		brne	IdleOK								; On va lancer le compteur de timeout
		ret											; sinon, on s'en va
IdleOK:
		mov		IdleCounter,Work					; On transf�re la valeur dans le bon registre

WaitEndMBB:
		sbrc	StatReg2,FlagMBB					; Si jamais, on �tait en train d'attendre la fin d'un Make Before Break
		rjmp	WaitEndMBB							; On va laisser cette �tape se terminer...

        ldi     Work,QuinzeSecHi					; Quinze secondes de timeout pour le timer3
        sts     TCNT3H,Work							
		ldi		Work,QuinzeSecLo
        sts     TCNT3L,Work

		sbr		StatReg1,EXP2(FlagIdle)				; On positionne le flag qui indique qu'on est en train d'attendre

        ldi     Work,TimerDiv		        		; On d�marre le Timer 1 avec CK/1024
        sts     TCCR3B,Work                     	; et il va compter pendant � peu pr�s 15 secondes avant l'overflow
	
		ret

; -----------------------------------
; -- Arr�t du Timer 3 du mode Idle --
; -----------------------------------

StopIdle:

        ldi     Work,TimerStop						; On arr�te le Timer
 		sts		TCCR3B,Work
		
		cbr		StatReg1,EXP2(FlagIdle)				; On passe le flag � 0

		ret

; ------------------------------
; -- Petite routine d'attente --
; ------------------------------

Attendre:
        ldi     Count1,255
Wait3_0:ldi     Count2,255
Wait3_1:dec     Count2
        brne    Wait3_1
        dec     Count1
        brne    Wait3_0

		ret

; ======================================================
; == Routine d'attente un peu plus g�n�rale           ==
; == On charge	Count1 avce une valeur entre 0 et 255 ==
; ======================================================

MyWait:
		ldi     Count2,255
MyWait_1:
		dec     Count2
        brne    MyWait_1
        dec     Count1
        brne    MyWait

		ret

;===================================
; == Impulsion de trig des amplis ==
; ==================================

TrigWait:
		nop
		nop
		nop

		ret

; ************************************
; ***                              ***
; *** Routine d'�criture en EEprom ***
; ***                              ***
; *** L'adresse (basse) est dans   ***
; *** le registre Work             ***
; ***                              ***
; *** La donn�e est dans Work2     ***
; ***                              ***
; ************************************

WriteEEprom:
	    cli										; inhibe les interruptions
WaitWEEProm:
        sbic    EECR,EEWE                       ; On attend que l'EEprom soit pr�te pour l'�criture
        rjmp    WaitWEEProm

		out     EEARL,Work                      ; On charge "l'adresse" pour l'EEPROM
		out     EEDR,Work2                      ; ainsi que la donn�e
        
        sbi     EECR,EEMWE                      ; Master Write Enable
        sbi     EECR,EEWE                       ; On �crit dans l'EEPROM           

                                                ; (arr�te le CPU pendant 2 cycles)
	    sei										; R�autorise les interruptions
		ret                                     ; et on a fini
        

; ************************************
; ***                              ***
; *** Routine de lecture en EEprom ***
; ***                              ***
; *** L'adresse (basse) est dans   ***
; *** le registre Work             ***
; ***                              ***
; *** La donn�e est dans Work2     ***
; ***                              ***
; ************************************

ReadEEprom:
		sbic	EECR,EEWE						; Si EEWE n'est pas � 0
		rjmp	ReadEEprom						; on attend

		out     EEARL,Work                      ; On charge "l'adresse" pour l'EEPROM

		sbi		EECR,EERE						; Signale � l'EEPROM qu'on veut lire
												; (4 cycles d'horloge)
		in		Work2,EEDR						; r�cup�re la donn�e

		ret										; et ouali

; Routines pour l'AD8402 - Inutilis� avec un VFD
#if defined(LCD)
.include "AD8402.asm"
#endif

; Routines pour l'afficheur
#if defined (LCD)
.include "LCD.asm"
#else
.include "VFD.asm"
#endif

; Routines pour le contr�le de volume
.include "Volume.asm"

; Routines pour la lecture de l'encodeur rotatif
.include "Encodeur.asm"

; Routines pour la r�ception RC5
.include "RC5.asm"

; Routines pour la gestion des relais d'entr�e/sorties
.include "Inputs.asm"

; Routines d'affichage du volume et des intitul�s des entr�es
.include "Affichage.asm"

; Routines de conversion Binaire-BCD
.include "BinaireToBCD.asm"

; Routine de configuration de la bestiole
.include "Menu.asm"

; Les diff�rents messages � afficher
.include "Messages.asm"

