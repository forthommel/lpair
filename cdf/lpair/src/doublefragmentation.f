c     Fragmentation algorithm
c     Connects LPAIR output to Jetset for string fragmentation
c
c     Authors :
c     ...
c     N. Schul (UCL, Louvain-la-Neuve)
c     L. Forthomme (UCL, Louvain-la-Neuve), Feb 2014

      SUBROUTINE DOUBLEFRAGMENTATION
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
c.. Pair produced code
      INTEGER IPAIR,NLHE
      PARAMETER (IPAIR=24) 
      INTEGER L,NLEP 
c... general kinematics
      REAL*8       E1,E6,E3,E8,P1,E2
      REAL*8       P3,P8
      REAL*8       EGAMMA1,EGAMMA2
      DIMENSION    X(10),M(10),Z(10),XI(50,10),XIN(50)

      INTEGER NLIMAX
      PARAMETER (NLIMAX=13)
      REAL*4  PL(4,NLIMAX),PMXDA(4),PMXDB(4)
      REAL*4  I2MASS(NLIMAX)
      DATA    I2MASS/NLIMAX*-9999.9/

C   LUND COMMON 
      REAL*4        P(4000,5)
      INTEGER       N,K(4000,5)
      COMMON/LUJETS/N,K,P
      save /lujets/

c... parameters pi
      REAL*4  PI2,PI
      PARAMETER (PI2=2.0*3.14159265)
      PARAMETER (PI=3.14159265)
c... for LUJOIN      
      INTEGER JLPSF3(2)
      DATA    JLPSF3/10,11/
      INTEGER JLPSF4(2)
      DATA    JLPSF4/12,13/

c... for MX
      REAL*8  MX1,MX2,WX1,WX2,W1,W6,W3,W8
      INTEGER I2STAT(13),I2PART(13)
      INTEGER I2MO1(13),I2DA1(13),I2DA2(13)
c... angles, etc.
      REAL*4 H1RN,RANPHI,SINPHI,COSPHI,RANY,RANUDQ
C----- Allow W+ -> l+ v only
      COMMON/LUDAT3/MDME(8750,2)
      SAVE  /LUDAT3/
      
* --- HEPEVT common block
      PARAMETER (NMXHEP=10000)
      COMMON/HEPEVT/NEVHEP,NHEP,
     &     ISTHEP(NMXHEP),IDHEP(NMXHEP),
     &     JMOHEP(2,NMXHEP),JDAHEP(2,NMXHEP),
     &     PHEP(5,NMXHEP),VHEP(4,NMXHEP)
      REAL PHEP,VHEP
      INTEGER I,J

      DOUBLE PRECISION x(10)
      COMMON/event/accepted,x(10)
!
! INCOMING p+_1    == 1
! photon 1         == 2
! DISSOCIATED p+_1 == 3
! Quark/Diquark    == 4&5

!
! INCOMING p+_2    == 6
! photon 2         == 7
! DISSOCIATED p+_2 == 8
! Quark/Diquark    == 9&10

*   1  proton       (incoming, left)
*   2  proton       (incoming,right)
*   3  proton       (outgoing, left)
*   5  proton       (outgoing,right)
*   4  muon-pair (resonance product)
*   6  muon         (outgoing, left)
*   7  muon         (outgoing,right)

      EGAMMA1 = PHEP(4,3)-PHEP(4,1)
      EGAMMA2 = PHEP(4,5)-PHEP(4,2)

      PPXP1 = PHEP(1,3)
      PPYP1 = PHEP(2,3)
      PPZP1 = PHEP(3,3)

      PPXP2 = PHEP(1,5)
      PPYP2 = PHEP(2,5)
      PPZP2 = PHEP(3,5)

      PPXM1 = PHEP(1,6)
      PPYM1 = PHEP(2,6)
      PPZM1 = PHEP(3,6)
      PPEM1 = PHEP(4,6)

      PPXM2 = PHEP(1,7)
      PPYM2 = PHEP(2,7)
      PPZM2 = PHEP(3,7)
      PPEM2 = PHEP(4,7)

      PP93 = PHEP(3,4) ! dimuon pz
      PE93 = PHEP(4,4) ! dimuon E

      OPEN(22,file='events.out', status='unknown')  
      
      DO 11111 I=1,7
         PRINT *,I,(PHEP(J,I),J=1,5)
