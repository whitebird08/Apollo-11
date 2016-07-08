# Copyright:	Public domain.
# Filename:	CM_ENTRY_DIGITAL_AUTOPILOT.agc
# Purpose:	Part of the source code for Colossus 2A, AKA Comanche 055.
#		It is part of the source code for the Command Module's (CM)
#		Apollo Guidance Computer (AGC), for Apollo 11.
# Assembler:	yaYUL
# Contact:	Ron Burkey <info@sandroid.org>.
# Website:	www.ibiblio.org/apollo.
# Pages:	1063-1092
# Mod history:	2009-05-13 RSB	Adapted from the Colossus249/ file of the
#				same name, using Comanche055 page images.
#		2009-05-20 RSB	Corrections: Removed an extraneous label 
#				EXDAPIN, added a missing instruction in 
#				COMPAT.
#
# This source code has been transcribed or otherwise adapted from digitized
# images of a hardcopy from the MIT Museum.  The digitization was performed
# by Paul Fjeld, and arranged for by Deborah Douglas of the Museum.  Many
# thanks to both.  The images (with suitable reduction in storage size and
# consequent reduction in image quality as well) are available online at
# www.ibiblio.org/apollo.  If for some reason you find that the images are
# illegible, contact me at info@sandroid.org about getting access to the 
# (much) higher-quality images which Paul actually created.
#
# Notations on the hardcopy document read, in part:
#
#	Assemble revision 055 of AGC program Comanche by NASA
#	2021113-051.  10:28 APR. 1, 1969  
#
#	This AGC program shall also be referred to as
#			Colossus 2A

# Page 1063
# SUBROUTINE TO READ GIMBAL ANGLES AND FORM DIFFERENCES.  GIMBAL ANGLES ARE SAVED IN 2'S COMPLEMENT, BUT THE
# DIFFERENCES ARE IN 1'S COMP.  ENTER AND READ ANGLES EACH .1 SEC.
#
#	CM/DSTBY = 1 FOR DAP OPERATION
#	CM/DSTBY = 0 TO TERMINATE DAP OPERATION

		BANK	15
		
		SETLOC	ETRYDAP
		BANK
		
		COUNT	15/DAPEN
		
		EBANK=	AOG
		
READGYMB	CA	TEN		# KEEP RESTART DT GOING RELATIVE TO
		ADS	CM/GYMDT	# PIPTIME.  (GROUP 6)
		
					# IF A RESTART OCCURS, SKIP PRESENT CYCLE.  THE
					# PHASCHNG PROTECTION IS IN CM/DAPIC.
					
		CA	BIT6		# CHECK FOR FINE ALIGN MODE OF CDU.
		MASK	IMODES33	# (PROTECT AOG/PIP ETC AS WELL AS
		EXTEND			# GIMBAL DIFFERENCES)
		BZF	READGYM1	# OK
		
		CS	BIT1		# NOT IN FINE ALIGN, SO IDLE
		MASK	CM/FLAGS	# SET GYMDIFSW = 0
		TS	CM/FLAGS
		TC	FLUSHJET	# QUENCH JETS, SINCE MAY BE A WHILE.
		TC	CM/GYMIC +2
		
READGYM1	CA	CDUX
		XCH	AOG
		EXTEND
		MSU	AOG		# -DELAOG=AOG(N-1) - AOG(N)
		TS	-DELAOG
		
		CA	CDUY
		XCH	AIG
		EXTEND
		MSU	AIG
		TS	-DELAIG
		
		CA	CDUZ
		XCH	AMG
		EXTEND
		MSU	AMG
		TS	-DELAMG

# Page 1064
DOBRATE?	CS	CM/FLAGS	# CM/DSTBY=103D BIT2  GYMDIFSW=104D BIT1
		MASK	THREE
		INDEX	A
		TC	+1
		TC	DOBRATE		# OK, GO ON
		TC	CM/GYMIC	# DON'T CALC BODYRATE ON FIRST PASS.
		NOOP
		TC	FLUSHJET	# TURN OFF ALL JETS
		
		TC	PHASCHNG
		OCT	00006		# DEACTIVATE DAP GROUP 6.
		
		TC	TASKOVER
		
DOBRATE		CA	ONE		# DO BODYRATE
DOBRATE1	TS	JETEM		# SKIP BODYRATE

		CA	TEN		# KEEP CDU READ GOING.
		TC	WAITLIST
		EBANK=	AOG
		2CADR	READGYMB
		
					# DOES NOT PROTECT TEMK, SQ IN SPSIN/COS
					
		CCS	JETEM
		TC	BODYRATE
		TC	TASKOVER	# SKIP CALC ON INITIAL PASS.  (PASSES)
		
CM/GYMIC	ADS	CM/FLAGS	# GYMDIFSW:  C(A)=1, KNOW BIT IS 0
		CAF	ZERO
		TS	JETAG
		TS	OLDELP
		TS	OLDELQ
		TS	OLDELR
		TS	GAMDOT		# NO GYM DIF, PROB NO GAM DIF.
		TC	DOBRATE1
		
# Page 1065
# COME HERE TO CORRECT FOR OVERFLOW IN ANGULAR CALCULATIONS

ANGOVCOR	TS	L		# THIS COSTS 2 MCT TO USE.
		TC	Q		# NO OVFL
		INDEX	A
		CAF	LIMITS
		ADS	L
		TC	Q
		
		BLOCK	3
		
		COUNT	03/DAPEN
		
FLUSHJET	CA	7		# COME HERE TO TURN OFF ALL JETS.
		EXTEND
		WRITE	ROLLJETS	# ZERO CHANNEL 6
		EXTEND
		WRITE	PYJETS		# ZERO CHANNEL 5
		TC	Q
		
		BANK	15
		
		COUNT	15/DAPEN
		
		SETLOC	ETRYDAP
		BANK
		
RATEAVG		COM			# SUBROUTINE TO ESTIMATE RATES IN PRESENCE
		AD	JETEM		# OF CONSTANT ACCELERATION.
		EXTEND
		MP	HALF		# DELV (EST) = DELV +(DELV-OLDELV)/2
		AD	JETEM
		TC	Q
		
# Page 1066
# THESE ARE CALLED FOR THE VARIOUS INITIALIZATIONS NEEDED.

		BANK	20
		SETLOC	DAPS1
		BANK
		
		COUNT	20/DAPEN
		EBANK=	AOG
		
CM/DAPON	CA	EBAOG
		TS	EBANK
		
		TC	DOWNFLAG	# RESET DAPBIT1.  T5 RESTART IDENTIFIER.
		ADRES	DAPBIT1		# BIT 15 FLAG 6		CMFLAGS.
		TC	DOWNFLAG	# RESET DAPBIT2
		ADRES	DAPBIT2		# BIT 14 FLAG 6
		EXTEND
		DCA	T5IDLER1	# DISABLE RCS CALCULATION
		DXCH	T5LOC
		EXTEND
		DCA	T5IDLER1	# DISABLE RCS JET CALLS
		DXCH	T6LOC
		
		TC	FLUSHJET	# JETS DEPARTED ON SM. ZERO JET BITS.
		
		CS	13,14,15
		MASK	DAPDATR1	# SET CONFIG BITS=0 FOR ENTRY
		TS	DAPDATR1
		TC	+4
		
