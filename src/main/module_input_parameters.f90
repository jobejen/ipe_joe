!note:20120207: v36: used only activating the perp.transport gradually...
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
      MODULE module_input_parameters
      USE module_precision
      USE module_IPE_dimension,ONLY: NLP,NMP
      IMPLICIT NONE

!--- IPE wide run parameters
      INTEGER (KIND=int_prec), PUBLIC   :: start_time  !=0  !UT[sec]
      INTEGER (KIND=int_prec), PUBLIC   :: stop_time   !=60 !UT[sec]
      INTEGER (KIND=int_prec), PUBLIC   :: time_step   !=60 ![sec]
      INTEGER (KIND=int_prec), PUBLIC   :: nprocs=1    !Number of processors
      INTEGER (KIND=int_prec), PUBLIC   :: HaloSize=99 !Halo size (big number=NOP for serial)

      REAL (KIND=real_prec), PUBLIC :: F107D   !.. Daily F10.7
      REAL (KIND=real_prec), PUBLIC :: F107AV  !.. 81 day average F10.7
!
      INTEGER (KIND=int_prec), PUBLIC :: NYEAR ! year
      INTEGER (KIND=int_prec), PUBLIC :: NDAY  ! day number

      INTEGER (KIND=int_prec), PUBLIC :: ip_freq_output  ![sec] must be multiple of time_step
      INTEGER (KIND=int_prec), PUBLIC :: ip_freq_msis    !frequency[sec] to call MSIS/HWM: default 15min
!--- FLIP specific input parameters
      REAL (KIND=real_prec), PUBLIC :: DTMIN_flip  !.. Minimum time step allowed (&=10 secs?)
      INTEGER (KIND=int_prec),PUBLIC :: sw_INNO  !.. switch to turn on FLIP NO calculation if <0
      REAL (KIND=real_prec), PUBLIC :: FPAS_flip   !.. Pitch angle scattering fraction
      REAL (KIND=real_prec), PUBLIC :: HPEQ_flip   !.. Sets initial equatorial [H+][cm-3] if positive
      REAL (KIND=real_prec), PUBLIC :: HEPRAT_flip !.. Initial He+/H+ ratio (.01 to 1.0)
      REAL (KIND=real_prec), PUBLIC :: COLFAC_flip !.. O+ - O collision frequency Burnside factor (1.0 to 1.7)

      INTEGER (KIND=int_prec),PUBLIC :: sw_TEI    !.. switches Te/Ti solutions ON if > 0
      INTEGER (KIND=int_prec),PUBLIC :: sw_OHPLS  !.. switches O+/H+ solutions ON if > 0

      INTEGER (KIND=int_prec),PUBLIC :: sw_IHEPLS !.. switches He+ diffusive solutions on if > 0
      INTEGER (KIND=int_prec),PUBLIC :: sw_INPLS  !.. switches N+ diffusive solutions on if > 0
      INTEGER (KIND=int_prec),PUBLIC :: sw_wind_flip  !.. switch for neutral wind input to FLIP: 1:ON; 0:ZERO wind
      INTEGER (KIND=int_prec),PUBLIC :: sw_depleted_flip  !.. switch for depleted flux tube in FLIP: 1:ON; 0:OFF 
      INTEGER (KIND=int_prec),PUBLIC :: start_time_depleted !.. time UT to start to deplete the flux tube
      INTEGER,PUBLIC :: sw_neutral_heating_flip  !.. switch for neutral heating calculation in FLIP: 1:ON; 0:OFF
      REAL (KIND=real_prec), PUBLIC :: init_Te_max !.. max Te[K] in the initial profile
      INTEGER, PUBLIC :: sw_DEBUG_flip           !.. switch to turn on debug writes:0=off; 1=on for solver
      INTEGER, PUBLIC :: sw_ERSTOP_flip          !.. switch to turn on STOP in SUB-WRITE_EFLAG
!dbg20120301: N+ BAND solver issue
      LOGICAL, PUBLIC :: sw_LCE  !local chemical equilibruium below ht_LCE[km]
      REAL (KIND=real_prec), PUBLIC :: ht_LCE !.. max ht[km] for LCE
      REAL (KIND=real_prec), PUBLIC :: ZLBNP_inp !.. ZLBNP
!dbg20120304:
      REAL (KIND=real_prec), PUBLIC :: FNFAC_flip !.. FNFAC in RSPRIM.FOR

!--- MSIS/HWM specific input parameters
      REAL (KIND=real_prec), DIMENSION(7), PUBLIC :: AP   ! magnetic index(daily)
