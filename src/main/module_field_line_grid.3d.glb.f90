!dbg2010923: to reduce memory1: apexE etc
!dbg20110927: to reduce memory2:
! DATE: 08 September, 2011
!********************************************
!***      Copyright 2011 NAOMI MARUYAMA   ***
!***      ALL RIGHTS RESERVED             ***
!********************************************
! LICENSE AGREEMENT Ionosphere Plasmasphere Electrodynamics (IPE) model
! DEVELOPER: Dr. Naomi Maruyama
! CONTACT INFORMATION:
! E-MAIL : Naomi.Maruyama@noaa.gov
! PHONE  : 303-497-4857
! ADDRESS: 325 Broadway, Boulder, CO 80305
!--------------------------------------------  
      MODULE module_FIELD_LINE_GRID_MKS
      USE module_precision
      USE module_IPE_dimension,ONLY: NPTS2D,NMP0,NMP1,NMP_all,NLP,NLP_all
      IMPLICIT NONE

! --- PRIVATE ---
!
! --- PUBLIC ---
      INTEGER (KIND=int_prec),PUBLIC :: mp_save,lp_save
      REAL(KIND=real_prec),PARAMETER,PUBLIC :: ht90  = 90.0E+03  !reference height in meter
!... read in parameters
      INTEGER(KIND=int_prec), ALLOCATABLE,TARGET,PUBLIC :: JMIN_IN(:),JMAX_IS(:)  !.. first and last indices on field line grid
      TYPE :: plasma_grid
!dbg20110927         REAL(KIND=real_prec) :: Z  !.. altitude [meter]
         REAL(KIND=real_prec) :: SL !.. distance of point from northern hemisphere foot point [meter]
         REAL(KIND=real_prec) :: BM !.. magnetic field strength [T]
         REAL(KIND=real_prec) :: GR !.. Gravity [m2 s-1]
!dbg20110927         REAL(KIND=real_prec) :: GL !.. magnetic co-latitude Eq(6.1) [rad]
         REAL(KIND=real_prec) :: Q  !
         REAL(KIND=real_prec) :: GCOLAT !.. geographic co-latitude [rad]
         REAL(KIND=real_prec) :: GLON   !.. geographic longitude [rad]
      END TYPE plasma_grid
      TYPE(plasma_grid), ALLOCATABLE, TARGET,PUBLIC :: plasma_grid_3d(:,:)      
      REAL(KIND=real_prec),ALLOCATABLE,TARGET,PUBLIC :: plasma_grid_Z(:) !.. altitude [meter] (NPTS2D)
      REAL(KIND=real_prec),ALLOCATABLE,TARGET,PUBLIC :: plasma_grid_GL(:)!.. magnetic co-latitude Eq(6.1) [rad]
      REAL(KIND=real_prec),ALLOCATABLE,TARGET,PUBLIC :: mlon_rad(:) !mag longitude in [rad]
      REAL(KIND=real_prec),PARAMETER, PUBLIC :: dlonm90km = 4.5 ![deg]
!      REAL(KIND=real_prec), ALLOCATABLE, PUBLIC ::  GCOLAT(:,:)    !.. geographic co-latitude [rad]
!      REAL(KIND=real_prec), ALLOCATABLE, PUBLIC ::  GLON(:,:)      !.. geographic longitude [rad]
!      REAL(KIND=real_prec), ALLOCATABLE, PUBLIC ::  Qvalue(:,:)
!      REAL(KIND=real_prec), ALLOCATABLE, PUBLIC ::  GL_rad(:,:)    !.. magnetic co-latitude Eq(6.1) [rad]
!      REAL(KIND=real_prec), ALLOCATABLE, PUBLIC ::  SL_meter(:,:)  !.. distance of point from northern hemisphere foot point [meter]
!      REAL(KIND=real_prec), ALLOCATABLE, PUBLIC ::  BM_T(:,:)     !.. magnetic field strength [T]

      REAL(KIND=real_prec), ALLOCATABLE, PUBLIC ::  Be3(:,:,:)     ! .. Eq(4.13) Richmond 1995 at Hr=90km in the NH(1)/SH(2) foot point [T]
