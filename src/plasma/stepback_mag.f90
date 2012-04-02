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
      SUBROUTINE stepback_mag (mp,lp &
!d     &, phi_t1 &
!d     &, theta_t1 &
     &, phi_t0 , theta_t0 )
      USE module_precision
      USE module_eldyn,ONLY: Ed1_90,Ed2_90,coslam_m,lpconj
      USE module_FIELD_LINE_GRID_MKS,ONLY: Be3,mlon_rad,plasma_grid_GL,JMIN_IN,JMAX_IS,ht90,plasma_grid_Z  !,apexE, geographic_coords
      USE module_physical_constants,ONLY: earth_radius,rtd,pi
!      USE cons_module,ONLY: h0 !potential solver reference height[cm] =90km
      USE module_input_parameters,ONLY: time_step,sw_debug
      IMPLICIT NONE
! INPUT
      INTEGER (KIND=int_prec), INTENT(IN) :: mp  !mag-lon index
      INTEGER (KIND=int_prec), INTENT(IN) :: lp  !mag-lat index
!      REAL(KIND=real_prec), INTENT(IN) :: DT  ! time step [second]      
      REAL(KIND=real_prec),POINTER  :: phi_t1  !magnetic longitude,phi at T1
      REAL(KIND=real_prec) :: theta_t1(2)!magnetic latitude,theta at T1
! OUTPUT
      REAL(KIND=real_prec), INTENT(OUT) :: phi_t0(2)!magnetic longitude,phi[rad] at T0
      REAL(KIND=real_prec), INTENT(OUT) :: theta_t0(2) !magnetic latitude,theta[rad] at T0
!---local variables---
      REAL(KIND=real_prec) :: v_e(2)  !1:ed2/be3 (4.18) ;2: -ed1/be3 (4.19)
      REAL(KIND=real_prec) :: sinLambda_m  !
      REAL(KIND=real_prec) :: cos2Lambda_m  ! 
      REAL(KIND=real_prec) :: sinIm !eq(3.7) 
! these are geographic
!      TYPE(geographic_coords) :: VEXB !EXB velocity [m s-1] eq(4.17)
      REAL(KIND=real_prec) :: v_e2magsouth !EXB converted to positive:mag-southward
      REAL(KIND=real_prec) :: r !meter
      INTEGER (KIND=int_prec) :: ihem !1:NH; 2:SH
      INTEGER (KIND=int_prec) :: lp0,ift
      REAL(KIND=real_prec) :: r_apex,sintheta,sin2theta,r_apex_dipole,r0_apex
      INTEGER (KIND=int_prec) :: midpoint
!---------------
!dbg
phi_t1 => mlon_rad(mp)
theta_t1(1) = plasma_grid_GL( JMIN_IN(lp) ) !NH
theta_t1(2) = plasma_grid_GL( JMAX_IS(lp) ) !SH


!NOTE: electric fields do not have to be equal at both ends of the flux tubes
!    : transport problem over the poles
      r = earth_radius + ht90 ![m]

      which_hemisphere: DO ihem=1,2 !ihem_max
!lp0 is used for array(NLP*2)
        IF ( ihem==1 ) THEN
          lp0 = lpconj(lp) !NH
          ift = JMIN_IN(lp)
        ELSE IF ( ihem==2 ) THEN
          lp0 = lp !SH
          ift = JMAX_IS(lp)
        END IF

! Ed1/2[V/m] at ( phi_t1(mp), theta_t1(lp) ), Be3[T]
        v_e(1) =   Ed2_90(mp,lp0) / Be3(ihem,mp,lp) !(4.18) +mag-east(d1?) 
        v_e(2) = - Ed1_90(mp,lp0) / Be3(ihem,mp,lp) !(4.19) +down/equatorward(d2?)
        
!dbg
if(sw_debug) &
& print *,'sub-St:',ihem,'ve2[m/s]',v_e(2),'ed1[mV/m]', Ed1_90(mp,lp0)*1.0E+3,' be3[tesla]',Be3(ihem,mp,lp) 
!dbg ,' BM-N',plasma_grid_3d( JMIN_IN(mp,lp) ,mp)%BM,' BM-S',plasma_grid_3d( JMAX_IS(mp,lp) ,mp)%BM


