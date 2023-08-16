;****************************
;*** Param�tres �ditables ***
;****************************

.equ	DisplaySize		=20					; Taille de l'afficheur utilis� en nombre de caract�res (pour une ligne)

.equ	NameSize		=12					; La longueur du nom d'une entr�e.
											; Ne pas d�passer 16 (inclus) sinon plantage...
											; Normalement �gale � (DisplaySize - 8)
#ifdef BYPASS
.equ	MaxInput		=4					; Nombre d'entr�es � prendre en compte (Maximum=4)
#else
.equ	MaxInput		=5
#endif

; *****************************************************************************
; ***                                                                       ***
; ***   *****************************************************************   ***
; ***   *** NE PAS MODIFIER LA SUITE - OU A VOS RISQUES ET PERILS ;o) ***   ***
; ***   *****************************************************************   ***
; ***                                                                       ***
; *****************************************************************************

; *** Les diff�rents registres

.def	IRSup			=R0					; Registre qui contient les infos pour acc�lerer le volume � la telco
.def    SeqMBB       	=R1             	; D�lai de recollage des relais de volume
.def	DelayPot		=R2					; Contient la valeur du d�lai pour le Make Before Break du potar de volume

.def 	VolRegG			=R3					; Registre contenant le volume de la voie gauche
.def 	VolRegD			=R4					; Registre contenant le volume de la voie droite
.def	VolReg			=R5					; Le registre qui contient le volume "g�n�ral" (hors balance)
.def	BalanceReg		=R6					; Contient la valeur de la balance

.def	T_Inc			=R7					; Registre temporaire d'incr�mentation
.def	T_Dec			=R8					; Registre temporaire de d�cr�mentation
.def	IntTemp			=R9					; Registre temporaire pour les interruptions

.def	Ref1			=R10				; Deux registres de travail
.def	Ref2			=R11				; pour la r�ception IR

.def	MenuReg1		=R12				; Un registre pour les routines de menu
.def	MenuReg2		=R13				; et un second

.def	IdleCounter		=R14				; Compteur pour la mise en mode Idle
.def	Last			=R15				; Derni�re valeur de l'encodeur

; *** Les registres imm�diats

.def	StatReg1		=R16				; Registre contenant les diff�rents flags de status
.def	StatReg2		=R17				; Second registre de Status

.def	TimerIR_L		=R18				; Les registre de timers
.def	TimerIR_H		=R19				; pour la r�ception RC5											

.def 	CommandeIR		=R20				; Registre contenant la commande re�ue par RC5
.def 	SystemIR		=R21				; Registre contenant l'ID syst�me re�ue par le RC5 ($FF si rien re�u)

.def	Char			=R22				; Registre contenant le caract�re � afficher sur l'afficheur

.def	Work			=R23				; Registre temporaire de travail
.def	Work1			=R24				; Second registre temporaire de travail
.def	Work2			=R25				; Troisi�me registre temporaire de travail
.def	Work3			=R26				; Quatri�me registre temporaire de travail

.def    Count1        	=R27            	; Un compteur
.def    Count2        	=R28            	; Un autre compteur

.def	LSDVol			=R29				; Contient le chiffre des unit�s du volume
.def	MSDVol			=R30				; Contient le chiffre des dizaines du volume

; *** Les diff�rents bits du registre d'�tat (StatReg1)