!------------
!...calculated parameters
!      REAL(KIND=real_prec), ALLOCATABLE,     PUBLIC ::  Z_meter(:,:) !.. altitude [meter]
      REAL(KIND=real_prec), ALLOCATABLE,     PUBLIC ::  Pvalue(:)  !.. p coordinate (L-shell)
!      REAL(KIND=real_prec), ALLOCATABLE,     PUBLIC ::  GR_mks(:,:)  !.. Gravity [m2 s-1]


!-------------
!nm20110822:no longer used
!      REAL(KIND=real_prec),               ALLOCATABLE, PUBLIC ::  SZA_rad(:) !solar zenith angle [radians]
!
! components (east, north, up) of base vectors
      TYPE :: geographic_coords
         REAL(KIND=real_prec) :: east
         REAL(KIND=real_prec) :: north
         REAL(KIND=real_prec) :: up
      END TYPE geographic_coords

      TYPE(geographic_coords), ALLOCATABLE, PUBLIC ::  apexD(:,:,:)    !(3,NPTS2D,NMP).. Eq(3.8-10) Richmond 1995
      TYPE(geographic_coords), ALLOCATABLE, PUBLIC ::  apexE(:,:,:)    !(2,NPTS2D,NMP).. Eq(3.11-12) Richmond 1995
!
      PRIVATE :: read_plasma_grid_global !dbg ,test_grid_output
      PUBLIC :: init_plasma_grid


      CONTAINS
!---------------------------
! initialise plasma grids
        SUBROUTINE init_plasma_grid ( )
        USE module_physical_constants,ONLY: earth_radius, pi, G0,zero
        USE module_input_parameters,ONLY: sw_debug,lpstrt,lpstop,mpstrt,mpstop
        IMPLICIT NONE

        INTEGER (KIND=int_prec) :: i, mp,lp
        REAL (KIND=real_prec) :: sinI
        INTEGER (KIND=int_prec), parameter :: sw_sinI=0  !0:flip; 1:APEX
        INTEGER (KIND=int_prec), POINTER :: in,is
        REAL(KIND=real_prec), DIMENSION(NPTS2D) ::  r_meter2D     !.. distance from the center of the Earth[meter]
!---------
! array initialization
      plasma_grid_Z(:)     = zero

!if the new GLOBAL 3D version
      CALL read_plasma_grid_global ( r_meter2D )

! make sure to use the MKS units.
      plasma_grid_Z(1:NPTS2D) = r_meter2D(1:NPTS2D) - earth_radius ![meter]
      print *,"Z_meter calculation completed"

      Pvalue(:) = zero
      apex_longitude_loop: DO mp = NMP0,NMP1
      IF ( mpstrt<=mp.AND.mp<=mpstop ) & 
     &  print *,"sub-init_plasma_grid: mp=",mp


!.. p coordinate (L-shell) is a single value along a flux tube 
!NOTE: in FLIP, PCO is only used in setting up the rough plasmasphere H+ initial profiles (See PROFIN). It does not have to be accurate.

!dbg20120112:      Pvalue(:) = zero
      apex_latitude_height_loop:   DO lp = 1,NLP

        IN => JMIN_IN(lp)
        IS => JMAX_IS(lp)

        IF (mp==NMP0)  CALL Get_Pvalue_Dipole ( r_meter2D(IN), plasma_grid_GL(IN), Pvalue(lp) )