NOTYET		CA	.5SEC
		TC	BANKCALL
		CADR	DELAYJOB	# (DELAYJOB DOES INHINT)
	+4	CA	BIT11		# GAMDIFSW = 94D BIT11, INITLY=0
		MASK	CM/FLAGS	# IF ZERO, WAIT UNTIL CM/POSE UPDATE.
		EXTEND
		BZF	NOTYET
		
		CS	ONE		# ACTIVATE CM/DAP
		TS	RCSFLAGS	# USE BIT3 TO INITIALIZE NEEDLER ON
					# NEXT PASS.
		TS	P63FLAG		# SO WAKEP62 WILL NOT BE INITIATED UNTIL
					# HEADSUP IS SET IN P62.
					
					# FLAG TO PREVENT MULTIPLE CALLS TO WAKEP62
					
		CA	7
		TS	JETAG
		TS	PAXERR1		# KEEP NEEDLES ZERO UNTIL DAP UPDATE
					# IN CASE CMDAPMOD IS NOT +1.
# Page 1067
		INHINT
		EXTEND
		DCA	ALFA/180	# DO ATTITUDE HOLD UNTIL KEYBOARD
		DXCH	ALFACOM		# ESTABLISHES HEADSUP.
		CA	ROLL/180
		TS	ROLLHOLD	# FOR ATTITUDE HOLD IN MODE +1.
		EXTEND
		MP	HALF
		TS	ROLLC		# NOT INTERESTED IN LO WORD.
		
		CS	CM/FLAGS
		MASK	BIT12		# CMDAPARM =93D BIT12  INITLY=0
		ADS	CM/FLAGS	# SET BIT TO 1.
		
		CS	FLAGWRD2	# SET  NODOFLAG  TO PREVENT FURTHER
		MASK	BIT1		# V 37 ENTRIES.
		ADS	FLAGWRD2
		
		RELINT
		
		TC	POSTJUMP
		CADR	P62.1
		
# Page 1068
# INITIALIZE CM/DAP.  WAITLIST CALL FOR READGYMB.  SET SWITCH CM/DSTBY =1
# SO READACCS WILL ENTER A WTLST CALL FOR  SETJTAG .
#  CMDAPARM  = 0, SO ONLY BODY RATE AND ATTITUDE CALCULATIONS ARE DONE.
# SET AVEGEXIT TO CONTINUE AT CM/POSE

CM/DAPIC	CA	EBAOG
		TS	EBANK
		
		INHINT
CM/DAP2C	CS	PIPTIME +1
					# PRIO OF P62 L PRIO AVG.:PIPTM=PIPTM1.
		TS	JETEM
		
		CA	POS1/2
		AD	POS1/2
		AD	TIME1		# OVFL GUARANTEED
		ADS	JETEM		# C(A) = DELTA TIME SINCE PIPUP
		
		CS	FIVE
		AD	JETEM
		CCS	A
		AD	-CDUT+1
		TCF	-2
		NOOP
		AD	ONE		# SEND NO ZERO TO WTLST
		TS	CM/GYMDT	# FOR RESTART
		TC	WAITLIST
		EBANK=	AOG
		2CADR	READGYMB
		
		CS	CM/SWIC1	# GAMDIFSW, GYMDIFSW, CM/DSTBY
		MASK	CM/FLAGS	# DAPARM, .05GSW, LATSW, ENTRYDSP
		AD	CM/SWIC2	# SET CM/DSTBY, LATSW
					# DISABLE ENTRY DISPLAY, SINCE DES. GIMB.
					# CALC.  (P62.3) GOES TO ENDEXIT
		TS	CM/FLAGS
		
		CA	7
		TS	BETA/180	# NECESSARY:  NO OVFL CORRECTIO
		CA	ONE		# INITIALIZE THE TM OF BODY RATES VIA
		TS	SW/NDX		# UPBUFF.
		
		TC	2PHSCHNG	# DOES INHINT/RELINT
		OCT	40116		# SAVE TBASE6
		OCT	05024
		OCT	13000
		
		TC	POSTJUMP
# Page 1069
		CADR	P62.2
		
CM/SWIC1	OCT	16017
CM/SWIC2	=	TEN		# 00012: CM/DSTBY, LATSW
-CDUT+1		OCT	77766
		EBANK=	T5LOC
T5IDLER1	2CADR	T5IDLOC

# Page 1070
# THIS SECTION CALCULATES THE ANGULAR BODY RATES EACH .1 SEC.  THE ANGULAR RATES ARE THOSE ALONG THE BODY AXES
# XB, YB, ZB, AND ARE NORMALLY DESIGNATED P, Q, R.	REQUIREMENT:  TEMPORARILY ERASE.  JETEM, JETEM +1
#
# SINCE RESTARTS ZERO THE JET OUTPUT CHANNELS, NO ATTEMPT IS MADE TO RESTART THE ENTRY DAPS.  THAT IS,
# THE 0.1 SEC DAPS WILL MISS A CYCLE, AND WILL PICK UP AT THE NEXT 0.1 SEC UPDATE.  MOST OF THE TIME THE 2 SEC
# ROLL SYSTEM WILL MISS ONLY 0.1 SEC OF CONTROL.  HOWEVER, IF THE RESTART OCCURS AFTER THE SECTION TIMETST HAS
# STARTED, THEN THE ROLL SYSTEM WILL MISS ONE CYCLE.
# THIS IS NECESSARY UNDER THE GROUND-RULE THAT NO JET COMMANDS SHALL BE LESS THAN 14 MS.

		EBANK=	AOG
		BANK	15
		SETLOC	ETRYDAP
		BANK
		
		COUNT	15/DAPEN
		
BODYRATE	CA	AMG		# THESE ARE 2'S COMPL NOS, BUT USE ANYWAY.
		TC	SPCOS
		TS	COSM
		
		CA	AOG		# C(AOG) = AOG/180
		TC	SPSIN		# SINO
		TS	SINO		# SINO = SIN(AOG)
		
		EXTEND
		MP	COSM
		TS	SINOCOSM	# SO CM
		
		CA	AOG
		TC	SPCOS		# COSO
		TS	COSO
		
		EXTEND
		MP	COSM
		TS	COSOCOSM	# CO CM
		
# PITCHDOT:  Q TCDU/180 = IDOT TCDU/180 COSO COSM + MDOT TCDU/180 SINO

		CS	-DELAMG
		EXTEND
		MP	SINO
		DXCH	JETEM		# 2 LOCS
		CS	-DELAIG
		EXTEND
		MP	COSOCOSM
		DAS	JETEM
		CA	JETEM
		XCH	OLDELQ
		TC	RATEAVG
		TS	QREL		# PITCHDOT = Q TCDU/180
		
# Page 1071
# YAWDOT:  R TCDU/180 = -IDOT TCDU/180 COSM SINO + MDOT TCDU/180 COSO

		CS	-DELAMG
		EXTEND
		MP	COSO
		DXCH	JETEM
		CA	-DELAIG
		EXTEND
		MP	SINOCOSM
		DAS	JETEM
		CA	JETEM
		XCH	OLDELR
		TC	RATEAVG
		TS	RREL		# YAWDOT = R TCDU/180
		