.equ	FlagPower		=0					; Le flag de Power On (Bit 0 de StatReg1)
.equ	FlagBalance		=1					; Le flag de Balance - Indique qu'on est en mode d'affichage de balance (Bit 1 de StatReg1)
.equ	FlagMute		=2					; Le flag de Mute (Bit 2 de StatReg1)
.equ	FlagMenu		=3					; Le flag de passage en mode menu (Bit 3 de StatReg1)
.equ	FlagAsym		=4					; Le flag du relais de Bal/Unbal (� 1, indique qu'on est asym�trique en entr�e)
.equ	FlagDecremente  =5					; Le flag de d�cr�mentation encodeur
.equ	FlagIncremente	=6					; Le flag d'incr�mentation encodeur
.equ	FlagIdle		=7					; Le flag qui indique qu'on est en train d'attendre la fin du timeout d'idle

; *** Les diff�rents bits du second registre d'�tat (StatReg2)

.equ	FlagIRRec		=7					; Flag de r�ception IR
.equ	FlagIRBypass	=6					; Ordre IR de Bypass
.equ	FlagIRMute		=5					; Ordre IR de mute
.equ	FlagBypass		=4					; Etat du bypass
.equ	FlagMBB			=3					; Flag qui signale qu'on est en phase de MBB
.equ	Flag6dB			=2					; Signale qu'il faut augmenter le volume de 6dB (pour une entr�e asym�trique)
.equ	FlagWait		=1					; Flag pour indiquer une attente (alternative au bit "T")
.equ	FlagBlink		=0					; Flag pour le clignotement de l'afficheur

.equ	CodeCharMin		=1					; Code Ascii min des caract�res autoris�s
.equ	CodeCharMax		=253				; Code Ascii max des caract�res autoris�s

; *** Les diff�rents bits du registre IRSup

.equ	IRNewToggle		=7					; Le bit 7 de R0 (IRSup) contient le nouveau toggle de l'IR
.equ	IROldToggle		=6					; Le bit 6 de R0 (IRSup) contient l'ancien toggle de l'IR
.equ	IRVolUp			=5					; Bit 5 du m�me registre � 1 si on agit sur le volume up
.equ	IRVolDown 		=4					; Bit 4 du m�me registre � 1 si on agit sur le volume down
.equ	IRCountOn		=3					; Bit 3 � 1 signale que le timer a �t� lanc� pour un volume speedup
.equ	IRCountOver		=2					; Bit 2 � 1 signale que le temps fatidique est �coul� ;)
.equ	IRCountOverMore =1					; Bit 1 � 1 pour signaler qu'on peut encore acc�lerer 

; *** La d�finition des diff�rents ports d'entr�e sortie

; Le volume
.equ	PortVolume		=PORTA				; Port de sortie du Volume
.equ	PortLatchVolG 	=PORTE				; Ligne PE6
.equ	LE_VolG			=6					; pour le latch de volume Gauche
.equ	PortLatchVolD	=PORTD				; Ligne PD2
.equ	LE_VolD			=2					; pour le latch de Volume Droite
.equ	MasqueBalance	=0b00001111			; Seuls les 4 premiers bits de balance nous int�ressent
.equ	BalanceMaxi		=12
.equ	VolumeMaxi		=0b01111111			; La valeur maximale du volume
.equ	SixdBMore		=0b00001000			; 6dB de volume en plus ou en moins
.equ	EncoderStepMin	=1

; Les relais d'entr�e
.equ    PortRelaisIn	=PORTC				; Port de commande des relais d'entr�es
.equ	RelaisInput1	=6					; PC6 pour le relais de In1
.equ	RelaisGNDIn1	=7					; PC7 pour la masse de In1
.equ	RelaisInput2	=5					; PC5 pour le relais de In2
.equ	RelaisGNDIn2	=4					; PC4 pour la masse de In2
.equ	RelaisInput3	=2					; PC2 pour le relais de In3
.equ	RelaisGNDIn3	=3					; PC3 pour la masse de In3
.equ	RelaisInput4	=1					; PC1 pour le relais de In4
.equ	RelaisGNDIn4	=0					; PC0 pour la masse de In4

.equ	RelaisAllGND	=0b10011001			; Tous les relais de masse des entr�es
.equ 	RelaisOnlyGNDIn1=0b10000000			; Seulement le relais de la masse de l'entr�e 1
.equ 	RelaisOnlyGNDIn2=0b00010000			; Seulement le relais de la masse de l'entr�e 2
.equ 	RelaisOnlyGNDIn3=0b00001000			; Seulement le relais de la masse de l'entr�e 3
.equ 	RelaisOnlyGNDIn4=0b00000001			; Seulement le relais de la masse de l'entr�e 4

; Les autres relais
#if defined (MFC)
.equ    PortRelaisMute	=PORTG				; Port connect� au relais de mute
.equ	RelaisMute		=0					; PG0 pour la ligne de mute
#else
.equ    PortRelaisMute	=PORTA				; Port connect� au relais de mute
.equ	RelaisMute		=7					; PA7 pour la ligne de mute
#endif
.equ	PortRelaisAsym	=PORTG				; PG1 pour le relais
.equ	RelaisAsym		=1					; de Balanced/Unbalanced