! calculate ExB drift (4.17) at IN/IS foot point
!CAUTION! these are geographic
!VEXB%east  = (v_e(1) * apexE(1,ift,mp)%east)  + (v_e(2) * apexE(2,ift,mp)%east)
!VEXB%north = (v_e(1) * apexE(1,ift,mp)%north) + (v_e(2) * apexE(2,ift,mp)%north)
!VEXB%up    = (v_e(1) * apexE(1,ift,mp)%up)    + (v_e(2) * apexE(2,ift,mp)%up)
!print *,'VEXB[m/s]',VEXB !%east,VEXB%north,VEXB%up

! assume Lambda_m in Richmond 95 equals to theta_t1
        cos2Lambda_m = coslam_m(lp0) * coslam_m(lp0) ! 0<cos2<1
        IF ( ihem==1 ) THEN
          sinLambda_m  = + SQRT( 1.0 - cos2Lambda_m )  !>0 ---NH 
        ELSE IF ( ihem==2 ) THEN 
          sinLambda_m  = - SQRT( 1.0 - cos2Lambda_m )  !<0 ---SH 
        END IF
        sinIm = 2.0 * sinLambda_m / SQRT(4.0-3.0*cos2Lambda_m)
        v_e2magsouth = v_e(2) * sinIm
if(sw_debug)&
& print *,'sub-St:',ihem,'v_e2*sinI[m/s]',v_e2magsouth,' sinI',sinIm

        theta_t0(ihem) = theta_t1(ihem) - ( v_e2magsouth * time_step) / r
        phi_t0(ihem)   = phi_t1
!make sure that:  0*dtr<=theta<=180*dtr=pi, otherwise goes over to the other side of the poles
        IF ( theta_t0(ihem)<0.0  ) THEN
          theta_t0(ihem) = theta_t0(ihem) * (-1.0)
          phi_t0(ihem)   = phi_t0(ihem) + pi  !other side
        ELSE IF ( theta_t0(ihem)>pi   ) THEN
          theta_t0(ihem) = pi*2.0 - theta_t0(ihem)
          phi_t0(ihem)   = phi_t0(ihem) + pi  !other side
        END IF
         
        phi_t0(ihem)   = phi_t0(ihem) - ( v_e(1) * time_step ) / ( r * sinLambda_m )
!make sure that:  0*dtr<=phi<360*dtr=2pi
        IF ( phi_t0(ihem)>=pi*2.0 ) THEN 
          phi_t0(ihem) = phi_t0(ihem) - pi*2.0
        ELSE IF ( phi_t0(ihem)< 0.0    ) THEN 
          phi_t0(ihem) = phi_t0(ihem) + pi*2.0
        END IF

      END DO which_hemisphere !: DO ihem=1,2

!if(sw_debug) then
if(lp==130) then
!sintheta=SIN(theta)
!sin2theta = sintheta*sintheta 
!r0_apex = r/sin2theta 
ihem=1 !only
if(sw_debug) print *,mlon_rad(mp)
midpoint = JMIN_IN(lp) + ( JMAX_IS(lp) - JMIN_IN(lp) )/2
r_apex = earth_radius + plasma_grid_Z(midpoint) ![m]

sintheta=SIN( theta_t1(ihem) )
sin2theta = sintheta*sintheta 
r_apex_dipole = r/sin2theta 
if(sw_debug) print "('sub-St:T1: phi=',F12.6,' theta=',F12.6,' r=',2E13.5)",phi_t1*rtd,(90.-theta_t1(ihem)*rtd)     ,r_apex_dipole,r_apex

sintheta=SIN( theta_t0(ihem) )
sin2theta = sintheta*sintheta 
r0_apex = r/sin2theta 
if(sw_debug) print "('sub-St:T0: phi=',F12.6,' theta=',F12.6,' r=',E13.5)",phi_t0(ihem)*rtd,(90.-theta_t0(ihem)*rtd),r0_apex
if(sw_debug) print "(4E12.4)", (theta_t1(ihem)-theta_t0(ihem))*rtd, (r_apex_dipole-r0_apex), (( v_e2magsouth * time_step) / r) , ( v_e2magsouth * time_step)
end if

NULLIFY(phi_t1)
      END SUBROUTINE stepback_mag

      SUBROUTINE stepback_mag_R (utime,mp,lp &
     &, phi_t0 , theta_t0, r0_apex )
      USE module_precision
      USE module_eldyn,ONLY: Ed1_90,Ed2_90,lpconj
      USE module_FIELD_LINE_GRID_MKS,ONLY: Be3,mlon_rad,plasma_grid_Z,JMIN_IN,JMAX_IS,ht90,apexE,plasma_grid_GL,plasma_grid_3d
      USE module_physical_constants,ONLY: earth_radius,rtd,pi
      USE module_input_parameters,ONLY: time_step,sw_exb_up,sw_debug,lpstrt,lpstop,mpstrt,mpstop,start_time,lpmin_perp_trans
      USE module_plasma,ONLY: VEXBup
      IMPLICIT NONE