# ROLLDOT:  P TCDU/180 = ODOT TCDU/180 + IDOT TCDU/180 SINM

		CA	AMG
		TC	SPSIN
		TS	SINM
		
		EXTEND
		MP	-DELAIG
		TS	JETEM
		CA	ZERO
		DDOUBL			# ROUND L INTO A
		AD	-DELAOG
		AD	JETEM
		CS	A
		TS	JETEM
		XCH	OLDELP
		TC	RATEAVG
		TS	PREL		# ROLLDOT = P TCDU/180
		
					# IF GAMDOT < 0.5 DEG/SEC, THEN GAMDOT =0
					
		CCS	GAMDOT
		TC	+2
		TC	NOGAMDUT
		CS	ROLL/180
		TC	SPSIN
		EXTEND
		MP	GAMDOT
		TS	JETEM +1	# -SR GAMDOT
		EXTEND
		MP	SINTRIM		# SIN(-20)	(FOR NOMINAL L/D = .3)
		ADS	PREL		# PREL TCDU/180=(P-SALF SR GAMDOT)TCDU/180
		
		CA	ROLL/180
		TC	SPCOS
# Page 1072
		COM
		EXTEND
		MP	GAMDOT
		ADS	QREL		# QREL TCDU/180=(Q-CR GAMDOT) TCDU/180
		
		CS	JETEM +1	# B( ) = -SR GAMDOT
		EXTEND
		MP	COSTRIM		# COS(-20)	(FOR NOMINAL L/D = .3)
		ADS	RREL		# RREL TCDU/180=(R+CALF SR GAMDOT)TCDU/180
		
NOGAMDUT	CA	BIT12		# CMDAPARM = 93D BIT 12
		MASK	CM/FLAGS
		EXTEND
STBYDUMP	BZF	TASKOVER	# DAP NOT ARMED.

		CA	POSMAX		# PICK UP AT ATTRATES IN 10 MS OR SO.
		TS	TIME5
		
		EXTEND
		DCA	ATDOTCAD
		DXCH	T5LOC
					# DOES NOT PROTECT TEMK, SQ IN SPSIN/COS
					
		TC	TASKOVER
		
		EBANK=	AOG
ATDOTCAD	2CADR	ATTRATES

# Page 1073
# CALCULATE BODY ATTITUDE RATES AND INTEGRATE TO OBTAIN ATTITUDE ANGLES.
#
#	CB PHIDOT TCDU/180 = (CA PREL + SA RREL) TCDU/180
#	BETADOT TCDU/180 = (-SA PREL + CA RREL) TCDU/180
#	ALFADOT TCDU = (QREL + SB PHIDOT) TCDU/180

ATTRATES	LXCH	BANKRUPT	# CONTINUE HERE VIA T5
		EXTEND			# TASK MAY BE SKIPPED AT RESTART.
		QXCH	QRUPT
		CA	SR
		DOUBLE
		TS	CM/SAVE
					# DOES NOT PROTECT TEMK, SQ IN SPSIN/COS
					
		CA	QREL
		AD	ALFA/180
		TC	ANGOVCOR
		TS	ALFA/180
		TC	SPCOS
		TS	CALFA		# CALFA
		TS	PHIDOT
		
		EXTEND
		MP	PREL
		XCH	PHIDOT		# CA PREL
		EXTEND
		MP	RREL		# CA RREL
		TS	BETADOT
		
		CA	ALFA/180
		TC	SPSIN
		TS	SALFA		# SIN(ALFA)
		
		EXTEND
		MP	RREL		# SA RREL
		ADS	PHIDOT		# CB PHIDOT, SAVED.
		
		CS	SALFA
		EXTEND
		MP	PREL
		ADS	BETADOT		# SAVE BETADOT TCDU/180
		ADS	BETA/180	# BETA DONE.
		
		TC	SPSIN
		EXTEND
		MP	PHIDOT		# NEGLECT CB IN CB PHIDOT
		AD	ALFA/180
		TC	ANGOVCOR
		TS	ALFA/180	# ALFA DONE.
# Page 1074
		COM
		AD	ALFACOM
		TC	ANGOVCOR	# JUST IN CASE ...
		TS	AK1
		TS	QAXERR		# FOR PITCH FDAI AND EDIT.
		
		CA	PHIDOT		# PHIDOT TCDU/180, NEGLECTING CB
		AD	ROLL/180
		TC	ANGOVCOR
		TS	ROLLTM		# ROLL/180 FOR TM.
		TS	ROLL/180	# ROLL DONE.
		
# START YAW AUTOPILOT HERE.  RATE DAMPING WITH ENFORCED COORDINATED ROLL MANEUVER.

		CS	BETA/180	# IF IN ATM, SAVE 'RAXERR' FOR TM DNLST.
		AD	BETACOM
		TS	RAXERR		# IF OUTSIDE ATM, USE TM REGISTER 'RAXERR'
					# AS A TEMPORARY.  (DAP OPERATION IS IN INTERRUPT, SO
					# IS OK.)  FINAL C(RAXERR) AT END OF DAP CYCLE WILL
					# BE R-AXIS ERROR.
					
		CA	BIT3		# .05GSW = 102D BIT3	SW=0, LESS .05G
		MASK	CM/FLAGS	# SWITCH =1, GREATER THAN .05 G
		EXTEND
		BZF	EXDAP		# IF G LESS THAN .05
		CS	ONE		# IF G GEQ  THAN .05
		TS	CMDAPMOD	# SAVE -1 FOR USE IN CM/RCS
		
		TS	AK1		# TO ZERO PITCH AND YAW FDAI NEEDLES
		TS	AK2		# IN ATM.  (MODE =-1)
		
		CS	PREL		# YAW ERROR = RREL - PREL TAN(ALFA)
		EXTEND
		MP	SINTRIM		# LET SIN(-20) BE APPROX FOR TAN(-20)
		AD	RREL
		TC	2D/SDZ		# GO TEST DZ.  GET TAG: +0 IF IN DZ
		INDEX	A		# +/- 1 IF NOT
		CAF	YJETCODE
		
		TS	JETEM
		
# START PITCH AUTOPILOT HERE.  RATE DAMPING ONLY.

		CA	QREL
		TC	2D/SDZ
EXDAPIN		INDEX	A		# COME HERE FROM EX ATM DAP
		CAF	P/RJCODE
		ADS	JETEM		# COMBINE ALL NEW BITS.
		
		EXTEND			# DOES NOT REQUIRE SAVING OLD CODES.
# Page 1075		
		WRITE	PYJETS		# SET PYCHAN TO DESIRED BIT CONFIG.
		
		CCS	JETAG
		TC	CM/RCS
		TC	CM/FDAI
		TC	CM/FDAIR -1 	# (JETAG=-1 EQUIVALENT TO CMDAPMOD=+1)

# Page 1076
# DEAD ZONE LOGIC USED BY ENTRY DIGITAL AUTOPILOTS.

3DDZ		CCS	A		# YAWLIM=1.0-3/180=16384-273=16111
		AD	YAWLIM
		TCF	DZCOM
		AD	YAWLIM
		TCF	DZNOCOM
		
					# BIASED DZ FOR EXT ATM DAP.