!debug write
!nm20120123: IF ( sw_debug ) THEN
IF ( mpstrt<=mp.AND.mp<=mpstop .AND. lpstrt<=lp.AND.lp<=lpstop) THEN
print "('lp=',i6,'  IN=',i6,'  IS=',i6,'  NPTS=',i6)", lp,IN,IS,(IS-IN+1)
print "('r [m]      =',2E12.4)", r_meter2D(in),r_meter2D(is)
print "('G-LAT [deg]=',2f10.4)",(90.-plasma_grid_3d(in,mp)%GCOLAT*180./pi),(90.-plasma_grid_3d(is,mp)%GCOLAT*180./pi)
print "('M-LAT [deg]=',2f10.4)",(90.-plasma_grid_GL(in)*180./pi),(90.-plasma_grid_GL(is)*180./pi)
print "('GLON  [deg]=',2f10.4)",(plasma_grid_3d(in,mp)%GLON*180./pi),(plasma_grid_3d(is,mp)%GLON*180./pi)
print "('Qvalue     =',2E12.4)", plasma_grid_3d(in,mp)%Q, plasma_grid_3d(is,mp)%Q
print "('BM [Tesla]    =',2E12.4)", plasma_grid_3d(in,mp)%BM, plasma_grid_3d(is,mp)%BM
!print "('D1         =',2E12.4)", apexD(1,in,mp)%east, apexD(1,is,mp)%east
!print "('D2         =',2E12.4)", apexD(2,in,mp)%east, apexD(2,is,mp)%east
print "('D3         =',6E12.4)", apexD(3,in,mp)%east,apexD(3,in,mp)%north,apexD(3,in,mp)%up, apexD(3,is,mp)%east,apexD(3,is,mp)%north,apexD(3,is,mp)%up
print "('E1         =',2E12.4)", apexE(1,in,mp)%east, apexE(1,is,mp)%east
print "('E2         =',2E12.4)", apexE(2,in,mp)%east, apexE(2,is,mp)%east
print "('Be3 [T] NH/SH  =',2E12.4)", Be3(1,mp,lp), Be3(2,mp,lp)

print "('SL [m]     =',4E13.5)", plasma_grid_3d(in:in+1,mp)%SL, plasma_grid_3d(is-1:is,mp)%SL
print "('Z  [m]     =',4E13.5)",  plasma_grid_Z(in:in+1),  plasma_grid_Z(is-1:is)
print "('Pvalue     =',F10.4)", Pvalue(lp)
END IF !( sw_debug ) THEN


! assuming Newtonian gravity: G0 is gravity at the sea level (z=0) 
!NOTE: positive in NORTHern hemisphere; negative in SOUTHern hemisphere
         flux_tube: DO i=IN,IS

!dbg20110831
!d print *,'calling sub-Get_sinI'&
!d &, i,mp,lp,sw_sinI, sinI&
!d &, plasma_grid_GL(i), apexD(3,i,mp)%east, apexD(3,i,mp)%north, apexD(3,i,mp)%up

           CALL Get_sinI ( sw_sinI, sinI, plasma_grid_GL(i) &
     &, apexD(3,i,mp)%east, apexD(3,i,mp)%north, apexD(3,i,mp)%up ) 
           plasma_grid_3d(i,mp)%GR  =  G0 * ( earth_radius * earth_radius ) / ( r_meter2D(i) * r_meter2D(i) ) * sinI * (-1.0)

!IF ( sw_debug )  print "(4E12.4)", Z_meter(i,mp),sinI, (G0 * ( earth_radius * earth_radius ) / ( r_meter2D(i) * r_meter2D(i) )),  GR_mks(i,mp)
        
         END DO flux_tube

IF ( sw_debug )  then
  if ( sw_sinI==0 ) then
    print *,'sinI: flip'
  else if ( sw_sinI==1 ) then
    print *, 'sinI: APEX'
  endif
  print "('GRavity[m2 s-1]=',4E12.4)",plasma_grid_3d(in:in+2,mp)%GR,plasma_grid_3d(is,mp)%GR
END IF

!debug20110314
if( sw_debug .and. mp==1 .and. lp>=lpstrt .and. lp<=lpstop ) then
print *,'lp=',lp,' in=',in,' is=',is,(is-in+1),(90.-plasma_grid_GL(in)*180./pi)
endif !(mp==1) then

!explicitly disassociate the pointers
         NULLIFY (IN,IS)

       END DO apex_latitude_height_loop   !: DO lp = 1,NLP
     END DO apex_longitude_loop         !: DO mp = NMP0,NMP1 

     mlon_rad(:) = zero
     DO mp = 1,NMP_all+1 
       mlon_rad(mp) = REAL( (mp-1),real_prec ) * dlonm90km *pi/180.00
     END DO