! INPUT
      INTEGER (KIND=int_prec), INTENT(IN) :: utime !universal time [sec]
      INTEGER (KIND=int_prec), INTENT(IN) :: mp  !mag-lon index
      INTEGER (KIND=int_prec), INTENT(IN) :: lp  !mag-lat index
! OUTPUT
      REAL(KIND=real_prec), INTENT(OUT) :: phi_t0(2)!magnetic longitude,phi[rad] at T0
      REAL(KIND=real_prec), INTENT(OUT) :: theta_t0(2) !magnetic latitude,theta[rad] at T0
      REAL(KIND=real_prec), INTENT(OUT) :: r0_apex ![meter]
! local
      REAL(KIND=real_prec),POINTER  :: phi_t1  !magnetic longitude,phi at T1
      REAL(KIND=real_prec) :: theta_t1(2)!magnetic latitude,theta at T1
      INTEGER (KIND=int_prec) :: midpoint, midpoint_min,midpoint_max
      REAL(KIND=real_prec) :: v_e(2)   !1:ed2/be3 (4.18) ;2: -ed1/be3 (4.19)
      REAL(KIND=real_prec) :: r ,r_apex,  sin2theta,sintheta,theta  !meter
      INTEGER (KIND=int_prec) :: ihem !1:NH; 2:SH
      INTEGER (KIND=int_prec) :: lp0,ift
      REAL(KIND=real_prec) :: GLON_deg, LT_SEC
!
      phi_t1 => mlon_rad(mp)
      theta_t1(1) = plasma_grid_GL( JMIN_IN(lp) ) !NH
      theta_t1(2) = plasma_grid_GL( JMAX_IS(lp) ) !SH


      r = earth_radius + ht90 ![m]
      midpoint = JMIN_IN(lp) + ( JMAX_IS(lp) - JMIN_IN(lp) )/2
      r_apex = earth_radius + plasma_grid_Z(midpoint) ![m]
if(sw_debug) print *,'sub-StR:',mp,lp,r,r_apex,plasma_grid_Z(midpoint)

!note: for the moment, Ed1/B is calculated only in NH, assuming that the flux tube is moving with the same velocity between N/SH.
      which_hemisphere: DO ihem=1,1 !ihem_max
!lp0 is used for array(NLP*2)
        IF ( ihem==1 ) THEN
          lp0 = lpconj(lp) !NH
        ELSE IF ( ihem==2 ) THEN
          lp0 = lp !SH
        END IF

        
       IF ( sw_exb_up<=1 ) THEN 

! (0) self consistent electrodynamics
!...comming soon...

! (1) WACCM E empirical model
! Ed1/2[V/m] at ( phi_t1(mp), theta_t1(lp) ), Be3[T]
!note: Be3 should be constant along a magnetic field!!! 
        v_e(1) =   Ed2_90(mp,lp0) / Be3(ihem,mp,lp) !(4.18) +mag-east(d1?) 
        v_e(2) = - Ed1_90(mp,lp0) / Be3(ihem,mp,lp) !(4.19) +down/equatorward(d2?)
if(sw_debug)&
& print *,'sub-StR:',ihem,'ve2[m/s]',v_e(2),'ed1[mV/m]', Ed1_90(mp,lp0)*1.0E+3,' be3[tesla]',Be3(ihem,mp,lp) 

        VEXBup(mp,lp) = (v_e(1) * apexE(1,midpoint,mp)%up)    + (v_e(2) * apexE(2,midpoint,mp)%up)

!dbg20120301:temp solution: make sure flux tube does not go beyond the sim region...
if ( lp==lpstrt.or.lp==lpstop ) then
 VEXBup(mp,lp) = 0.0
endif

if(sw_debug)&
& print *,'sub-StR:' &
&, v_e(1),apexE(1,midpoint,mp)%up,v_e(2),apexE(2,midpoint,mp)%up

        ELSE IF ( sw_exb_up==2 ) THEN 

!(2) GIP empirical model

        ELSE IF ( sw_exb_up==3 ) THEN 