11111 CONTINUE

c...  READ the kinematics from the event
      E1=3500.
      P1=3500.
      E2=3500.      
      P2=-P1
      E5=3500.-EGAMMA1
      E7=3500.-EGAMMA2
      
      NFAIL=0
      DO 999 L=1,1
 1       J=rand(0)*6561+1.
         NFAIL=NFAIL+1
         IF(NFAIL.GT.9999) THEN
            WRITE(*,*) 'SKIP Event'
            GO TO 999
         ENDIF
C     
C     SEL X VALUES IN THIS VEGAS BIN <<<<<<<<<<<<<<<<<<<<<<<<<<<<
         JJ=J-1
         AMI=1.0D0/DBLE(3.0D0)
         DO 52 II=1,8
            JJJ=JJ/3
            M(II)=JJ-JJJ*3
            X(II)=(rand(0)+M(II))*AMI
            JJ=JJJ
 52      CONTINUE
         DO 53 J=1,8
            XI(1,J)=1.
 53      CONTINUE
         RC=0.02
         DO 54 J=1,8
            KK=0
            XN=0.
            DR=XN
            I=KK
 64         KK=KK+1
            DR=DR+1.
            XO=XN
            XN=XI(KK,J)
 65         IF(RC.GT.DR) GO TO 64
            I=I+1
            DR=DR-RC
            XIN(I)=XN-(XN-XO)*DR
            IF(I.LT.50) GO TO 65
            DO 66  I=1,50
               XI(I,J)=XIN(I)
 66         CONTINUE
            XI(50,J)=1.
 54      CONTINUE
         
         DO 56 I=1,8
            XX=X(I)*50
            J=XX
            JJ=J+1
            DDD=XI(JJ,I)-XI(J,I)
            Z(I)=XI(JJ,I)-DDD
c            WRITE(*,*) 'z(',I,') = ',Z(I)
 56      CONTINUE
         
c...  compute the MX value
         WX1=(1.1449)*(102400/1.1449)**Z(8)
         WX2=(1.1449)*(102400/1.1449)**Z(7)
         MX1=DSQRT(WX1)
         MX2=DSQRT(WX2)
c     smearing of the mass (N. Schul)
c     WRITE(*,*) 'mx1, mx2=',MX1,MX2
         VARYMX1=rand(0)*(0.1*MX1)
         VARYMX2=rand(0)*(0.1*MX2)
         MX1=MX1+VARYMX1
         MX2=MX2+VARYMX2
         WRITE(*,*) 'corr mx1, mx2=',MX1,MX2
         
C...  VARIOUS INTERMEDIATE QUANTITIES
c......masses
         W1=0.880406915
         W2=W1
         W5=WX1
         W7=WX2
         P5=DSQRT(E5*E5-W5)
         P7=DSQRT(E7*E7-W7)
c...  Fill the Lund
C     PARTICLE 1 = "PROTON1" <===================================
         PL(1,1)=0.0
         PL(2,1)=0.0
         PL(3,1)=P1
         PL(4,1)=E1
C     PARTICLE 2 = "PROTON2" <===================================
         PL(1,2)=0.0
         PL(2,2)=0.0
         PL(3,2)=-P1
         PL(4,2)=E2
         
C     PARTICLE 5 = QUARK1 OUT <==================================
         PL(1,5)=PPXP1
         PL(2,5)=PPYP1
         PL(3,5)=PPZP1
         PL(4,5)=E5
C     PARTICLE 8 = QUARK2 OUT <==================================
         PL(1,7)=PPXP2
         PL(2,7)=PPYP2
         PL(3,7)=PPZP2
         PL(4,7)=E7
         