#if defined (BYPASS)
#if defined (MFC)
.equ 	PortRelaisBypass=PORTG				; PG2 pour le relais
.equ 	RelaisBypass	=4					; de bypass
#else
.equ 	PortRelaisBypass=PORTG				; PG2 pour le relais
.equ 	RelaisBypass	=2					; de bypass
#endif
#else
.equ 	PortRelaisTape 	=PORTG				; PG2 pour le relais
.equ 	RelaisTape		=2					; de tape
#endif

.equ 	PortRelaisAlim	=PORTG				; PG3 pour le relais
.equ 	RelaisAlim		=3					; d'alim On/StandBy

.equ	PortAutresRelais=PORTG

; L'afficheur

#if defined(LCD)
.equ	DataDirLCD		=DDRF				; Registre de direction du port de donn�es LCD (Sur le port F)
.equ	PinsDataLCD		=PINF				; Port F pour les donn�es du LCD
.equ	PortDataLCD		=PORTF				; Port F pour les donn�es du LCD
.equ 	PortCmdLCD		=PORTE				; 3 lignes du port E pour la commande du LCD
.equ	RS_LCD			=2					; PE2 pour RS du LCD
.equ	RW_LCD			=3					; PE3 pour R/W du LCD
.equ	E_LCD			=4					; PE4 pour Enable du LCD
.equ	ContrasteMaxi	=30					; Valeur maximum du contraste (Les valeurs sup�rieures ne servent � rien)
.equ	WaitBright		=100				; Valeur pour la temporisation de variation de luminosit� au d�marrage
.equ	WaitBrightEnd	=50					; Valeur pour la temporisation de variation de luminosit� � l'arr�t
.equ	BrightnessMax	=255
#if defined(CRYSTALFONTZ)
.equ	BlockChar		=6					; Le caract�re "block" n'est pas d�fini dans le cas de CrystalFontz
#else
.equ	BlockChar		=255				; mais l'est pour les autres afficheurs
#endif

#endif

#if defined(VFD)
.equ	DataDirVFD		=DDRF				; Registre de direction du port de donn�es VFD (Sur le port F)
.equ	PinsDataVFD		=PINF				; Port F pour les donn�es du VFD
.equ	PortDataVFD		=PORTF				; Port F pour les donn�es du VFD
.equ 	PortCmdVFD		=PORTE				; 3 lignes du port E pour la commande du VFD
.equ	RS_VFD			=2					; PE2 pour RS du VFD
.equ	RW_VFD			=3					; PE3 pour R/W du VFD
.equ	E_VFD			=4					; PE4 pour Enable du VFD
.equ	ContrasteMaxi	=30					; Valeur maximum du contraste (Les valeurs sup�rieures ne servent � rien)
.equ	WaitBright		=255				; Valeur pour la temporisation de variation de luminosit� au d�marrage
.equ	WaitBrightEnd	=255				; Valeur pour la temporisation de variation de luminosit� � l'arr�t
.equ	VFDBrightDelay	=2
.equ	VFDBrightDelayS	=10
.equ	BrightnessMax	=3
.equ	BlockChar		=255
#endif

; La r�ception RC5
.equ	PinsRC5			=PIND				; L'entr�e RC5 est sur
.equ	InRC5			=1					; PD1 (INT1)

; Le potar num�rique AD8402
.equ	PortAD8402		=PORTD				; Il est sur le port D
.equ	SDI_AD8402		=5					; PD5 pour la ligne SDI
.equ	CLK_AD8402		=6					; PD6 pour la ligne CLK
.equ	CS_AD8402		=7					; PD7 pour la ligne /CS

; Les switches
.equ	PinMenu			=PINE				; Port E pour le switch de menu
.equ	SwitchMenu		=5					; (PE5)

.equ	PortSwitches	=PORTB				; Le port B pour les switches
.equ	PinsSwitches	=PINB				; et les pins en lecture directe
#if defined (LCD)
#if defined(CRYSTALFONTZ)
.equ	SwitchIn1		=5					; PB5 pour le switch Input 1
.equ	SwitchIn2		=4					; PB4 pour le switch Input 2
#else
.equ	SwitchIn1		=4					; PB4 pour le switch Input 1
.equ	SwitchIn2		=5					; PB5 pour le switch Input 2
#endif
#endif
#if defined(VFD)
.equ	SwitchIn1		=5					; PB5 pour le switch Input 1
.equ	SwitchIn2		=4					; PB4 pour le switch Input 2
#endif
.equ	SwitchIn3		=3					; PB3 pour le switch Input 3
.equ	SwitchIn4		=2					; PB2 pour le switch Input 4