!.. MSIS: or when sw(9)=-1. :                 
!           - array containing:                                         
!             (1) daily ap                                              
!             (2) 3 hr ap index for current time                        
!             (3) 3 hr ap index for 3 hrs before current time           
!             (4) 3 hr ap index for 6 hrs before current time           
!             (5) 3 hr ap index for 9 hrs before current time           
!             (6) average of eight 3 hr ap indicies from 12 to 33 hrs pr
!                    to current time                                    
!             (7) average of eight 3 hr ap indicies from 36 to 57 hrs pr
!                    to current time 
!.. HWM:        ap - two element array with                                    
!             ap(1) = magnetic index(daily) (use 4 in lower atmos.)     
!             ap(2)=current 3hr ap index (used only when sw(9)=-1.) 
!
!--- ELDYN specific input parameters
      REAL (KIND=real_prec), PUBLIC :: kp_eld   ! geomagnetic index
!--- all the SWITCHes either integer or logical or character
      LOGICAL, PUBLIC :: sw_debug
      LOGICAL, PUBLIC :: sw_debug_mpi
      LOGICAL, PUBLIC :: sw_output_fort167
      INTEGER(KIND=int_prec), DIMENSION(2), PUBLIC :: iout
      INTEGER(KIND=int_prec), PUBLIC :: mpstop
      INTEGER(KIND=int_prec), PUBLIC :: sw_neutral    !0:GT; 1:MSIS
      INTEGER(KIND=int_prec), PUBLIC :: sw_pcp        !0:heelis; 1:weimer
      INTEGER(KIND=int_prec), PUBLIC :: sw_grid       !0:APEX; 1:FLIP
! if sw_grid=1 
!dbg20120304: nolonger used
!nm20120304      REAL (KIND=real_prec), PUBLIC :: PCO_flip  
!nm20120304      REAL (KIND=real_prec), PUBLIC :: BLON_flip 
      LOGICAL, PUBLIC :: sw_output_plasma_grid
!JFM  LOGICAL, PUBLIC :: sw_rw_sw_perp_trans
      LOGICAL, PUBLIC :: sw_dbg_perp_trans
      INTEGER(KIND=int_prec), PUBLIC :: sw_perp_transport 
!0:WITHOUT perpendicular transport
!1:THETA only transport included
!2:both THETA&PHI:transport included, NH/SH flux tubes are moving together with the same ExB drift
!3:both THETA&PHI:transport included, NH/SH flux tubes are moving separately with different ExB drift
! if sw_perp_tr=>1
      INTEGER (KIND=int_prec), PUBLIC :: lpmin_perp_trans !=15 :mlatN=78deg???
      INTEGER (KIND=int_prec), PUBLIC :: lpmax_perp_trans !=151:mlatN=5.64deg
      INTEGER (KIND=int_prec), PUBLIC :: record_number_plasma_start
      INTEGER (KIND=int_prec), PUBLIC :: sw_record_number
      INTEGER (KIND=int_prec), PUBLIC :: duration !used when sw_record_n=1
      INTEGER (KIND=int_prec), PUBLIC :: sw_exb_up
! (0) self consistent electrodynamics
! (1) WACCM E empirical model
! (2) GIP empirical model
! (3) SUPIM empirical model
      INTEGER(KIND=int_prec), PUBLIC :: sw_para_transport 
!0:WITHOUT parallel transport (no calling to flux tube solver)
!1:parallel transport included
      INTEGER(KIND=int_prec), PUBLIC :: sw_ksi
!0: ksi_factor=1.0---no compressional effect/no adiabatic heating
!1: ksi_factor from richards thesis---including compressional effect/adiabatic heating ,,,used until 20120314 with interpolate_ft.v16.f90
!2:20120330: new way of calculating the ksi_factor with interpolate_ft.v17.f90
      INTEGER(KIND=int_prec), PUBLIC :: sw_divv
!0: div * V//=0
!1: div * V// included in the Te/i solver
!dbg20120313 
      REAL(KIND=real_prec), PUBLIC :: fac_BM

      NAMELIST/NMIPE/start_time &
     &,stop_time &
     &,time_step &
     &,F107D   &
     &,F107AV  &
     &,NYEAR  &
     &,NDAY   &
     &,ip_freq_output &
     &,ip_freq_msis
      NAMELIST/NMFLIP/DTMIN_flip  & 
     &,sw_INNO   & 
     &,FPAS_flip   & 
     &,HPEQ_flip   & 
     &,HEPRAT_flip & 
     &,COLFAC_flip & 
     &,sw_TEI &
     &,sw_OHPLS &
     &,sw_IHEPLS &
     &,sw_INPLS  &
     &,sw_wind_flip &
     &,sw_depleted_flip &
     &,start_time_depleted &
     &,sw_neutral_heating_flip &
     &,init_Te_max &
     &,sw_DEBUG_flip &
     &,sw_ERSTOP_flip &
     &,sw_LCE &
     &,ht_LCE &
     &,ZLBNP_inp &
     &,FNFAC_flip
      NAMELIST/NMMSIS/AP  &
     &,kp_eld
      NAMELIST/NMSWITCH/&
           &  sw_neutral     &
           &, sw_pcp         &
           &, sw_grid        &
           &, sw_output_plasma_grid        &