BIASEDZ		TS	JETEM2		# SAVE RATE/180.  ERROR/180 IS IN L.
		CCS	A		# START ERROR DZ.
		CS	CM/BIAS		# = .6/180
		TCF	+2
		CA	CM/BIAS
		AD	L		# BIAS THE ERROR.
		LXCH	Q		# SAVE CALLER'S RETURN ADDRES.
		TC	3DDZ		# GO GENERATE THE ERROR BIT.
		DXCH	L		# BIT TO L, RESTORE CALLER'S Q.
4D/SDZ		CCS	JETEM2		# CAME HERE IN EXT ATM.  C(L) = ERROR BIT
		AD	4D/SLIM		# IF RATE GEQ 4D/S, SET L=0 AND TAKE
		TCF	+2		# JET BITS ACCORDING TO SGN OF RATE.
		AD	4D/SLIM
		TS	A
		TCF	+2		# RATE OK. CONTINUE
		ZL			# RATE GEQ 4 D/S.  OVER RIDE ERROR BIT
		XCH	JETEM2		# AND CONTINUE TO GET SIGN.
		
2D/SDZ		CCS	A		# COME HERE TO TEST IF A WITHIN 2DEG/S DZ
		AD	YDOTLIM		# 1.0 - YDOT DZ		(OR PDOT)
		TCF	+3
		AD	YDOTLIM		# YDOT DZ = 2 DEG/SEC
DZCOM		COM
DZNOCOM		TS	JETEM +1	# GENERATE TAG, SET C(A)= -+1 OUTSIDE DZ
		CA	ZERO		# SET C(A) = +0 INSIDE
		TC	Q
		
# Page 1077
# EXTRA ATMOSPHERIC DIGITAL AUTOPILOT
#
# 1.	IF ABS(CALF) -C(45) POS, USE			IF CALFA POS, CMDAPMOD= +0
#	BETA:	YAW ERROR = SGN(CALF) (BETACOM -BETA)	IF CALFA NEG, CMDAPMOD= -0
#		     RATE = BETADOT			IF CMDAPMOD = -0, RATE = RREL
#		   R-AXIS = CONTROL
#
#	ROLL:  ROLL ERROR = SGN(CALF) (ROLLC - ROLL)	IF CMDAPMOD = -0, RATE DAMP ONLY.
#		     RATE = PREL
#		   P-AXIS = CONTROL
#
# 2.	IF C(45) GEQ CALFA GEQ -C(45), USE		CMDAPMOD = +1
#	BETA:  ROLL ERROR = SGN(-SALF) (BETACOM -BETA)
#		     RATE = BETADOT
#		   P-AXIS = CONTROL
#
#	ROLL:	YAW ERROR = SGN(SALF) (ROLLC - ROLL)	RATE DAMP ONLY.
#		     RATE = RREL
#		   R-AXIS = CONTROL
#
# 3.	FOR ALL CASES, USE
#	ALFA: PITCH ERROR = (ALFACOM - ALFA)
#		     RATE = QREL
#		   Q-AXIS = CONTROL

EXDAP		TS	CMDAPMOD	# +0 FOR NOW
		CCS	CALFA
		AD	C45LIM		# =1.0-COS(45)
		TCF	+2
		AD	C45LIM
		TS	A
		TCF	EXDAP2		# HERE IF ABS(CALFA) L COS(45)
		
		CCS	CALFA		# |CALFA| > 0.707
		TCF	+1		# CONTINUE IF POS; GO TO EXDAP4 IF NEG.

		CCS	P63FLAG		# VALID VALUES ARE:  -1, +1, +0.
		TC	EXDAP4
		TC	+2
		TC	EXDAP4
		TC	PHASCHNG	# SINGLE PASS THROUGH HERE.
		OCT	40334
		CS	ONE
		TS	P63FLAG		# SET FLAG TO ASSURE SINGLE PASS.
		CA	NSEC
		TC	WAITLIST
		EBANK=	AOG
		2CADR	WAKEP62		# CALL TO TERMINATE P62 IN N SEC.
# Page 1078		
					# 65 DEG/ 3DEG/SEC = 21 SEC NOMINAL
					# TRANSIT TIME FROM ALFA=45 TO ALFA TRIM.
					
EXDAP4		CCS	JETAG		# ROLLJET INTERFACE TEST BETWEEN .1 SEC
		TCF	EXDAP3		# DAP AND THE 2 SEC CM/RCS DAP
		TCF	EXDAP3
		CA	ZERO
		EXTEND			# TURN OFF ROLL JETS IF ON AND WAIT
		WRITE	ROLLJETS	# UNTIL START OF 2 SEC CM/RCS CYCLE
		TS	JETAG		# RESTORE PROPER VALUE +0
		
					# ROLL FDAI WILL BE IN ERROR UNTIL NEXT CM/RCS CALL.
EXDAP3		CCS	CALFA		# HERE IF ABS(CALFA) GEQ COS(45)
		CA	RAXERR		# C()= BETACOM - BETA/180
		TCF	EXDAP1
		CS	ZERO
		TS	CMDAPMOD	# FOR CM/RCS
		CS	RAXERR		# COMPLEMENT OF YAW ERROR.
EXDAP1		TS	RAXERR		# FOR YAW FDAI
		TS	AK2		# WANT RAXERR FOR TM.
		TS	L
		CCS	CMDAPMOD	# COORDINATE BETA CONTROL.
		TC	+3		# C(CMDAPMOD) CAN BE +1, +0, OR -0.
		CA	ONE		# USE BETADOT TO COORD IN MODE +0
		INDEX	A		# OTHERWISE USE RREL.
		CA	RREL
		TC	BIASEDZ		# GO TEST DZ  +0 IF IN DX, +-1 OTHERWISE
					# IF GEQ 4D/S, SET ERROR BIT IN L=0
		EXTEND
		ROR	LCHAN		# L HAS BETA BIT
		INDEX	A
		CAF	YJETCODE
		TS	JETEM
		
		CA	QAXERR		# ALFA ERROR.
		TS	L
		CA	QREL		# FOR ALPHADOT USE QREL
		TC	BIASEDZ
		EXTEND
		ROR	LCHAN
		TCF	EXDAPIN		# CONTINUE ON IN DAP
		
EXDAP2		INCR	CMDAPMOD	# SET CMDAPMOD TO +1

		CS	ONE		# INDICATE CHANGE FROM .1 SEC UPDATE TO
		TS	JETAG		# TO 2 SEC FOR ROLL JETS.  (IF CMDAPMOD
					# =0 AND JETAG =-1, QUENCHES JETS IF ON)
					
		CCS	P63FLAG		# IF FLAG WAS +1, SET =0.
		TS	P63FLAG