.equ	SwitchTapeOrBypass	=0				; PB0 pour le switch de Tape/Bypass

.equ	PortSwitchOn	=PORTD				; PD0 (INT0) pour l'interrupteur de marche/arr�t
.equ 	PinSwitchOn		=PIND
.equ	SwitchOn		=0	
#if defined(BYPASS)
.equ 	PinSwitchMC		=PINB				; Le bouton d'annulation du menu (Menu Cancel)
.equ	SwitchMC		=0					; Ici, c'est le bouton de Bypass, mais on peut changer
#else
.equ 	PinSwitchMC		=PIND				; Le bouton d'annulation du menu (Menu Cancel)
.equ	SwitchMC		=0					; Ici, c'est le bouton de on/off, mais on peut changer
#endif
.equ 	PortLedOn		=PORTE				; La loupiote t�moin
.equ	LedOn			=7					; est sur PE7

; L'encodeur
.equ 	PortEncodeur	=PORTB				; Port B pour l'encodeur
.equ 	PinsEncodeur	=PINB
.equ	EncodeurA		=6					; PB6 pour un canal de l'encodeur
.equ 	EncodeurB		=7					; et PB7 pour l'autre
.equ	MasqueEncodeur	=0b11000000			; le masque de lecture de l'encodeur  

; Les triggers

.equ 	PortTriggers	=PORTD
.equ 	PinTriggerIn	=PIND
.equ 	LatchTrigOut	=3					; PD3 pour latcher la sortie des triggers
.equ 	LectureTrigIn	=4					; PD4 pour lire la valeur des triggers
.equ	PortAdresTrig	=PORTA				; PA0, PA1 & PA2 son les adresses des d�codeurs de triggers
.equ	AdresseAmpliG	=0					; Adresse du port de trigger de l'ampli de gauche
.equ	AdresseAmpliD	=1					; Adresse du port de trigger de l'ampli de droite
.equ	AdresseCasque	=2					; Adresse du port de trigger de l'ampli casque

; Les diff�rents param�tres pour les timers

.equ    TimerStop    =0                 	; Valeur pour arr�ter les timers
.equ    TimerDiv     =5                 	; Clock/1024
.equ	Timer0Div	 =0b00000100			; Clock/64 pour le timer 0 (16�s par it�ration)
.equ	TimerLed	 =4
.equ	TimerScroll	 =5
.equ	IdleCount	 =1						; Nombre de fois o� le timer d'Idle doit faire un overflow avant d'activer l'Idle

.equ    CinqSecHi    =$B1               	; avec ck/1024, a 4MHz, les timers sont incr�ment�s toutes les 256 us
.equ    CinqSecLo    =$E0               	; 5s # 20000 it�rations -> (65536-20000)=45536 -> $B1E0
.equ    TroisSecHi   =$D1               	; 3s # 11750 it -> (65536-11750)=53586 -> $D152
.equ    TroisSecLo   =$52
.equ    DeuxSecHi    =$E1               	; 2s # 7800 it -> (65536-7800)=57736 -> $E188
.equ    DeuxSecLo    =$88
.equ    UneSecEtDmHi =$E9 
.equ    UneSecEtDmLo =$1C
.equ    UneSecHi     =$F0               	; 1s # 3900 it -> (65536-3900)=61636 -> $F0C4
.equ    UneSecLo     =$C4
.equ    UneDemiSecHi =$F8               	; 0.5s # 1953 it -> 65536-1953=$F85F
.equ    UneDemiSecLo =$5F
.equ	QuinzeSecHi	 =$1B
.equ	QuinzeSecLo	 =$1D

; Adresses en EEProm des param�tres de configuration

.equ	EE_Start_Config		=16				; Adresse de d�but des param�tres de configuration en EEPROM