!JFM       &, sw_rw_sw_perp_trans &
           &, sw_dbg_perp_trans &
           &, sw_perp_transport &
           &, lpmin_perp_trans &
           &, lpmax_perp_trans &
           &, sw_exb_up &
           &, sw_para_transport &
           &, sw_ksi &
           &, sw_divv &
           &, mpstop  &
           &, NLP,NMP &
           &, sw_debug       &
           &, sw_debug_mpi   &
           &, sw_output_fort167   &
           &, record_number_plasma_start   &
           &, sw_record_number   &
           &, duration   &
           &, fac_BM   &
           &, iout

!nm20120304           &, PCO_flip       &
!nm20120304           &, BLON_flip      &


      PRIVATE
      PUBLIC :: read_input_parameters


      CONTAINS
!---------------------------
! initialise plasma grids
        SUBROUTINE read_input_parameters ( )
        USE module_IPE_dimension,ONLY: NLP,NMP,NPTS2D
        IMPLICIT NONE
!---------
        INTEGER(KIND=int_prec),PARAMETER :: LUN_nmlt=1
        CHARACTER(LEN=*),PARAMETER :: INPTNMLT='IPE.inp'
        INTEGER(KIND=int_prec) :: IOST_OP
        INTEGER(KIND=int_prec) :: IOST_RD
        INTEGER (KIND=int_prec), PARAMETER :: LUN_LOG0=10  !output4input parameters only
        CHARACTER (LEN=*), PARAMETER :: filename='logfile_input_params.log'
        INTEGER (KIND=int_prec) :: istat        

        OPEN(UNIT=LUN_LOG0,FILE=filename,STATUS='unknown',FORM='formatted',IOSTAT=istat)
        IF ( istat /= 0 ) THEN
          WRITE( UNIT=6, FMT=*)'ERROR OPENING FILE',filename
          STOP
        END IF

        OPEN(LUN_nmlt,FILE=INPTNMLT,ERR=222,IOSTAT=IOST_OP,STATUS='OLD')
        READ(LUN_nmlt,NML=NMIPE    ,ERR=222,IOSTAT=IOST_RD,END=111)
        READ(LUN_nmlt,NML=NMFLIP   ,ERR=222,IOSTAT=IOST_RD,END=111)
        READ(LUN_nmlt,NML=NMMSIS   ,ERR=222,IOSTAT=IOST_RD,END=111)
        READ(LUN_nmlt,NML=NMSWITCH ,ERR=222,IOSTAT=IOST_RD,END=111)

222     IF ( IOST_OP /= 0 ) THEN
          WRITE(UNIT=LUN_LOG0, FMT=*) "OPEN NAMELIST FAILED!", IOST_OP
          STOP
        ELSEIF ( IOST_RD /= 0 ) THEN
          WRITE(UNIT=LUN_LOG0, FMT=*) "READ NAMELIST FAILED!", IOST_RD
          STOP
        ENDIF

111     CONTINUE
        WRITE(UNIT=LUN_LOG0, NML=NMIPE)
        WRITE(UNIT=LUN_LOG0, NML=NMFLIP)
        WRITE(UNIT=LUN_LOG0, NML=NMMSIS)
        WRITE(UNIT=LUN_LOG0, NML=NMSWITCH)


WRITE(UNIT=LUN_LOG0,FMT=*)'NMP=',NMP,' NLP=',NLP,' NPTS2D=',NPTS2D

WRITE(UNIT=LUN_LOG0,FMT=*)'real_prec=',real_prec,' int_prec=',int_prec


        CLOSE(LUN_nmlt)
        CLOSE(LUN_LOG0)

stop_time=start_time+duration
!SMS$insert call NNT_NPROCS(nprocs)
print *,'finished reading namelist:',filename
print *,' '
print"(' NLP:                 ',I6)",NLP
print"(' NMP:                 ',I6)",NMP
print"(' mpstop:              ',I6)",mpstop
print"(' stop_time            ',I6)",stop_time
print"(' Number of Processors:',I6)",nprocs
print"(' HaloSize:            ',I6)",HaloSize

!dbg20120509        IF ( sw_rw_sw_perp_trans )  CALL setup_sw_perp_transport ()
!note:20120207: v36: used only activating the perp.transport gradually...

 
        END SUBROUTINE read_input_parameters

END MODULE module_input_parameters