# Page 1079		
		NOOP
		
		CCS	SALFA		# BETA CONTROL WITH P JETS
		CS	RAXERR		# B()= BETACOM - BETA/180
		TCF	+2
		CA	RAXERR
		TS	PAXERR1		# TEMP SAVE.  ERROR/180
		EXTEND
		MP	HALF		# CM/FDAI EXPECTS ERROR/360.
		XCH	PAXERR1		# ERROR/360 FOR FDAI, GET ERROR/180.
		TS	L
		CCS	SALFA
		CS	BETADOT		# USE BETADOT TO COORD IN MODE +1
		TC	+2
		CA	BETADOT
		TC	BIASEDZ
		EXTEND
		ROR	LCHAN
		INDEX	A
		CAF	P/RJCODE	# GET ROLL CODE
		EXTEND			# ROLL CONTROL WITH YAW JETS.
		WRITE	ROLLJETS	# WE'LL SKIP REGULAR ROLL SYST
		
		CA	ROLLHOLD	# ROLL/180 AT CM/DAPON TIME.
		EXTEND
		MSU	ROLL/180	# 1'S COMPL, BUT SO WHAT'S A BIT?
		TS	L		# FORCE A LIMIT CYCLE IN YAW RATE.
		CCS	SALFA
		CA	L		# TO REMOVE ITS BIASING EFFECT ON M DOT.
		TC	EXDAP1
		CS	L
		TC	EXDAP1
		
NSEC		DEC	2100		# 65 DEG/ 3 DEG/SEC
					# IF NSEC IS CHANGED, REMEMBER TO CHANGE 4.33SPOT.
4D/SLIM		DEC	16348		# 1.0 -4/180 D/S = 4/1800 EXP 14
YDOTLIM		DEC	16366		# =1.0 - YDOT DZ= 16384 -18
					# YDOT DZ = YDOT TCDU/180 = 2/1800 EXP 14
					
CM/BIAS		DEC	55		# =.6/180 B14 = 55
YAWLIM		DEC	16055		# YAWLIM=1.0-3.6/180=16384-329=16055
C45LIM		DEC	.29289		# =1.0-COS(45)

SINTRIM		DEC	-.34202		# SIN(-20)	(FOR NOMINAL L/D = .3)
COSTRIM		DEC	.93969		# COS(-20)	(FOR NOMINAL L/D = .3)

# TO MAKE DAP INSENSITIVE TO PITCH ERRORS DUE TO ACCUMULATED NAV ERRORS, USE NOMINAL VALUE (-20 DEG) FOR TRIM ALFA
# USED DURING ATMOSPHERIC COORDINATION.  OUTSIDE ATMOSPHERE, NAV ERRORS WILL BE SLIGHT, BUT ALFA CAN DIFFER GREATLY
# FROM TRIM, SO USE ON-BOARD ESTIMATES.

# Page 1080
# JET CODE TABLES FOLLOW

		OCTAL	00120		# POS Y
YJETCODE	OCTAL	00000		# RCS JET BITS
		OCTAL	00240		# NEG Y
		OCTAL	00005		# POS R JET BITS	ALSO POS P JET BITS
P/RJCODE	OCTAL	00000	
		OCTAL	00012		# NEG R			ALSO NEG P
		
# Page 1081
# RCS		THIS SECTION IS ENTERED EACH 2 SEC BY WAITLIST CALL FOLLOWING A DELAY OF 1.2 SEC AFTER PIPUP.
# THE TASK  SETJTAG  SETS A FLAG IN  JETAG  TO SIGNIFY THAT ROLL UPDATE IS DUE.  IN ROUGHLY 5 CS  BPDYRATE  WILL BE
# EXECUTED AND JETAG WILL CAUSE  CM/RCS  TO ACT ON ROLLC IMMEDIATELY THEREAFTER.  THE
# TASK SAVES THE CALL TIME SO THAT CM/RCS CAN DETERMINE HOW MUCH OF THE 2 SEC INTERVAL REMAINS BEFORE THE
# NEXT UPDATE.

SETJTAG		CS	TIME1		# SAVE NOMINAL UPDATE TIME FOR SYNCH
		TS	TUSED
					# THE 5 CS APPEARS IN TIMETST.
		CA	ONE		# RATHER THAN INCR, FOR SAFETY
		TS	JETAG		# SET JETAG=1 TO CAUSE CM/RCS TO BE
		TC	PHASCHNG
		OCT	00001
		
		TC	TASKOVER	# EXECUTED AFTER NEXT BODYRATE UPDATE
		
# PREDICTIVE ROLL SYSTEM	ENTRY STEERING PROVIDES ROLL COMMAND IN LOC ROLLC.  THE FOLLOWING CALCULATES THE
# TRAJECTORY TO THE ORIGIN IN PHASE PLANE (X,V).  PROGRAM ENTERS JET ON AND OFF CALLS INTO WTLST TO PRODUCE
# THE DESIRED TRAJECTORY.  ONLY THOSE CALLS WHICH CAN BE EXECUTED WITHIN THE INTERVAL  T  (2 SEC) ARE ENTERED IN
# WTLST, THE REMAINDER ARE RECONSIDERED AT NEXT UPDATE.

HALFPR		EQUALS	NEG1/2 +1

					# CLEAR JETAG BEFORE TIMETST.  SET TO +0 TO SHOW
					# ROLL DAP CALLED.  IN EVENT OF RESTART, BODYRATE
					# MAY MISS A CYCLE.  CM/RCS WILL MISS A CYCLE ONLY
					# IF A RESTART OCCURS AFTER TIMETST COMMENCES.
					
CM/RCS		CS	ONE
		TS	JNDX		# SET NDX FOR POS ROLL, AND CHANGE LATER
		
		CS	2T/TCDU		# ROLLDOT = DELAOG + DELAIG SINM =DELR
		EXTEND
		MP	PREL		# DELR/180 = RDOT TCDU/180 = RDOT/1800
		AD	L		# -2 RDOT T/180 IN L
		TS	-VT/180		# SAVE -2VT/180 HERE
		
		CS	ROLL/180
		TS	SR		# SAVE (-R/180) /2
		
		CS	CM/FLAGS
		MASK	BIT4		# LATSW = 101D BIT4
		EXTEND			# ROLL OVER TOP $
		BZF	GETLCX		# NO, TAKE SHORTEST PATH
		ADS	CM/FLAGS	# YES, ENFORCE ROLL OVER TOP.. (BIT =0)
		CA	ROLLC		# (ROLLC/180) /2
		AD	SR		# -(R/180) /2
		XCH	LCX/360		# DIFFERENT X REQD HERE.  DISCONT AT 180.
		TCF	COMPAT		# POSSIBLE OVFL ABOVE.
		
# Page 1082
GETLCX		CA	POS1/2		# FORM RCOM/360
		DOUBLE
		AD	ROLLC
		XCH	LCX/360		# IGNORE POSSIBLE OVFL.
		
		CA	SR		# FORM -R/360
		AD	NEG1/2
		AD	NEG1/2		# IGNORE OVFL
		XCH	LCX/360		# -R/360
		ADS	LCX/360		# LCX/360 = RCOM/360 - R/360  RANGE (-1,1)
		
# DOES SGN(-VT) (VT/180) (VT/180) (180/(4 A1 TT COSALFA)) + X/360 + SGN(X) / 2	  OVFL ?

		CCS	-VT/180		# TAKE SHORTEST ANGULAR PATH
		AD	ONE		# (BASED ON SINGLE JET ACCELERATION)
		TCF	+2
		AD	ONE
		EXTEND
		MP	-VT/180		# C(-VT/180) = -2 VT/180
		EXTEND
		MP	1/16A1		# = 180/(16 A1 TT)
		EXTEND
		DV	CALFA
		TS	L
		CCS	LCX/360
		CAF	POS1/2
		TCF	+2
		CS	POS1/2
		AD	LCX/360		# IS LCX/360 LESS THAN 180 DEGS  $
		AD	L
		TS	L
		TCF	COMPAT		# YES, GO ON.