.equ	EE_StartInputBehave	=16				; Comportement de l'entr�e au d�marrage
.equ	EE_StartInput		=17				; Num�ro de l'entr�e activ�e au d�marrage
.equ	EE_In_Bypass		=18				; Num�ro de l'entr�e qui est en Bypass au repos
.equ	EE_StartVolume		=19				; Comportement du volume au d�marrage
.equ	EE_VolumePreset		=20				; Valeur du volume ua d�marrage
.equ	EE_AffichageVolume	=21				; Mode d'affichage du volume : dB(=0) normal - de 0 � 127 (=1) ou en binaire (=2)
.equ	EE_DelaiVolume		=22				; D�lai pour les relais de volume
.equ	EE_DelaiRecolleVol  =23				; D�lai pour le recollage des relais de volume
.equ	EE_MuteLevel		=24				; Niveau de volume pour un mute
.equ	EE_Balance			=25				; Adresse de la valeur de la balance (63=milieu)
.equ	EE_StartBrightness	=26				; Luminosit� du Backlight de l'afficheur au d�marrage
.equ	EE_StartContrast	=27				; Contraste de l'afficheur au d�marrage
.equ	EE_IdleBrightness	=28				; Luminosit� de l'afficheur en mode Idle
.equ	EE_IdleTimeOut		=29				; Valeur du Time Out d'Idle
.equ	EE_TrigIn1			=30				; Trigger sur l'entr�e 1 (> 0 = oui)
.equ	EE_TrigIn2			=31				; Trigger sur l'entr�e 2 (> 0 = oui)
.equ	EE_TrigIn3			=32				; Trigger sur l'entr�e 3 (> 0 = oui)
.equ	EE_TrigIn4			=33				; Trigger sur l'entr�e 4 (> 0 = oui)
.equ	EE_TrigIn5			=34				; Trigger sur l'entr�e 5 (> 0 = oui) (Normalement non utilis�)
.equ	EE_TrigAmps			=35				; Trigger sur les amplis (> 0 = oui)
.equ	EE_TrigHeadAmp		=36				; Trigger sur l'ampli casque (> 0 = oui)
.equ	EE_BalIn1			=37				; Entr�e 1 en sym�trique (> 0 = oui)
.equ	EE_BalIn2			=38				; Entr�e 2 en sym�trique (> 0 = oui)
.equ	EE_BalIn3			=39				; Entr�e 3 en sym�trique (> 0 = oui)
.equ	EE_BalIn4			=40				; Entr�e 4 en sym�trique (> 0 = oui)
.equ	EE_BalIn5			=41				; Entr�e 5 en sym�trique (> 0 = oui) (Normalement non utilis�)
.equ	EE_In1_6dB			=42				; Entr�e 1 +6dB si elle est en RCA (> 0 = oui)
.equ	EE_In2_6dB			=43				; Entr�e 2 +6dB si elle est en RCA (> 0 = oui)
.equ	EE_In3_6dB			=44				; Entr�e 3 +6dB si elle est en RCA (> 0 = oui)
.equ	EE_In4_6dB			=45				; Entr�e 4 +6dB si elle est en RCA (> 0 = oui)
.equ	EE_In5_6dB			=46				; Entr�e 5 +6dB si elle est en RCA (> 0 = oui) (Normalement inutilis�)
.equ	EE_ModVol_In1		=47				; Correction de volume sur entr�e 1
.equ	EE_ModVol_In2		=48				; Correction de volume sur entr�e 2
.equ	EE_ModVol_In3		=49				; Correction de volume sur entr�e 3
.equ	EE_ModVol_In4		=50				; Correction de volume sur entr�e 4
.equ	EE_ModVol_In5		=51				; Correction de volume sur entr�e 5 (Normalement inutilis�)
.equ 	EE_SpeedUp			=52				; Speedup du volume par t�l�comande IR
.equ	EE_EncoderStep	    =53				; Nombre de pulses de l'encodeur avant une action effective
.equ	EE_IdleLed			=54				; Extinction ou non de la Led On en mode Idle

.equ	EE_Stop_Config		=55				; Stoppe ici pour les param�tres en EEPROM

; Adresses en EEPROM des param�tres de t�l�commande IR

.equ	EE_Start_IR			=64				; Adresse en EEPROM du d�but des commandes RC5