C     PARTICLE 3 = GAMMA1
         PL(1,3)=-PL(1,5)
         PL(2,3)=-PL(2,5)
         PL(3,3)=3500.0-PL(3,5)
         PL(4,3)=EGAMMA1
C     PARTICLE 4 = GAMMA2
         PL(1,4)=-PL(1,7)
         PL(2,4)=-PL(2,7)
         PL(3,4)=-3500.0-PL(3,7)
         PL(4,4)=EGAMMA2
         
C     Particle 6 --> middle particle
         PL(1,6)=0.0
         PL(2,6)=0.0
         PL(3,6)=PP93
         PL(4,6)=PE93
         
c...  choose the quark content
C==== > INSERT THE MASS OF THE HADRONIC SYSTEM <=================
         I2MASS(5)=SNGL(MX1)
C===  > RANDOM SELECTION OF U , D AND DI QUARKS <================
         RANUDQ3=rand(0)
         IF (RANUDQ3 .LT. 1.0/9.0) THEN
            I2PART(12)=1
            I2PART(13)=2203
            ULMDQ3=0.771333277
            ULMQ3 =0.00989999995
         ELSEIF (RANUDQ3 .LT. 5.0/9.0) THEN
            I2PART(12)=2
            I2PART(13)=2101
            ULMDQ3=0.579333305
            ULMQ3 =0.0055999998
         ELSE
            I2PART(12)=2
            I2PART(13)=2103
            ULMDQ3=0.771333277
            ULMQ3 =0.0055999998
         ENDIF

C==== > INSERT THE MASS OF THE HADRONIC SYSTEM <=================
         I2MASS(7)=SNGL(MX2)
C===  > RANDOM SELECTION OF U , D AND DI QUARKS <================
         RANUDQ4=rand(0)
         IF (RANUDQ4 .LT. 1.0/9.0) THEN
            I2PART(10)=1
            I2PART(11)=2203
            ULMDQ4=0.771333277
            ULMQ4 =0.00989999995
         ELSEIF (RANUDQ4 .LT. 5.0/9.0) THEN
            I2PART(10)=2
            I2PART(11)=2101
            ULMDQ4=0.579333305
            ULMQ4 =0.0055999998
         ELSE
            I2PART(10)=2
            I2PART(11)=2103
            ULMDQ4=0.771333277
            ULMQ4 =0.0055999998
         ENDIF
         
C...  Set Lund code
*
*  1 : incoming proton 1
         I2STAT(1)=21
         I2PART(1)=2212
         I2MO1(1)=0
         I2DA1(1)=3
         I2DA2(1)=5
         
*  2 : incoming proton 2
         I2STAT(2)=21
         I2PART(2)=2212
         I2MO1(2)=0
         I2DA1(2)=4
         I2DA2(2)=7
         
*  3 : photon 1
         I2STAT(3)=11
         I2PART(3)=22
         I2MO1(3)=1
         I2DA1(3)=0
         I2DA2(3)=0
         
*  4 : photon 2
         I2STAT(4)=11
         I2PART(4)=22
         I2MO1(4)=2
         I2DA1(4)=6
         I2DA2(4)=0
         
*  5 : outgoing proton 1
         I2STAT(5)=21
         I2PART(5)=2212
         I2MO1(5)=1
         I2DA1(5)=0
         I2DA2(5)=0
         
*  6 : central system (mother : photon 2)
*         I2STAT(6)=1
*         I2PART(6)=14 ! muon neutrino ?!
         I2STAT(6)=11
         I2PART(6)=100
         I2MO1(6)=4
         I2DA1(6)=8
         I2DA2(6)=9
         
*  7 : outgoing proton 2
         I2STAT(7)=21
         I2PART(7)=2212
         I2MO1(7)=2
         I2DA1(7)=0
         I2DA2(7)=0
         
*  8 : muon 1
         I2STAT(8)=1
         I2PART(8)=13
         I2MO1(8)=6