if ( sw_debug ) print *,'mlon_rad[deg]',mlon_rad*180.0/pi


        END SUBROUTINE init_plasma_grid
!---------------------------
!20110726: the new GLOBAL 3D version: NMP=80
! global grid with the low resolution version
! magnetic longitude used for the grid. from 0 to 355.5 with 4.5 degree interval

      SUBROUTINE read_plasma_grid_global ( r_meter2D )
        USE module_IPE_dimension,ONLY: NPTS2D,NMP_all,NLP_all
        USE module_physical_constants,ONLY: earth_radius,pi,zero
        USE module_input_parameters,ONLY:read_input_parameters,sw_debug,lpstrt
        USE module_IO,ONLY: filename,LUN_pgrid
        IMPLICIT NONE

!        integer (kind=int_prec), parameter :: NMP=80
!        integer (kind=int_prec), parameter :: NLP=170
!        integer (kind=int_prec), parameter :: NPTS2D=44438 
!        real(kind=8) gr_2d(npts2,nmp)
!        real(kind=8) gcol_2d(npts2,nmp)
!    real(kind=8) glon_2d(npts2,nmp)
!    real(kind=8) q_coordinate_2d(npts2,nmp)
!    real(kind=8) bcol_2d(npts2,nmp)
!    real(kind=8) Apex_D1_2d(3,npts2,nmp)
!    real(kind=8) Apex_D2_2d(3,npts2,nmp)
!    real(kind=8) Apex_D3_2d(3,npts2,nmp)
!    real(kind=8) Apex_E1_2d(3,npts2,nmp)
!    real(kind=8) Apex_E2_2d(3,npts2,nmp)
!    real(kind=8) Apex_grdlbm2_2d(3,npts2,nmp)
!    real(kind=8) integral_ds_2d(npts2,nmp)
!    real(kind=8) apex_BMAG_2d(npts2,nmp)
!    real(kind=8)  Apex_BE3_N(nmp,nlp), Apex_BE3_S(nmp,nlp)

!-------------
!... read in parameters
      INTEGER(KIND=int_prec), DIMENSION(NMP_all,NLP_all) :: JMIN_IN_all,JMAX_IS_all  !.. first and last indices on field line grid

      REAL(KIND=real_prec), DIMENSION(NPTS2D,NMP_all) ::  dum0     !.. distance from the center of the Earth[meter]
      REAL(KIND=real_prec), DIMENSION(NPTS2D,NMP_all) ::  dum1  !.. geographic co-latitude [rad]
      REAL(KIND=real_prec), DIMENSION(NPTS2D,NMP_all) ::  dum2    !.. geographic longitude [rad]
      REAL(KIND=real_prec), DIMENSION(NPTS2D,NMP_all) ::  dum3
!dbg20110927      REAL(KIND=real_prec), DIMENSION(NPTS2D,NMP_all) ::  GL_rad_all      !.. magnetic co-latitude Eq(6.1) [rad]
!dbg20110927      REAL(KIND=real_prec), DIMENSION(NPTS2D,NMP_all) ::  SL_meter_all  !.. distance of point from northern hemisphere foot point [meter]
!dbg20110927      REAL(KIND=real_prec), DIMENSION(NPTS2D,NMP_all) ::  BM_T_all      !.. magnetic field strength [T]
! components (east, north, up) of base vectors
      REAL(KIND=real_prec), DIMENSION(3,NPTS2D,NMP_all) ::  dum4    !.. Eq(3.8) Richmond 1995
      REAL(KIND=real_prec), DIMENSION(3,NPTS2D,NMP_all) ::  dum5    !.. Eq(3.9) Richmond 1995
      REAL(KIND=real_prec), DIMENSION(3,NPTS2D,NMP_all) ::  dum6    !.. Eq(3.10) Richmond 1995