.equ	EE_IRSytemID		=64				; Adresse du pr�amp en RC5
.equ	EE_IRStandbyOn		=65				; Commande IR Mise en route/Veille
.equ	EE_IRMute			=66				; Commande IR Mute
.equ	EE_IRVolumePlus		=67				; Commande IR Volume +
.equ	EE_IRVolumeMoins	=68				; Commande IR Volume -
.equ	EE_IRBalanceAGauche	=69				; Commande IR Balance vers la gauche
.equ	EE_IRBalanceADroite	=70				; Commande IR Balance vers la droite
.equ	EE_IRInput1			=71				; Commande IR S�lection entr�e 1
.equ	EE_IRInput2			=72				; Commande IR S�lection entr�e 2
.equ	EE_IRInput3			=73				; Commande IR S�lection entr�e 3
.equ	EE_IRInput4			=74				; Commande IR S�lection entr�e 4
#if defined (BYPASS)
.equ	EE_IRInputBypass	=75				; Commande IR S�lection Bypass
#else
.equ	EE_IRInputTape		=75				; Commande IR S�lection entr�e Tape
#endif
.equ	EE_IRBrightnessPlus	=76				; Commande IR Augmentation Luminosit� Backlight
.equ	EE_IRBrightnessMoins=77				; Commande IR Diminution Luminosit� Backlight
.equ	EE_IRContrastPlus	=78				; Commande IR Augmentation contraste Afficheur
.equ	EE_IRContrastMoins	=79				; Commande IR Diminution Contraste Afficheur

.equ	EE_Stop_IR			=80				; Stoppe ici pour les commandes IR en EEPROM
 
; Les Adresses en EEPROM des d�buts d'intitul� des entr�es et des messages �ditables

.equ	EE_Start_Label		=144			; Adresse de d�but en EEPROM des noms des entr�es
		
.equ	EE_TitreIn1			=144			; D�but en EEPROM de l'intitul� de l'entr�e 1
.equ	EE_TitreIn2			=160			; D�but en EEPROM de l'intitul� de l'entr�e 2
.equ	EE_TitreIn3			=176			; D�but en EEPROM de l'intitul� de l'entr�e 3
.equ	EE_TitreIn4			=192			; D�but en EEPROM de l'intitul� de l'entr�e 4
.equ	EE_TitreIn5			=208			; D�but en EEPROM de l'intitul� de l'entr�e 5 (Tape/Bypass)

.equ	EE_Stop_Label		=224			; Fin des intitul�s des entr�es en EEPROM

.equ	EE_Welcome_Hi		=$01			; Adresse haute du message de bienvenue
.equ	EE_Welcome_Lo		=$00			; Adresse basse du message de bienvenue

.equ	EE_Bye_Hi			=$01			; Adresse basse du message de fin
.equ	EE_Bye_Lo			=$30			; Adresse haute du message de fin

.equ	EE_Mute_Hi			=$01			; Adresse haute du message de mute
.equ	EE_Mute_Lo			=$60			; Adresse basse du message de mute

; Les adresses en EEPROM des caract�res accentu�s

.equ	EE_Eaigu	=88
.equ 	EE_Egrave	=96
.equ	EE_Etrema	=104
.equ	EE_FDroite	=112
.equ	EE_FGauche	=120 
.equ	EE_Agrave	=128
.equ	EE_Smile	=136 

; Les m�mes adresses, mais en CGRAM

.equ	CGRam_Eaigu		=8
.equ 	CGRam_Egrave	=16
.equ	CGRam_Etrema	=24
.equ	CGRam_FDroite	=32
.equ	CGRam_FGauche	=40 
.equ	CGRam_Agrave	=48
.equ	CGRam_Smile		=56 

; Les adresses correspondantes � tout �a en RAM

.equ	RAM_Start			=$01			; La RAM commence en $0100 sur ces �C