TRTAGXPI	INDEX	A		# NO, SHIFT X BY - SGN(X) 2 PI
		CS	HALFPR		# +A YIELDS -1/2
		DOUBLE
		ADS	LCX/360
		
COMPAT		CA	LCX/360		# CORRECT FOR ASSUMED COORD TURN.
		EXTEND
		MP	CALFA		# COS ALFA
		TS	LCX/360		# SCALED LCX OK HERE.
		
		CCS	CMDAPMOD	# FOUR POSSIBILITIES HERE
		TC	DZCALL1		# EXIT, SETTING JETAG=0. (C(A)=0)
					# ALL 3 AXES ALREADY DONE.
		TC	+1		# G LESS THAN .05.  CA POS. CONTINUE
		CA	LCX/360		# G GEQ .05.  CONTINUE IN CM/RCS
		TS	LCX/360		# CMDAPMOD=-0.  DAMPING ONLY. SET LCX=0
		TS	ERRORZ		# INITIAL ROLL ERROR (UNREFLECTED) FOR TM.
		TS	PAXERR1		# SAVE LCX FOR FDAI AND EDIT.  (/360)
# Page 1083
		CA	-VT/180		# GET - 2 VT/180
		TS	SR
		CA	SR		# GET -VT/180, LEAVE -VT/360 IN SR FOR DZ
		TS	-VT/180E	#			DIAGNOSTIC ****
		XCH	-VT/180		# NOW CONTENTS OF -VT/180 AS LABELED
		EXTEND
		MP	-VT/180		# B(A) = -ZVT/180
		EXTEND
		MP	180/8ATT
		TS	VSQ/4API
		
# IS SGN(VT) ( (180/4A1 TT) VT/180 VT/180 - .5 BUFLIM/360 ) -X/360 -.5 BUFLIM/360  POS?

WHICHALF	DOUBLE			# FOR SECOND BURN, A1
		COM
		AD	BUFLIM		# =BUFLIM/(2 360)
		TS	L
		CCS	-VT/180
		CS	L
		TCF	+2
		CA	L
		AD	LCX/360
		AD	BUFLIM
		EXTEND
		BZMF	REFLECT		# POINT (X,V) IN LHP.
		
# IS SGN(VT) ( (180/4A1 TT) VT/180 VT/180 - .5 BUFLIM/360 ) -X/360 + .5 BUFLIM/360  NEG?

		COM
		AD	BUFLIM
		AD	BUFLIM
		EXTEND
		BZMF	DZ1		# POINT (X,V) IN RHP
		
# IS POINT WITHIN VELOCITY DZ?

		CS	VSQMIN		# IS VSQ/4API - (VSQ/4API) MIN NEG?
		AD	VSQ/4API
		EXTEND
		BZMF	DZCALL		# YES.
		
# POINT IS IN BUFFER ZONE.  THRUST TO X AXIS.

		CS	JNDX
		TS	JNDX1
		TC	OVRLINE1
		
REFLECT		CS	-VT/180		# RELFECT LHP INTO RHP REL TO TERM CONTR
		TS	-VT/180
		TS	SR		# -VT/360 SAVED FOR DZ.
# Page 1084
		CS	LCX/360
		TS	LCX/360
		CS	JNDX
		TS	JNDX
		
# IS VSQ/4API - (VSQ/4API) MIN NEG?

DZ1		CS	VSQMIN		# IS VSQ/4API - (VSQ/4API) MIN NEG  $
		AD	VSQ/4API
		EXTEND
		BZMF	DZ2		# YES, GO TEST FURTHER.
		TCF	MAXVTEST	# NO
		
# IS X/360 - XMIN/360 -VT/360 NEG?

DZ2		CS	XMIN/360	# XMIN/360 = 4/360
		AD	LCX/360
		AD	SR		# C(SR) = -VT/360
		EXTEND			# IS X/360 - XMIN/360 -VT/360 NEG  $
		BZMF	DZCALL		# YES, IN DZ.  EXIT SETTING JETAG=0.
		
# IS XD/360 - VM/360K - XS/360 POS?

MAXVTEST	CS	JNDX
		TS	JNDX1		# NOW CAN SET JNDX1 FOR TON2 JETS.
		CS	XS/360		# XS/360 = (XMIN -YMIN/K) /360
		AD	VSQ/4API
		AD	LCX/360
		TS	XD/360		# XD/360= X/360 +VSQ/4API   X INTERCEPT
					# BUT C(XD/360) = (XD - XS) /360
		AD	-VM/360K	# X INTERCEPT FOR MAX V (VM)
		COM
		EXTEND
		BZMF	MAXVTIM1	# YES, THRUST TO VM
		CA	XD/360
		EXTEND
		MP	KTRCS
		DDOUBL			# GO SAVE PREDICTED DRIFTING VELOCITY.
		
		TC	GETON1		# INSURE THAT Q IS POS AS TAG.
MAXVTIM1	EXTEND
		ZQ			# SET +Q AS TAG
		CS	-VMT/180
GETON1		TS	VDT/180		# VDT/180 OR VMT/180
		AD	-VT/180
		DOUBLE
		EXTEND
		MP	180/8ATT
		TS	TON1		# TON1 / 4T
# Page 1085
		EXTEND
		BZMF	OVRLINE
		TC	GETON2		# RESET Q POS IF CAME FROM MAXVTIM1
		
OVRLINE		CCS	Q
		TCF	OVRLINE1
MAXVTIM2	CA	JNDX1		# ABOVE VM, SO THRUST DOWN
		TS	JNDX
		CS	TON1
		TCF	OVRLINE2 +1
		
OVRLINE1	CS	-VT/180		# DRIFT AT V
		TS	VDT/180
OVRLINE2	CA	ZERO
		TS	TON1
GETON2		CA	VDT/180		# VDT/180, OR VMT/180 OR VT/180
		DOUBLE
		EXTEND
		MP	180/8ATT
		DOUBLE			# FOR SECOND BURN, A1
		TS	TON2		# = TON2 / 4T
		
		COM
		EXTEND
		BZMF	GETOFF
		TS	TON2
		CA	JNDX
		TS	JNDX1
		
GETOFF		CS	TON2		# TON2 / 4T
		EXTEND
		MP	VDT/180		# VDT/180, OR VT/180, OR VMT/180.
		TS	XD/360		# USE AS TEMP
		CS	VDT/180
		EXTEND
		BZF	TOFFOVFL	# OMIT THE DIVIDE IF DEN = 0.
		AD	-VT/180
		EXTEND
		MP	TON1		# TON1 /4T
		AD	XD/360		# TEMP = -VDT/180 / 2 TON2
		AD	LCX/360
		ZL
		XCH	L		# TEST THE DIVIDE
		EXTEND
		DV	VDT/180
		EXTEND
		BZF	GETOFF2		# DIVIDE OK
		