!dbg20110927      REAL(KIND=real_prec), DIMENSION(3,NPTS2D,NMP_all) ::  E1_all    !.. Eq(3.11) Richmond 1995
!dbg20110927      REAL(KIND=real_prec), DIMENSION(3,NPTS2D,NMP_all) ::  E2_all    !.. Eq(3.12) Richmond 1995
      REAL(KIND=real_prec), DIMENSION(2,NMP_all,NLP_all) ::  Be3_all         ! .. Eq(4.13) Richmond 1995 at Hr=90km in the NH(1)/SH(2) foot point [T]

!-------------local
        CHARACTER (LEN=11) :: FORM_dum
        CHARACTER (LEN=7)  :: STATUS_dum
        REAL(KIND=real_prec), DIMENSION(NPTS2D),INTENT(OUT) ::  r_meter2D     !.. distance from the center of the Earth[meter]
        CHARACTER(LEN=*), PARAMETER :: filepath_pgrid= &
!     & '../../field_line_grid/20110419lowres_global/'  !20110419 low res global grid
     &  './'
        CHARACTER(LEN=*), PARAMETER :: filename_pgrid= &
!     &  'GIP_apex_coords_global_lowresCORRECTED'        !20110824: corrected for lp=1-6
     &  'ipe_grid'        !20110824: corrected for lp=1-6

!dbg      INTEGER(KIND=int_prec) :: sw_test_grid=0  !1: ON testgrid; 0: OFF 
!---

! array initialization
      JMIN_IN(:) = -999
      JMAX_IS(:) = -999
      r_meter2D(:) = zero
      plasma_grid_3d(:,:)%GCOLAT = zero
      plasma_grid_3d(:,:)%GLON   = zero
      plasma_grid_3d(:,:)%Q      = zero
      plasma_grid_GL(:  )        = zero
      plasma_grid_3d(:,:)%SL     = zero
      plasma_grid_3d(:,:)%BM     = zero
      apexD(:,:,:)%east  = zero
      apexD(:,:,:)%north = zero
      apexD(:,:,:)%up    = zero
      apexE(:,:,:)%east  = zero
      apexE(:,:,:)%north = zero
      apexE(:,:,:)%up    = zero
      Be3(:,:,:) = zero



      filename =filepath_pgrid//filename_pgrid
      FORM_dum ='formatted' 
      STATUS_dum ='old'
      CALL open_file ( filename, LUN_pgrid, FORM_dum, STATUS_dum ) 
 
      print *,"open file completed"
      READ (UNIT=LUN_pgrid, FMT=*) JMIN_IN_all, JMAX_IS_all  !IN_2d_3d , IS_2d_3d
JMIN_IN(          1:NLP)=JMIN_IN_all(            1,1:NLP)
JMAX_IS(          1:NLP)=JMAX_IS_all(            1,1:NLP)
      print *,"reading JMIN_IN etc completed"
      READ (UNIT=LUN_pgrid, FMT=*) dum0, dum1, dum2, dum3 !gr_2d, gcol_2d, glon_2d, q_coordinate_2d
r_meter2D(     1:NPTS2D                 ) = dum0(1:NPTS2D,1        ) !r_meter
plasma_grid_3d(1:NPTS2D,NMP0:NMP1)%GCOLAT = dum1(1:NPTS2D,NMP0:NMP1) !GCOLAT
plasma_grid_3d(1:NPTS2D,NMP0:NMP1)%GLON   = dum2(1:NPTS2D,NMP0:NMP1) !GLON
plasma_grid_3d(1:NPTS2D,NMP0:NMP1)%Q      = dum3(1:NPTS2D,NMP0:NMP1) !Q

      print *,"reading r_meter etc completed"
      READ (UNIT=LUN_pgrid, FMT=*) dum0          !bcol_2d
plasma_grid_GL(1:NPTS2D)     =  dum0(1:NPTS2D,1) !GL

      print *,"reading GL_rad etc completed"
      READ (UNIT=LUN_pgrid, FMT=*) dum0, dum1 !integral_ds_2d, apex_BMAG_2d