.equ	RAM_StartInputBehave=$00			; Comportement de l'entr�e au d�marrage
.equ	RAM_StartInput		=$01			; Num�ro de l'entr�e activ�e au d�marrage
.equ	RAM_In_Bypass		=$02			; Num�ro de l'entr�e qui est en Bypass au repos
.equ	RAM_StartVolume		=$03			; Comportement du volume au d�marrage
.equ	RAM_VolumePreset	=$04			; Valeur du volume ua d�marrage
.equ	RAM_AffichageVolume	=$05			; Mode d'affichage du volume : dB(=0) normal - de 0 � 127 (=1) ou en binaire (=2)
.equ	RAM_DelaiVolume		=$06			; D�lai pour les relais de volume
.equ	RAM_DelaiRecolleVol =$07			; D�lai pour le recollage des relais de volume
.equ	RAM_MuteLevel		=$08			; Niveau de volume pour un mute
.equ	RAM_Balance			=$09			; Adresse de la valeur de la balance (63=milieu)
.equ	RAM_StartBrightness	=$0A			; Luminosit� du Backlight de l'afficheur au d�marrage
.equ	RAM_StartContrast	=$0B			; Contraste de l'afficheur au d�marrage
.equ	RAM_IdleBrightness	=$0C			; Luminosit� de l'afficheur en mode Idle
.equ	RAM_IdleTimeOut		=$0D			; Valeur du Time Out d'Idle
.equ	RAM_TrigIn1			=$0E			; Trigger sur l'entr�e 1 (> 0 = oui)
.equ	RAM_TrigIn2			=$0F			; Trigger sur l'entr�e 2 (> 0 = oui)
.equ	RAM_TrigIn3			=$10			; Trigger sur l'entr�e 3 (> 0 = oui)
.equ	RAM_TrigIn4			=$11			; Trigger sur l'entr�e 4 (> 0 = oui)
.equ	RAM_TrigIn5			=$12			; Trigger sur l'entr�e 5 (> 0 = oui) (Inutilis�)
.equ	RAM_TrigAmps		=$13			; Trigger sur les amplis (> 0 = oui)
.equ	RAM_TrigHeadAmp		=$14			; Trigger sur l'ampli casque (> 0 = oui)
.equ	RAM_BalIn1			=$15			; Entr�e 1 en sym�trique (> 0 = oui)
.equ	RAM_BalIn2			=$16			; Entr�e 2 en sym�trique (> 0 = oui)
.equ	RAM_BalIn3			=$17			; Entr�e 3 en sym�trique (> 0 = oui)
.equ	RAM_BalIn4			=$18			; Entr�e 4 en sym�trique (> 0 = oui)
.equ	RAM_BalIn5			=$19			; Entr�e 5 en sym�trique (> 0 = oui) (inutilis�)
.equ	RAM_In1_6dB			=$1A			; Entr�e 1 +6dB si elle est en RCA (> 0 = oui)
.equ	RAM_In2_6dB			=$1B			; Entr�e 2 +6dB si elle est en RCA (> 0 = oui)
.equ	RAM_In3_6dB			=$1C			; Entr�e 3 +6dB si elle est en RCA (> 0 = oui)
.equ	RAM_In4_6dB			=$1D			; Entr�e 4 +6dB si elle est en RCA (> 0 = oui)
.equ	RAM_In5_6dB			=$1E			; Entr�e 4 +6dB si elle est en RCA (> 0 = oui) (Inutilis�)
.equ	RAM_ModVol_In1		=$1F			; Correction de volume de l'entr�e 1
.equ	RAM_ModVol_In2		=$20			; Correction de volume de l'entr�e 2
.equ	RAM_ModVol_In3		=$21			; Correction de volume de l'entr�e 3
.equ	RAM_ModVol_In4		=$22			; Correction de volume de l'entr�e 4
.equ	RAM_ModVol_In5		=$23			; Correction de volume de l'entr�e 5 (inutilis�)
.equ	RAM_SpeedUp			=$24			; Acc�l�ration du volume � la t�l�commande IR
.equ	RAM_EncoderStep		=$25			; Nombre de pulses de l'encodeur avant une action effective
.equ	RAM_IdleLed			=$26			; Extinction ou non de la led en mode Idle

; Adresses en RAM des param�tres de t�l�commande IR

.equ	RAM_IRSytemID			=$27		; Adresse du pr�amp en RC5
.equ	RAM_IRStandbyOn			=$28		; Commande IR Mise en route/Veille
.equ	RAM_IRMute				=$29		; Commande IR Mute
.equ	RAM_IRVolumePlus		=$2A		; Commande IR Volume +
.equ	RAM_IRVolumeMoins		=$2B		; Commande IR Volume -
.equ	RAM_IRBalanceAGauche	=$2C		; Commande IR Balance vers la gauche
.equ	RAM_IRBalanceADroite	=$2D		; Commande IR Balance vers la droite
.equ	RAM_IRInput1			=$2E		; Commande IR S�lection entr�e 1
.equ	RAM_IRInput2			=$2F		; Commande IR S�lection entr�e 2
.equ	RAM_IRInput3			=$30		; Commande IR S�lection entr�e 3
.equ	RAM_IRInput4			=$31		; Commande IR S�lection entr�e 4