TOFFOVFL	CA	2JETT		# OVFL, USE  2T  FOR CONVENIENCE.
		TCF	TIMSCAL

# Page 1086
GETOFF2		XCH	L		# GET NUMERATOR.
		EXTEND
		DV	VDT/180		# C(A) = TOFF / 2T
		EXTEND
		MP	2JETT
TIMSCAL		TS	TOFF		# IN CS

		CAF	4JETT
		EXTEND
		MP	TON1		# C(TON1) = TON1 / 4T
		TS	TON1		# IN CS
		
		CAF	4JETT
		EXTEND
		MP	TON2		# C(TON2) = TON2 / 4T
		TS	TON2		# IN CS
		
		CA	ZERO		# CANNOT REDO AFTER TIMETST.  TUSED GONE
		TS	JETAG		# SET +0 TO SHOW ROLL DAP CALLED.
		
					# CAUSE THE TM OF BODY RATES VIA UPBUFF TO BE
					# INITIALIZED.  ALSO CAUSE NEEDLES TO BE DONE ON EXIT
					# AND ON ALTERNATE PASSES THROUGH CM/DUMPR.
					
		CA	ONE
		TS	SW/NDX

# Page 1087
# TIMETEST SECTION FOR RCS
#
# ENTER WITH THREE TIME INTERVALS AND THE CORRESPONDING JET CODE INDEXES IN ERASABLE LOCS TON1, TOFF, TON2, JNDX
# JNDX1.  SECTION PROCESSES TIME INTERVALS FOR WTLST CALLS AND ASSURES THAT WTLST CALLS ARE MADE ONLY
# (1) FOR POS INTERVALS GREATER THAN A SPECIFIED MINIMUM (HERE CHOSEN AS 2 CS) AND
# (2) FOR THE INTERVALS THAT WILL BE EXECUTED WITHIN THE TIME REMAINING IN THE SAMPLE INTERVAL T (2 SEC).
# TIMETST ESTABLISHES 6 LOCS CONTAINING JET CODES AND CORRESPONDING TIME INTERVALS.  THUS:  TON1, T1BITS,
# TOFF, TBITS, TON2, T2BITS.  OF THESE THE FIRST 2 LOCS ARE TEMPORARY, FOR IMMEDIATE ACTION, IN GENERAL.
# SECTION JETCALL BELOW PROCESSES THIS LIST.

TIMETST		CA	TIME1		# CORRECT FOR POSSIBLE TIME1 OVFL.
		AD	POS1/2
		AD	POS1/2		# OVFL GUARANTEED.
		ADS	TUSED		# B(TUSED) =-TUSED =-OLTIME1
		
		CA	-T-3		# =-T +2 -5 (SEE SETJTAG)
					# THE +2 REQUIRED FOR PROPER BRANCH.
		ADS	TUSED		# TUSED = TIME(K)-TIME(K-1)-T+2
		
		CS	TWO		# USE 2 SINCE TIME3 UNCERTAIN TO 1
		AD	TON1
		EXTEND
		BZMF	TIMETST1
		INDEX	JNDX
		CAF	P/RJCODE
		TS	T1BITS
		
		CA	TON1
		ADS	TUSED
		EXTEND
		BZMF	TOFFTEST
		CA	ZERO
		TCF	TIMETST3
TIMETST1	CS	ONE
		TS	TON1
TOFFTEST	CS	TWO
		AD	TOFF
		EXTEND
		BZMF	TIMETST2
		CA	TOFF
		ADS	TUSED
		EXTEND
		BZMF	TON2TEST
		CA	ZERO
		TCF	TIMETST4
TIMETST2	CS	ONE
		TS	TOFF
TON2TEST	CS	TWO
		AD	TON2
		EXTEND
		BZMF	TIMETST5
# Page 1088
		INDEX	JNDX1
		CAF	P/RJCODE
		TS	T2BITS
		CA	TON2
		ADS	TUSED
		EXTEND
		BZMF	JETCALL1
		CA	ZERO
		TCF	TIMETST5 +1
TIMETST3	TS	TON1
		CS	ONE
TIMETST4	TS	TOFF
TIMETST5	CS	ONE
		TS	TON2
		
# SECTION  JETCALL  EXAMINES CONTENTS OF JET TIMES IN LIST, ESTABLISHES WTLST ENTRIES, AND EXECUTES CORRESPONDING
# JET CODES.  A POSITIVE NZ NUMBER IN A TIME REGISTER INDICATES THAT A WTLST CALL IS TO BE MADE, AND ITS JET BITS
# EXECUTED.  A +0 INDICATES THAT THE TIME INTERVAL DOES NOT APPLY, BUT THE CORRESPONDING JET BITS ARE TO BE
# EXECUTED.  A NEG NUMBER INDICATES THAT THE TIME INTERVAL HAS BEEN PROCESSED.  IN EVENT OF +0 OR -1, THE 
# SUBSEQUENT TIME REGISTER IS EXAMINED FOR POSSIBLE ACTION.  THUS JET BITS TO BE EXECUTED MAY COME FROM MORE
# THAN ONE REGISTER.

JETCALL1	CA	ZERO
		TS	OUTTAG
		TS	NUJET
		TS	TBITS
		DXCH	TON1
		CCS	A
		TCF	JETCALL2	# CALL WTLST
JETCALL3	LXCH	NUJET		# WTLST ENTRIES COME HERE FROM JETCALL
		CS	ONE
		DXCH	TOFF
		CCS	A
		TCF	JETCALL2	# CALL WTLST
		LXCH	NUJET
		CS	ONE
		DXCH	TON2
		CCS	A
		TCF	JETCALL2	# CALL WTLST
		LXCH	NUJET
		TC	JETACTN		# C(A) = +0
JETCALL2	XCH	L		# SAVE JET BITS FOR AFTER WTLST CALL
		ADS	NUJET
		XCH	L
		AD	ONE		# RESTORE FOR CCS
		TC	WAITLIST
		EBANK=	AOG
		2CADR	JETCALL
		
JETACTN		CA	NUJET		# COME HERE WHEN DESIRED JET CODE IS KNOWN
# Page 1089
		EXTEND			# NO NEED TO SAVE OLD CODES
		WRITE	ROLLJETS	# SET RCHAN TO NEW BIT CONFIG.
		
		CCS	OUTTAG
		TC	TASKOVER
ROLLDUMP	TC	CM/FDAIR

					# EDIT DUMP AT ABOVE LOCATION.
					
# WAITLIST ENTRIES COME HERE.

JETCALL		CAF	BIT2		# CM/DSTBY =103D BIT2
		TS	OUTTAG		# SIGNIFY WTLST ENTRY
		MASK	CM/FLAGS	# IS SYSTEM DISABLED  $
		EXTEND
		BZF	JETACTN +1	# YES, QUENCH ROLL JETS, IF ON AND EXIT.
		ZL			# NO, CONTINUE.
		TCF	JETCALL3	# C(A) POS, C(L) = +0
		
# DEAD ZONE ENTRIES COME HERE.