!(3)  SUPIM empirical model: 
!note: becomes zero at R=4000km

          GLON_deg = plasma_grid_3d(midpoint,mp)%GLON*180./pi
          LT_SEC = utime + GLON_deg/15.*3600.
          IF ( LT_SEC>=86400.)  LT_SEC=LT_SEC-86400.
          IF ( LT_SEC<     0.)  LT_SEC=LT_SEC+86400.
          CALL supim_EXBV(utime,lp,LT_SEC,r_apex,GLON_deg,VEXBup(mp,lp))

        ELSE IF ( sw_exb_up==4 ) THEN 

!(4) zero for debug purpose
          VEXBup(mp,lp) = 0.0   !dbg20111101:v8

        ELSE IF ( sw_exb_up==5 ) THEN 
!(5) read in from a file
          if ( mp==mpstrt.and.lp==lpmin_perp_trans.and.MOD( (utime-start_time),900 )==0 )    CALL read_vexb ( utime,lp,mp )

        END IF !ELSE IF ( sw_exb_up==3 ) THEN 

!if(sw_debug)&
! print *,'sub-StR:',ihem,mp,lp,'v_exb_apex[m/s]',VEXBup(mp,lp)  ,utime


        r0_apex = r_apex - VEXBup(mp,lp) * time_step
if(sw_debug)&
& print *,'sub-StR:',r_apex,' r0 apex[m/s]',r0_apex

!dbbg20120301: temporary solution to keep flux tube within the sim region, instead of stopping
midpoint_min = JMIN_IN(lpstop) + ( JMAX_IS(lpstop) - JMIN_IN(lpstop) )/2
midpoint_max = JMIN_IN(lpstrt)  + ( JMAX_IS(lpstrt)  - JMIN_IN(lpstrt) )/2
if ( r0_apex<(plasma_grid_Z(midpoint_min)+earth_radius) ) then
   print *,'!r0_apex too small!',r0_apex,VEXBup(mp,lp),mp,lp, (plasma_grid_Z(midpoint_min)+earth_radius)
   r0_apex = plasma_grid_Z(midpoint_min)+earth_radius
else if ( r0_apex>(plasma_grid_Z(midpoint_max)+earth_radius) ) then
   print *,'!r0_apex too big!',r0_apex, VEXBup(mp,lp),mp,lp, (plasma_grid_Z(midpoint_max)+earth_radius)
   r0_apex = plasma_grid_Z(midpoint_max)+earth_radius
end if
!dbg20120301:
        sin2theta = r/r0_apex
        sintheta = SQRT( sin2theta )
        theta    = ASIN ( sintheta )
if(sw_debug) print *,'SIN',sin2theta,sintheta,theta,' mlat R0[deg]', (90.-  theta*180./pi)

        if ( ihem==1 ) then
           theta_t0(ihem) = pi*0.50 - ACOS ( sintheta )
        else if ( ihem==2 ) then
           theta_t0(ihem) = pi*0.50 + ACOS ( sintheta )
        end if

!temporary solution...
        phi_t0(ihem)   = phi_t1
END DO      which_hemisphere !: DO ihem=1,ihem_max



ihem=1 !only
if(sw_debug) print *,mp,lp, 'Z(mp,lp)',plasma_grid_Z(midpoint), (plasma_grid_Z(midpoint)+earth_radius)
if(sw_debug) print *, 'mlatN(mp,lp)',90.-plasma_grid_GL( JMIN_IN(lp) )*180./pi !NH
sin2theta = r/( earth_radius+plasma_grid_Z(midpoint) )
sintheta = SQRT( sin2theta )
theta_t1(ihem)    = ASIN ( sintheta )
if(sw_debug) print *,'DIPOLE',sin2theta,sintheta,theta_t1(ihem),' mlat NH[deg]', (90.-  theta_t1(ihem)*180./pi)


if(sw_debug) print "('sub-StR:T1: phi=',F12.6,' theta=',F12.6,' r=',E13.5)",phi_t1*rtd,      (90.-theta_t1(ihem)*rtd), r_apex
if(sw_debug) print "('sub-StR:T0: phi=',F12.6,' theta=',F12.6,' r=',E13.5)",phi_t0(ihem)*rtd,(90.-theta_t0(ihem)*rtd), r0_apex
if(sw_debug) print "(3E12.4)", (theta_t1(ihem)-theta_t0(ihem))*rtd, (r_apex-r0_apex), (VEXBup(mp,lp) * time_step)


      END SUBROUTINE stepback_mag_R