*  9 : muon 2
         I2STAT(9)=1
         I2PART(9)=-13
         I2MO1(9)=6

* 10 : quark 1
         I2STAT(10)=1
         I2MO1(10)=5
         I2DA1(10)=0
         I2DA2(10)=0
         
* 11 : diquark 1
         I2STAT(11)=1
         I2MO1(11)=5
         I2DA1(11)=0
         I2DA2(11)=0
         
* 12 : quark 2
         I2STAT(12)=1
         I2MO1(12)=7
         I2DA1(12)=0
         I2DA2(12)=0
         
* 13 : diquark 2
         I2STAT(13)=1
         I2MO1(13)=7
         I2DA1(13)=0
         I2DA2(13)=0
*
         
         
C==== > CHOOSE RANDOM DIRECTION IN MX FRAME <====================
         RANMXP1=PI2*rand(0)
         RANMXT1=ACOS(2.0*rand(0)-1.0)

         RANMXP2=PI2*rand(0)
         RANMXT2=ACOS(2.0*rand(0)-1.0)
         
C==== > COMPUTE MOMENTUM OF DECAY PARTICLE FROM MX1 <============
         PMXP2=DSQRT((MX2**2-ULMDQ3**2+ULMQ3**2)**2/
     &        4.0/MX2/MX2-ULMQ3**2)

         PMXDA(1)=SIN(RANMXT2)*COS(RANMXP2)*PMXP2
         PMXDA(2)=SIN(RANMXT2)*SIN(RANMXP2)*PMXP2
         PMXDA(3)=COS(RANMXT2)*PMXP2
         PMXDA(4)=SQRT(PMXP2**2+ULMDQ3**2)
         CALL LORENB(I2MASS(7),PL(1,7),PMXDA(1),PL(1,13))

         PMXDA(1)=-PMXDA(1)
         PMXDA(2)=-PMXDA(2)
         PMXDA(3)=-PMXDA(3)
         PMXDA(4)=SQRT(PMXP2**2+ULMQ3**2)
         CALL LORENB(I2MASS(7),PL(1,7),PMXDA(1),PL(1,12))

C==== > COMPUTE MOMENTUM OF DECAY PARTICLE FROM MX2 <============
         PMXP1=DSQRT((MX1**2-ULMDQ4**2+ULMQ4**2)**2/
     &        4.0/MX1/MX1-ULMQ4**2)

         PMXDB(1)=SIN(RANMXT1)*COS(RANMXP1)*PMXP1
         PMXDB(2)=SIN(RANMXT1)*SIN(RANMXP1)*PMXP1
         PMXDB(3)=COS(RANMXT1)*PMXP1
         PMXDB(4)=SQRT(PMXP1**2+ULMDQ4**2)

         CALL LORENB(I2MASS(5),PL(1,5),PMXDB(1),PL(1,11))
         PMXDB(1)=-PMXDB(1)
         PMXDB(2)=-PMXDB(2)
         PMXDB(3)=-PMXDB(3)
         PMXDB(4)=SQRT(PMXP1**2+ULMQ4**2)
         CALL LORENB(I2MASS(5),PL(1,5),PMXDB(1),PL(1,10))

         DO 2001 I=1,13
            PRINT *,I,':',(PL(J,I),J=1,4)
 2001    CONTINUE
         
         CALL LUNSET(13)
C     ====> FILLING THE LUND COMMON <============================
         DO 201 I=1,13
C     SET MOTHER/DAUGHTER VALUES, MARKING PARTICLES AS DECAYED <=
            CALL LUKSET(I,I2STAT(I),I2PART(I),
     &           I2MO1(I),I2DA1(I),I2DA2(I),0)
C     SET PULS, ENERGY AND MASS OFF THE PARTICLES <==============
            CALL LUPSET(I,PL(1,I),PL(2,I),PL(3,I),PL(4,I),I2MASS(I))
 201     CONTINUE

         CALL LUJOIN(2,JLPSF3)
         CALL LUJOIN(2,JLPSF4)

         CALL LUEXEC