DZCALL		CS	CMDAPMOD	# POSSIBLE VALUES OF CMDAPMOD: -1, +0, -0.
		MASK	BIT1
		TS	L		# C(L)=0 FOR -0: C(L)=1 FOR -1 OR +0.
		INDEX	A		# ERASABLE ORDER:  ROLLTM, ROLLC, ROLLC +1.
		CA	ROLLTM		# GET ROLL/180 OR ROLLC (/360).
		INDEX	L
		TS	A		# IF C(L)=1, STORE 'ROLLC' IN 'L'.
		AD	L		# (BOTH MUST BE SCALED DEG/180)
		TC	ANGOVCOR	# C(A)=ROLL/180 OR 2 ROLLC.
		TS	ROLLHOLD	# IF CMDAPMOD =-0, SAVE ROLL ANGLE.
					#	OTHERWISE, SAVE ROLL COMMAND.
					
		CA	ZERO		# COME HERE IF IN DZ, AND CANCEL JETS.
		EXTEND			# INHINT NOT NEEDED HERE.
		WRITE	ROLLJETS	# TURN OFF ALL ROLL JETS.
		TS	VDT/180		# SET =0 TO SHOW IN DEAD ZONE.
DZCALL1		TS	JETAG		# COME HERE WITH C(A)=0.
		TC	ROLLDUMP

# Page 1090
# CM ENTRY FDAI DISPLAY
#
# CALCULATE BY INTEGRATION THE ROLL ERROR BETWEEN THE 2 SEC CM/RCS UPDATES.  DISPLAY ATTITUDE ERRORS AS FOLLOWS:
#	ATM DAP:	DISPLAY ONLY ROLL ATTITUDE ERROR.
#	EXT ATM DAP:	PRESENT 3 ATTITUDE ERRORS RELATIVE TO THE APPROPRIATE BODY AXES EACH .1 SEC.
#				ROLL	ROLLC-ROLL
#				PITCH	ALFAC-ALFA
#				YAW	BETAC-BETA
#
# DURING ENTRY, THE FDAI NEEDLES HAVE FULL SCALE OF 67.5 DEG IN ROLL AND 16.875 DEG IN PITCH AND YAW.
# THE SUBROUTINE  NEEDLER  EXPECTS (ANGLE/180) AND SCALES TO 16.875 DEG FULL SCALE.

					# COME HERE EACH .1 SEC.  (CMDAPMOD=+1 COMES BELOW)
CM/FDAI		CS	PHIDOT		# INTEGRATE ROLL ERROR 'TWEEN 2SEC UPDATES
		EXTEND
		MP	CALFA		# FOR ASSUMED COORDINATION.
		EXTEND
		MP	HALF
		ADS	PAXERR1		# ROLL ERROR/360.  OVFL OK.
		
					# EDIT DUMP AT ABOVE LOCATION.
CM/FDAIR	CA	HALF
		EXTEND
		MP	PAXERR1		# FULL SCALE FOR FDAI (ROLL) IS 67.5 D
		TS	PAXERR		# .25 (ROLL ERROR/180) FOR FDAI NEEDLE.
		
					# PROGRAM TO FILE BODY RATES FOR TM ON ONE PASS AND
					# TO UPDATE THE NEEDLE DISPLAY ON THE NEXT.
					# SYNCHRONIZATION WITH CM/RCS IS USED SO THAT THE TM
					# IS DONE WITH THE ROLL SYSTEM AND NEEDLES START ON
					# THE SUBSEQUENT PASS.
					
CM/DUMPR	CS	SW/NDX		# COMBINED ALTERNATION SWITCH AND FILE
		TS	SW/NDX
		EXTEND			# INDEX
		BZMF	CMTMFILE	# FILE STARTS WITH SW/NDX +1 AND GOES TO
					# ENDBUF.			
					# INDEX IS POS FOR NEEDLES.
		
		TC	IBNKCALL
		CADR	NEEDLER
		
		TC	CM/END
		
					# INDEX IS NEG FOR TM FILE
					
CMTMFILE	AD	THREE
		EXTEND
		BZMF	SAVENDX

# Page 1091
		CA	TIME1		# INITIALIZE THE TM LIST IN UPBUFF.
		TS	CMTMTIME
		CS	THIRTEEN	# INITIALIZE COUNTER
SAVENDX		TS	SW/NDX		# A NEGATIVE NUMBER.
		EXTEND
		DCA	PREL
		INDEX	SW/NDX
		DXCH	ENDBUF -1
		CA	RREL
		INDEX	SW/NDX
		TS	ENDBUF +1
		
CM/END		CA	CM/SAVE
		TS	SR
					# DOES NOT PROTECT TEMK, SQ IN SPSIN/COS
					
		EXTEND
		DCA	T5IDLER2
		DXCH	T5LOC
		TC	RESUME
		
		EBANK=	T5LOC
T5IDLER2	2CADR	T5IDLOC

					# DEFINE THE FOLLOWING 17D REGISTERS IN UPBUFF TO BE
					# USED TO TELEMETER CM VEHICLE BODY RATE INFORMATION.
					# THE INFORMATION IS FILED EACH 0.2 SEC, GIVING 15D
					# DATA POINTS EACH 1 SEC.  TM LIST IS READ TWICE
					# EACH 2 SECONDS.
					#
					# THE SEQUENCE IS:	SP TIME		INITIAL TIME
					#			SWITCH		ALSO INDEX.
					#			P		ROLL RATE
					#			Q		PITCH RATE
					#			R		YAW RATE
					#			ETC.
					
#CMTMTIME	=	UPBUFF
#SW/NDX		=	UPBUFF +1
#ENDBUF		=	UPBUFF +16D

# Page 1092
# SPACER
#
# CONSTANTS USED IN THE ROLL CONTROL SYSTEM:	
# CONSTANTS ARE THE FOLLOWING:  A = 9.1 DEG/SECSQ, VM = 20 DEG/SEC, T = 2 SEC, TCDU = .1 SEC,
# XMIN = 4 DEG, VMIN = 2 DEG/SEC, K = .25, A1 = 4.55 DEG/SECSQ, VI = 1 DEG/SEC, INTERCEPT WITH DZ SIDE
# XBUF = 4DEG

-T-3		DEC	-203		# CS
VSQMIN		DEC	.61050061 E-3	# VSQ MIN/4 A PI = 4/(4 (9.1) 180)
2T/TCDU		=	OCT50		# T/TCDU EXP-14	   TCDU = .1SEC
180/8ATT	DEC	.61813187	# 180/(8 (9.1) 4)=(180/ATT)	EXP -3
-VMT/180	=	-VM/360K	# = 20 (2) / 180
2JETT		=	4SECS		# CS		2 (2) 100	INTEGER
4JETT		DEC	800		# CS		4 (2) 100	INTEGER
XMIN/360	DEC	182		# XMIN/360 = 4/ 360  EXP 14  = 182 INTEGER
-VM/360K	DEC	-.22222222	# =-20/( 360 (.25))
1/16A1		=	180/8ATT
					# 1/16A1   = 180/(16 A1 TT)
					#          = 180/(16 4.55 4)
XS/360		DEC	91		# = (XMIN +VI (T-1/K))/360 = 2/360 EXP 14
BUFLIM		=	XS/360		# 4/(2 360)

KTRCS		=	HALF		#    KT = (.25) 2 = .5

# *** END OF TVCDAPS .011 ***