plasma_grid_3d(1:NPTS2D,NMP0:NMP1)%SL     =dum0(1:NPTS2D,NMP0:NMP1) !SL
plasma_grid_3d(1:NPTS2D,NMP0:NMP1)%BM     =dum1(1:NPTS2D,NMP0:NMP1) !BM
      print *,"reading SL_meter etc completed"
      READ (UNIT=LUN_pgrid, FMT=*) dum4, dum5, dum6      !Apex_D1_2d
!D2
!dbg20110923  apexD(1,1:NPTS2D,NMP0:NMP1)%east  =  dum4(1,1:NPTS2D,NMP0:NMP1) !D1
!dbg20110923  apexD(1,1:NPTS2D,NMP0:NMP1)%north =  dum4(2,1:NPTS2D,NMP0:NMP1)
!dbg20110923  apexD(1,1:NPTS2D,NMP0:NMP1)%up    =  dum4(3,1:NPTS2D,NMP0:NMP1)
!D2
!dbg20110923  apexD(2,1:NPTS2D,NMP0:NMP1)%east  =  dum5(1,1:NPTS2D,NMP0:NMP1) !D2
!dbg20110923  apexD(2,1:NPTS2D,NMP0:NMP1)%north =  dum5(2,1:NPTS2D,NMP0:NMP1)
!dbg20110923  apexD(2,1:NPTS2D,NMP0:NMP1)%up    =  dum5(3,1:NPTS2D,NMP0:NMP1)
!D3
  apexD(3,1:NPTS2D,NMP0:NMP1)%east  =  dum6(1,1:NPTS2D,NMP0:NMP1) !D3
  apexD(3,1:NPTS2D,NMP0:NMP1)%north =  dum6(2,1:NPTS2D,NMP0:NMP1)
  apexD(3,1:NPTS2D,NMP0:NMP1)%up    =  dum6(3,1:NPTS2D,NMP0:NMP1)
      print *,"reading D1-3 etc completed"
      READ (UNIT=LUN_pgrid, FMT=*) dum4, dum5          !Apex_E1_2d
!E1
  apexE(1,1:NPTS2D,NMP0:NMP1)%east  =  dum4(1,1:NPTS2D,NMP0:NMP1) !E1
  apexE(1,1:NPTS2D,NMP0:NMP1)%north =  dum4(2,1:NPTS2D,NMP0:NMP1)
  apexE(1,1:NPTS2D,NMP0:NMP1)%up    =  dum4(3,1:NPTS2D,NMP0:NMP1)
!E2
  apexE(2,1:NPTS2D,NMP0:NMP1)%east  =  dum5(1,1:NPTS2D,NMP0:NMP1) !E2
  apexE(2,1:NPTS2D,NMP0:NMP1)%north =  dum5(2,1:NPTS2D,NMP0:NMP1)
  apexE(2,1:NPTS2D,NMP0:NMP1)%up    =  dum5(3,1:NPTS2D,NMP0:NMP1)
      print *,"reading E1/2 etc completed"
      READ (UNIT=LUN_pgrid, FMT=*) Be3_all(1,1:NMP_all,1:NLP_all),Be3_all(2,1:NMP_all,1:NLP_all) !Apex_BE3_N
Be3(1:2,NMP0:NMP1,1:NLP)=    Be3_all(1:2,NMP0:NMP1,1:NLP)
      print *,"reading Be3 etc completed"
      CLOSE(UNIT=LUN_pgrid)
      print *,"global grid reading finished, file closed..."


!dbg20110811:
!dbg IF ( sw_test_grid==1 ) THEN

!dbg  CALL test_grid_output ( JMIN_IN_all,JMAX_IS_all,r_meter_all,SL_meter_all,BM_T_all,GL_rad_all &
!dbg & ,GCOLAT_all,GLON_all,Qvalue_all,D1_all,D2_all,D3_all,E1_all,E2_all,Be3_all &
!dbg &,filepath_pgrid,filename_pgrid)
!dbg END IF 

      END SUBROUTINE  read_plasma_grid_global
!---
!20110927:test_grid_output deleted
!---------------------------
      END MODULE module_FIELD_LINE_GRID_MKS