c     IF(K(16,2).EQ.91.AND.K(16,1).EQ.11) THEN
c     WRITE(*,*) '-> System non-inelastic'
c     GO TO 1
c     ENDIF
         IF(K(17,2).EQ.2212.AND.K(17,1).EQ.1) THEN
            WRITE(*,*) '-> System non-inelastic'
            NFAIL=NFAIL+1
            GO TO 1
         ENDIF
         
         CALL LULIST(2)
         
         NLHE=0
         DO 203 I=1,N
            IF(K(I,1).EQ.1.AND.K(I,2).EQ.2212.AND.I.LT.16) THEN
               NLHE=NLHE+1
            ENDIF
            IF(K(I,1).EQ.1.AND.I.GT.15)        NLHE=NLHE+1
            IF(K(I,1).EQ.1.AND.I.GT.15.AND.K(I,2).EQ.12) NLHE=NLHE-1
            IF(K(I,1).EQ.1.AND.I.GT.15.AND.K(I,2).EQ.-12) NLHE=NLHE-1
            IF(K(I,1).EQ.1.AND.I.GT.15.AND.K(I,2).EQ.14) NLHE=NLHE-1
            IF(K(I,1).EQ.1.AND.I.GT.15.AND.K(I,2).EQ.-14) NLHE=NLHE-1
            IF(K(I,1).EQ.1.AND.I.GT.15.AND.K(I,2).EQ.16) NLHE=NLHE-1
            IF(K(I,1).EQ.1.AND.I.GT.15.AND.K(I,2).EQ.-16) NLHE=NLHE-1
 203     CONTINUE
         WRITE(22,*) '<event>'
         WRITE(22,*) NLHE+4,'  661   0.2983460E-04  0.9118800E+02',
     &        '0.7821702E-02  0.1300000E+00'
         WRITE(22,*) '22  -1   0   0   0   0  0.0',
     &        '  0.0  0.0',EGAMMA1,' 0.0  0.  1.'
         WRITE(22,*) '22  -1   0   0   0   0  0.0',
     &        '  0.0  0.0',EGAMMA2,' 0.0  0.  -1.'
         
         
         DO 202 I=1,N
            
            IF(K(I,1).EQ.1.AND.K(I,2).EQ.2212.AND.I.LT.14) THEN
               WRITE(22,*) '2212 1 1 2 0 0 0.0 0.0 ',P(I,4), ! -P(I,4) normally quoted
     &              P(I,4),P(I,5),' 0. 1'
            ENDIF
            IF(I.GT.13.AND.K(I,1).EQ.1) THEN
               IF(K(I,2).NE.12.AND.K(I,2).NE.-12.AND.K(I,2).NE.14) THEN
                  IF(K(I,2).NE.-14.AND.K(I,2).NE.16.
     &                 AND.K(I,2).NE.-16) THEN
                     WRITE(22,*) K(I,2),' 1 1 2 0 0',
     &                    P(I,1),P(I,2),P(I,3), ! P(I,3) normally quoted 
     &                    P(I,4),P(I,5),' 0. 1'
                  ENDIF
               ENDIF
            ENDIF
 202     CONTINUE
c     FOR MUONS
         WRITE(22,*) '13  1 1 2 0 0 ',PPXM1,PPYM1,PPZM1,PPEM1,
     &        ' 0.1057 0. 1'
         WRITE(22,*) '-13 1 1 2 0 0 ',PPXM2,PPYM2,PPZM2,PPEM2,
     &        ' 0.1057 0. 1'
         
c     FOR TAUS
c     WRITE(22,*) '15  1 1 2 0 0 ',PPXM1,PPYM1,PPZM1,PPEM1,
c     &  ' 1.77684 0. 1'
c     WRITE(22,*) '-15 1 1 2 0 0 ',PPXM2,PPYM2,PPZM2,PPEM2,
c     &  ' 1.77684 0. 1'
         
         WRITE(22,*) '</event>'
         
 999  CONTINUE
      END
      