#if defined (BYPASS)
.equ	RAM_IRInputBypass		=$32		; Commande IR S�lection Bypass
#else
.equ	RAM_IRInputTape			=$32		; Commande IR S�lection entr�e Tape
#endif

.equ	RAM_IRBrightnessPlus	=$33		; Commande IR Augmentation Luminosit� Backlight
.equ	RAM_IRBrightnessMoins	=$34		; Commande IR Diminution Luminosit� Backlight
.equ	RAM_IRContrastPlus		=$35		; Commande IR Augmentation contraste Afficheur
.equ	RAM_IRContrastMoins		=$36		; Commande IR Diminution Contraste Afficheur


; -- QQ adresses suppl�mentaires en RAM

.equ	RAM_EntreeActive		=$37		; Adresse contenant le num�ro de l'entr�e active
.equ	RAM_AncienneEntreeActive=$38		; Adresse contenant le num�ro de l'ancienne entr�e active
.equ	RAM_TempVolume			=$39		; Adresse contenant le niveau de volume (pour le mute)
.equ	RAM_Tempo				=$3A		; Une adresse multipurpose
.equ	RAM_TempChar			=$3B		; Stockage temporaire d'un caract�re
.equ	RAM_TitreActif			=$3C		; D�but de la chaine �dit�e stock�e en RAM (12 caract�res)

.equ	RAM_TitreIn1		=$50			; D�but en RAM de l'intitul� de l'entr�e 1
.equ	RAM_TitreIn2		=$60			; D�but en RAM de l'intitul� de l'entr�e 2
.equ	RAM_TitreIn3		=$70			; D�but en RAM de l'intitul� de l'entr�e 3
.equ	RAM_TitreIn4		=$80			; D�but en RAM de l'intitul� de l'entr�e 4
.equ	RAM_TitreIn5		=$90			; D�but en RAM de l'intitul� de l'entr�e 5 (Tape/Bypass)

.equ	RAM_Welcome_M		=$A0			; D�but en Ram des 2 lignes du message de bienvenue
.equ	RAM_Bye_M			=$CA			; D�but en Ram des 2 lignes du message de fin
.equ	RAM_Mute_M			=$F4			; D�but en Ram de la ligne du message de mute

.equ	RAM_Message_H		=$02			; Adresse de d�but du message �dit� (Octet poids fort)
.equ	RAM_Message_L		=$1E			; Octet poids faible

.equ	RAM_Bar_H			=$02			; Adresse haute en ram du caract�re de barres graphiques
.equ	RAM_Bar_L			=$60			; et son adresse basse
	
.equ	RAM_Encodeur_H		=$03			; Adresse haute en RAM du d�but de la table de d�codage de l'encodeur
.equ	RAM_Encodeur_L		=$00			; Adresse basse en RAM du d�but de la table de d�codage de l'encodeur (On est donc en 0x0300)

.equ	Memory1				=0x02			; Adresse haute de d�but en EEPROM de la zone "Memory 1" (0x0200) 
.equ	Memory2				=0x04			; Adresse haute de d�but en EEPROM de la zone "Memory 2" (0x0400)
.equ	Default				=0x06			; Adresse haute de d�but en EEPROM de la zone contenant les r�glages usine (0x0600) 
 
; -- QQ valeurs en plus
.equ	SaveLong	=32
.equ	SaveShort	=9
.equ	MuteLevelOff=128
.equ	Vide		=$0F

#if defined(VFD)
.equ	MaxDots		=7
.equ	MiDots		=3
#else
.equ	MaxDots		=8
.equ	MiDots		=4
#endif

#if defined (BYPASS)
.equ	IMM=1
#else
.equ	IMM=0
#endif

#if	defined(FLAT)
.equ	Stec		=4						; Le pas de l'encodeur
#else
.equ	Stec		=2
#endif

#if defined(CRYSTALFONTZ)
.equ	Nb			=3						; Le caract�re	"�"
#else
.equ	Nb			=0xDF
#endif

#if defined(CRYSTALFONTZ)
.equ	Fld			=0xC7					; la petite fl�che vers la droite
#else
.equ	Fld			=0x7E
#endif

.equ	FinChaine	=0xFF					; Fin de cha�ne d'affichage
.equ	FinLigne	=0xFE					; Fin de ligne d'affichage

