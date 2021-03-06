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
      MODULE module_NEUTRAL_MKS
      USE module_precision
      USE module_IPE_dimension,ONLY: NPTS2D,NLP,NMP
      USE module_FIELD_LINE_GRID_MKS,ONLY: ON_m3,HN_m3,N2N_m3,O2N_m3,HE_m3,N4S_m3,TN_k,TINF_k,Un_ms1
      USE module_input_parameters,ONLY : parallelBuild

      IMPLICIT NONE

! --- PUBLIC ---
!dbg20110516: temporary moved to module plasma because it is calculated by flip right now.
!      REAL(KIND=real_prec), dimension(NPTS2D,NMP), PUBLIC ::  NNO_m3


! follow APEX paper: components (east, north, up)
!t      REAL(KIND=real_prec), dimension(3,NPTS2D,NMP),PUBLIC  :: Un_ms1  !Ue1 Eq(5.6) in magnetic frame !1st dim: corresponds to apexD1-3
!dbg20110923: temporary reduce the array size for memory saving...

      PRIVATE
      PUBLIC :: neutral


      CONTAINS
!---------------------------
      subroutine neutral (utime) 
      USE module_IPE_dimension,ONLY: IPDIM
      use module_FIELD_LINE_GRID_MKS, only : plasma_grid_3d,plasma_grid_Z, apexD, JMIN_IN,JMAX_IS,east,north,up,ISL,IBM,IGR,IQ,IGCOLAT,IGLON,JMIN_ING,JMAX_ISG,WamField
      USE module_physical_constants,ONLY: pi,zero,earth_radius,g0,gscon,massn_kg
      USE module_input_parameters,ONLY: F107D,F107AV,AP,NYEAR,NDAY,sw_debug,mpstop,sw_grid,start_time,stop_time &
     &,sw_neutral, swNeuPar,mype
      USE module_unit_conversion,ONLY: M_TO_KM
      USE module_IO, ONLY:filename,FORM_dum,STATUS_dum,luntmp3
      USE module_open_file, ONLY:open_file
      implicit none

      INTEGER(KIND=int_prec), INTENT(in) :: utime  !universal time[sec]

      integer :: npts  !=IPDIM
      INTEGER(KIND=int_prec) :: IN, IS

      integer :: iyear, iday

      real(8) :: ut_hour 
      real(8) :: f107D_dum, f107A_dum 
      real(8),              dimension(IPDIM)   :: glon_deg, glat_deg, alt_km
      real(8),              dimension(7)       :: AP_dum
      REAL(KIND=real_prec), dimension(3,IPDIM) :: Vn_ms1  !geographic frame:1:east;2:north;3:up

      INTEGER(KIND=int_prec) :: i,lp,mp, midpoint,ipts
      REAL (KIND=real_prec) :: dotprod
!      INTEGER(KIND=int_prec) :: stat_alloc
      DOUBLE PRECISION :: GLATi,GLONGi,DECMAG !flip compatible
      REAL (KIND=real_prec) :: BCOMPU
      REAL (KIND=real_prec) :: dum0(NPTS2D)
!dbg20120313
      INTEGER(KIND=int_prec) :: utime_dum
!include WAM fields options
      real(KIND=real_prec), parameter :: hTop_m=7.82E+05 !m
!1:O,2:O2;3:N2
      INTEGER(KIND=int_prec) :: ihTopN,ihTopS,ihTop,jth,jjth
      INTEGER(KIND=int_prec) :: ihem,iStep,midPoints
      real(KIND=real_prec) :: r
!dbg20160715
      INTEGER(KIND=int_prec) :: idb
      real:: H, dist
!------

      iyear = NYEAR
      iday  = NDAY
      f107D_dum  = F107D
      f107A_dum  = F107AV
!nm20110822: no more allocatable arrays
!      IF (.NOT. ALLOCATED(AP_dum) )  ALLOCATE ( AP_dum(1:7) )
      AP_dum(1:7)= AP(1:7)
      ut_hour = REAL(utime)/3600. !convert from sec to hours

IF( sw_debug )  THEN
        print *, ' iyear, iday, ut_hour = ', iyear, iday, ut_hour
        print *, ' f107D, f107A, AP = ', f107D_dum, f107A_dum, AP_dum
END IF


! array initialization
!SMS$IGNORE BEGIN
      ON_m3  = zero
      HN_m3  = zero
      N2N_m3 = zero
      O2N_m3 = zero
      HE_m3  = zero
      N4S_m3 = zero
      TN_k   = zero
      TINF_k = zero
      Un_ms1 = zero
!SMS$IGNORE END

!SMS$PARALLEL(dh, lp, mp) BEGIN
!     apex_longitude_loop: DO mp = mpstrt, mpstop, mpstep          !1,NMP
!       apex_latitude_height_loop: DO lp = lpstrt, lpstop, lpstep  !1,NLP
      apex_longitude_loop: DO mp = 1,mpstop
        apex_latitude_height_loop: DO lp = 1,NLP

          IN = JMIN_IN(lp)
          IS = JMAX_IS(lp)
          NPTS = IS - IN + 1


IF( sw_debug )  then
!SMS$IGNORE BEGIN
print *,mype,'sub-neut: mp=',mp,lp,IN,IS,npts
!SMS$IGNORE END
END IF

!

!nm20110822: no more allocatable arrays
!          IF (.NOT. ALLOCATED(glon_deg) )  ALLOCATE ( glon_deg(IN:IS) )
!          IF (.NOT. ALLOCATED(glat_deg) )  ALLOCATE ( glat_deg(IN:IS) )
!          IF (.NOT. ALLOCATED(alt_km) )  ALLOCATE (   alt_km(IN:IS) )
!          IF (.NOT. ALLOCATED(Vn_ms1) )  ALLOCATE ( Vn_ms1(3,IN:IS), STAT=stat_alloc )
!if ( stat_alloc/=0 ) then
!  print *, ALLOCATED(Vn_ms1)
!  print *, '!STOP! Vn_ms1 DEALLOCATION FAILED! in neutral:',stat_alloc,lp,mp,in,is,npts
!  STOP
!end if
          glon_deg(1:NPTS) = plasma_grid_3d(IN:IS,lp,mp,IGLON)*180./pi
          glat_deg(1:NPTS) = 90. - plasma_grid_3d(IN:IS,lp,mp,IGCOLAT)*180./pi
          alt_km  (1:NPTS) = plasma_grid_Z(IN:IS,lp) * M_TO_KM  !/ 1000. 

          call get_thermosphere (npts, &
                         iyear, iday, ut_hour, f107D_dum, f107A_dum, AP_dum, &
                         glon_deg, glat_deg, alt_km, &
                         he_m3( IN:IS,lp,mp) &
     &                 , on_m3( IN:IS,lp,mp) &
     &                 , o2n_m3(IN:IS,lp,mp) &
     &                 , n2n_m3(IN:IS,lp,mp) &
     &                 ,  hn_m3(IN:IS,lp,mp) &
     &                 , n4s_m3(IN:IS,lp,mp) &
     &                 ,   tn_k(IN:IS,lp,mp) &
     &                 , tinf_k(IN:IS,lp,mp) &
     &              ,Vn_ms1(1:3,1:NPTS   )   )


!nm20151130 include WAM fields options: 
!sw_neutral
!0: WAM debug: use which ever ESMF fields are coming across for debugging purpose
!1: WAM default science mode: specify ESMF fields you wish to use
!2: GT
!3: MSIS(default)
!4: read in files
!
!swNeuPar OFF (from MSIS); ON (from WAM)
!determines which neutral parameters to derive from WAM when sw_neutral=0/1? 
!1:tn; 2:un1(east); 3:un2(north); 4:un3(up); 5:[O]; 6:[O2]; 7:[N2]
!
! note: H, He are always obtained from msis.
! what is the plan for n4s???
! ihTopN: the index of the highest height with the value in NH
! ihTopS: the index of the highest height with the value in SH
!

      midpoint = IN + (IS-IN)/2

!dbg20160715: temporarily change the code to use MSIS/HWM for the 1st time step, because wamfield is not ready for the 1st time step for a reason...
      if ( utime==432000 ) then
         print*,mype,mp,lp,'MSIS utime=',utime         
      else if ( utime>432000 ) then

         if ( sw_neutral==3 ) then
            if(lp==1)print*,mype,mp,'MSIS',sw_neutral,utime
         else if ( sw_neutral==0 .or. sw_neutral == 1 ) then
         !Tn
         ! nm20151130: temporarily obtain ihTopN
         NHLoop: do ipts=in,midpoint
            if ( plasma_grid_Z(ipts,lp)<=hTop_m .and. hTop_m<plasma_grid_Z(ipts+1,lp) ) then
               print*, mp,lp,'NH',ipts,plasma_grid_Z(ipts,lp)*1.e-3,hTop_m*1.e-3
               ihTopN=ipts
               exit NHLoop
            endif
            ! if midpoint < hTop_m[km]
            if ( ipts==midpoint) ihTopN = midpoint
         end do NHLoop !: do ipts=in,midpoint
         
         SHLoop: do ipts=is,midpoint, -1
            if ( plasma_grid_Z(ipts,lp)<=hTop_m .and. hTop_m<plasma_grid_Z(ipts-1,lp) ) then
               print*,mp,lp,'SH',ipts,plasma_grid_Z(ipts,lp)*1.e-3,hTop_m*1.e-3
               ihTopS=ipts
               exit SHLoop
            endif
            ! if midpoint < hTop_m[km]
            if ( ipts==midpoint) ihTopS = midpoint
         end do SHLoop !: do ipts=is       


!dbg20160711 commented out
!tmp20151130 temporarily assign msis Tn upto 800km
!         WamField = zero
!         NHLoop1: do ipts=in,ihTopN
!            WamField(ipts,lp,mp,1) = tn_k(ipts,lp,mp)
!         end do NHLoop1 !: do ipts=in,ihTopN
!         SHLoop1: do ipts=ihTopS,is
!            WamField(ipts,lp,mp,1) = tn_k(ipts,lp,mp)
!         end do SHLoop1 !: do ipts=in,ihTopN
!tmp20151130:
         jth=1   
         if ( swNeuPar(jth) ) then
         if(lp==1) print*,mp,'calculating wam Tn',jth 
            !below 800km: NH
            tn_k(IN:ihTopN,lp,mp)   = WamField(IN:ihTopN,lp,mp, jth) !Tn NH
            !below 800km: SH
            tn_k(ihTopS:IS,lp,mp)   = WamField(ihTopS:IS,lp,mp, jth) !Tn SH
            !above 800km NH
            tn_k(ihTopN+1:midpoint  ,lp,mp)   = WamField(ihTopN,lp,mp, jth) !Tn >800km NH
            tn_k(midpoint+1:ihTopS-1,lp,mp)   = WamField(ihTopS,lp,mp, jth) !Tn >800km SH
            !Tn Max NH
            tinf_k(IN:midpoint  ,lp,mp) = WamField(ihTopN,lp,mp, jth) !Tn Inf NH
            !Tn Max SH
            tinf_k(midpoint+1:IS,lp,mp) = WamField(ihTopS,lp,mp, jth) !Tn Inf SH

!perhaps i do not need this debug any more!
!dbg20160715
!SMS$IGNORE begin
print '(2i3,i4," tn MIN",f7.0," MAX",f7.0)',mype,mp,lp,minval(tn_k(IN:IS,lp,mp)),maxval(tn_k(IN:IS,lp,mp))
!SMS$IGNORE end

if ( minval(tn_k(IN:IS,lp,mp))<0.0 ) then

!SMS$IGNORE begin
   print*,mype,utime,'!STOP! INVALID Tn MIN!',mp,lp,minloc(tn_k(IN:IS,lp,mp))
!SMS$IGNORE end

   if (mp==41.and.lp==7) then

      do idb=1,14
!SMS$IGNORE begin
         print*,mp,lp,idb,wamfield(idb,lp,mp,1),tn_k(idb,lp,mp),plasma_grid_z(idb,lp)*1.e-3,utime
!SMS$IGNORE end
      end do
      STOP

   else if (mp==6.and.lp==15) then

      do idb=IN,IS
!SMS$IGNORE begin
         print*,mp,lp,idb,wamfield(idb,lp,mp,1),tn_k(idb,lp,mp),plasma_grid_z(idb,lp)*1.e-3,utime
!SMS$IGNORE end
      end do
      STOP

   else 
      do idb=IN,IS

!SMS$IGNORE begin
         print*,mp,lp,idb,wamfield(idb,lp,mp,1),tn_k(idb,lp,mp),plasma_grid_z(idb,lp)*1.e-3
!SMS$IGNORE end

      end do
      STOP
   end if ! (mp==41.and.lp==7) then

endif !(minval

!
!if(mp==1.or.mp==6.or.mp==11.or.mp==16) then
!  if(lp==1) then
!     do idb=1,88
!!SMS$IGNORE begin
!        print*,'sub-neut:wamfield',mype,mp,lp,idb,tn_k(idb,lp,mp),wamfield(idb,lp,mp,jth),plasma_grid_Z(idb,lp)*1.e-3
!!SMS$IGNORE end
!     enddo !idb
!  endif !lp
!endif !mp
!
         end if

         jth_loop: do jth=1,6 !2:east;3:notrh;4:up for WamField,swNeuPar
            jjth=jth+1 !2:4 for WamField,swNeuPar; !5:O,6:O2,7:N2
            if ( swNeuPar(jjth) ) then

               if ( jjth<5 ) then
                  if(lp==1) print*,mp,'calculating wam Un',jjth
                  !below 800km: NH
                  Vn_ms1(jth,IN-IN+1:ihTopN-IN+1) = WamField(IN:ihTopN,lp,mp, jjth) !Un NH
                  !below 800km: SH
                  Vn_ms1(jth,ihTopS-IN+1:IS-IN+1) = WamField(ihTopS:IS,lp,mp, jjth) !Un SH

               else if ( jjth==5 ) then
                  if(lp==1) print*,mp,'calculating wam compO',jjth 
                  !O below 800km: NH
                  on_m3( IN:ihTopN,lp,mp) = WamField(IN:ihTopN,lp,mp, jjth) !O
                  !O below 800km: SH
                  on_m3( ihTopS:IS,lp,mp) = WamField(ihTopS:IS,lp,mp, jjth) !O
               else if ( jjth==6 ) then
                  !O2 below 800km: NH
                  o2n_m3( IN:ihTopN,lp,mp) = WamField(IN:ihTopN,lp,mp, jth) !O2
                  !O2 below 800km: SH
                  o2n_m3( ihTopS:IS,lp,mp) = WamField(ihTopS:IS,lp,mp, jth) !O2
               else if ( jjth==7 ) then
                  !N2 below 800km: NH
                  n2n_m3( IN:ihTopN,lp,mp) = WamField(IN:ihTopN,lp,mp, jth) !n2
                  !N2 below 800km: SH
                  n2n_m3( ihTopS:IS,lp,mp) = WamField(ihTopS:IS,lp,mp, jth) !n2
               end if !jjth


!dbg20160913: it did not work! why?
!dbg20160824
!20160908 commeted out because this did not work why?
!temporary quick fix for the 3 strange points near the magnetic South pole
!(1)temporarily assigned from lp=14
!if( mp==4.and.lp==15 ) then 
!   if(jjth==5)then
!      on_m3(ihTopS:IS,lp,mp) = on_m3( ihTopS:IS,lp-1,mp)
!   else if(jjth==6)then
!      o2n_m3(ihTopS:IS,lp,mp) = o2n_m3( ihTopS:IS,lp-1,mp)
!   else if(jjth==7)then
!      n2n_m3(ihTopS:IS,lp,mp) = n2n_m3( ihTopS:IS,lp-1,mp)
!   endif !jjth=5
!endif !mp=3
!
!!(2)temporarily assigned from lp=13
!if( mp==5.and.lp==14 ) then 
!   if(jjth==5)then
!      on_m3(ihTopS:IS,lp,mp) = on_m3( ihTopS:IS,lp-1,mp)
!   else if(jjth==6)then
!      o2n_m3(ihTopS:IS,lp,mp) = o2n_m3( ihTopS:IS,lp-1,mp)
!   else if(jjth==7)then
!      n2n_m3(ihTopS:IS,lp,mp) = n2n_m3( ihTopS:IS,lp-1,mp)
!   endif !jjth=5
!endif !mp=4
!
!!(3)temporarily assigned from lp=12
!if( mp==5.and.lp==14 ) then 
!   if(jjth==5)then
!      on_m3(ihTopS:IS,lp,mp) = on_m3( ihTopS:IS,lp-2,mp)
!   else if(jjth==6)then
!      o2n_m3(ihTopS:IS,lp,mp) = o2n_m3( ihTopS:IS,lp-2,mp)
!   else if(jjth==7)then
!      n2n_m3(ihTopS:IS,lp,mp) = n2n_m3( ihTopS:IS,lp-2,mp)
!   endif !jjth=5
!endif !mp=4
!dbg20160824:end





            
               !dbg20160823:
               ihemLoop: DO ihem=1,2
                  if ( ihem==1 ) then 
                     !above 800km: NH
                     istep=+1
                     ihTop=ihTopN
                     midPoints=midPoint
                     
                  else if ( ihem==2 ) then 
                     !above 800km: SH
                     istep=-1
                     ihTop=ihTopS
                     midPoints=midPoint+1               
                  end if
 
                  above800kmLoop: DO ipts=ihTop+istep, midPoints, iStep 
!t                     r = (plasma_grid_Z(ipts,lp)-plasma_grid_Z(ihTop-istep,lp)) / (plasma_grid_Z(ihTop,lp)-plasma_grid_Z(ihTop-istep,lp))   
                     
                     if ( jjth<5) then
!t                        Vn_ms1(jth,ipts) = r*WamField(ihTop,lp,mp,jjth) + (1.-r)*WamField(ihTop-istep,lp,mp,jjth)
! extend the top value
                        Vn_ms1(jth,ipts) = WamField(ihTop,lp,mp,jjth) 
                        
                        
                     else  !jjth>=5

                        dist = earth_radius/(earth_radius+plasma_grid_Z(ipts,lp))
                        H = GSCON * Tn_k(ihTop,lp,mp) / (massn_kg(jjth-4)*G0*dist*dist)

                        if ( jjth==5 ) then !O
                        
                           if(lp==1) print*,mp,'calculating wam comp>800km NH',jjth 
                           on_m3( ipts,lp,mp) = WamField(ihTop,lp,mp,jjth) * exp((-plasma_grid_Z(ipts,lp)+plasma_grid_Z(ihTop,lp))/H)
                        
                        else if (jjth==6 ) then !O2
                           o2n_m3(ipts,lp,mp) = WamField(ihTop,lp,mp,jjth) * exp((-plasma_grid_Z(ipts,lp)+plasma_grid_Z(ihTop,lp))/H)
                        else if (jjth==7 ) then !N2
                           n2n_m3(ipts,lp,mp) = WamField(ihTop,lp,mp,jjth) * exp((-plasma_grid_Z(ipts,lp)+plasma_grid_Z(ihTop,lp))/H)
                        end if !jjth==5

                     end if !jjth<5
                     
                  end do above800kmLoop!: DO ipts=ihTop+istep, midPoints, iStep 
               end do          ihemLoop!: DO ihem=1,2         


            end if !( swNeuPar(jjth) ) then

         end do jth_loop !jth=1,3 !2:4 for WamField,swNeuPar            


!SMS$IGNORE begin
print '(2i3,i4," vn MIN",f7.1,"MAX",f7.1)',mype,mp,lp,minval(vn_ms1(2,IN:IS)),maxval(vn_ms1(2,IN:IS))
print '(2i3,i4," on MIN",e12.1,"MAX",e12.1)',mype,mp,lp,minval(on_m3(IN:IS,lp,mp)),maxval(on_m3(IN:IS,lp,mp))
!SMS$IGNORE end


            end if !      if ( sw_neutral == 3
        end if !( utime==432000 ) then




         !nm20151130
          flux_tube: DO i=IN,IS
            ipts = i-IN+1 !1:NPTS

            IF ( sw_grid==0 ) THEN !APEX
!dbg20110728: un_ms1(1:2) components are not used for the moment, so commented out!!! they will be needed when calculating the field line integrals
!!note: SQRT(D3*D3...) is required for scaling because sum of D1^2(1:3) are not equal to 1 
!! get neutral wind vectors along a field line: 
!! Un(1)=Ue1=d1*U: positive east, Eq(5.6) 
!!!!            dotprod = DOT_PRODUCT( D1(1:3,i,mp), D1(1:3,i,mp) ) 
!            dotprod = D1(1,i,mp)*D1(1,i,mp)  + D1(2,i,mp)*D1(2,i,mp)  + D1(3,i,mp)*D1(3,i,mp) 
!            IF ( dotprod > 0.0 ) THEN
!              Un_ms1(1,i,mp) = &
!     &     (  D1(1,i,mp)*Vn_ms1(1,i) + D1(2,i,mp)*Vn_ms1(2,i) + D1(3,i,mp)*Vn_ms1(3,i)  )/ &
!     & SQRT(  dotprod   )
!            ELSE
!!dbg20110728 not 100% sure if this is appropriate???
!              Un_ms1(1,i,mp) = 0.0 
!            END IF
!
!! Un(2)=Ue2=d2*U: positive down/equatorward, Eq(5.6) 
!            dotprod = D2(1,i,mp)*D2(1,i,mp)  + D2(2,i,mp)*D2(2,i,mp)  + D2(3,i,mp)*D2(3,i,mp) 
!            IF ( dotprod > 0.0 ) THEN
!            Un_ms1(2,i,mp) = &
!     &     ( D2(1,i,mp)*Vn_ms1(1,i) + D2(2,i,mp)*Vn_ms1(2,i) + D2(3,i,mp)*Vn_ms1(3,i)  )/ &
!     & SQRT(  dotprod   )
!            ELSE
!              Un_ms1(2,i,mp) = 0.0
!            END IF
         

! un(3)=Ue3=d3*U: positive parallel to a field line, Eq(5.6) 
               dotprod = apexD(i,lp,mp,east ,3)*apexD(i,lp,mp,east ,3)  &
                    &  + apexD(i,lp,mp,north,3)*apexD(i,lp,mp,north,3) &
                    &  + apexD(i,lp,mp,up   ,3)*apexD(i,lp,mp,up   ,3)
               IF ( dotprod > 0.0 ) THEN
                  Un_ms1(i,lp,mp,3) = & 
                       &     ( apexD(i,lp,mp,east ,3)*Vn_ms1(1,ipts)     &
                       &     + apexD(i,lp,mp,north,3)*Vn_ms1(2,ipts)     &
                       &     + apexD(i,lp,mp,up   ,3)*Vn_ms1(3,ipts) ) / &
                       &     SQRT(  dotprod   )
               ELSE
                  Un_ms1(i,lp,mp,3) = 0.0
               END IF
!!!DOT_PRODUCT( D3(1:3,i,mp), Vn_ms1(1:3,i) ) / SQRT(  DOT_PRODUCT( D3(1:3,i,mp), D3(1:3,i,mp) )  )

!dbg20110131: the midpoint values become NaN otherwise because of inappropriate D1/3 values...
               IF ( lp>=1 .AND. lp<=6 .AND. i==midpoint )   Un_ms1(i,lp,mp,:) = Un_ms1(i-1,lp,mp,:) 

            ELSE IF ( sw_grid==1 ) THEN !FLIP

               GLONGi=glon_deg(ipts) !GEOGRAPHIC longitude[deg]
               GLATi=glat_deg(ipts) !GEOGRAPHic latitude[deg]
               CALL MAGDEC(GLATi,GLONGi,DECMAG) !-- magnetic declination for winds
               DECMAG=DECMAG/57.296
               !.. Horizontal component
!FLIP or: BCOMPU = (UHED(1)*COS(DECMAG)+UHED(2)*SIN(DECMAG))
               BCOMPU = ( vn_ms1(2,ipts)*COS(DECMAG) + vn_ms1(1,ipts)*SIN(DECMAG) )
!FLIP or: UN(J)= -ABS(COSDIP(J))*BCOMPU * 100.0   !.. The wind along B in cm/s 
!*(-1) will be done in flux_tube_solver...f90
! unit: meter s-1: unit conversion to cm/s will be done in CTIP-INT.f
               Un_ms1(i,lp,mp,3) = ABS( apexD(i,lp,mp,north,3) )*BCOMPU    !.. The wind along B

if( 350.<=alt_km(ipts).and.alt_km(ipts)<=450.) then
print *,i,ipts,alt_km(ipts),Vn_ms1(1,ipts),Un_ms1(i,lp,mp,3),glongi,glati,(decmag*57.296),BCOMPU
endif

END IF !( sw_grid==0 ) THEN !APEX

          END DO flux_tube !: DO i=IN,IS

IF ( sw_debug ) THEN
      print "('lp=',i6,'  mp=',i6,'  IN=',i6,'  IS=',i6,'  NPTS=',i8)", lp,mp,IN, IS, npts
      print "(' glon_deg = ',2F10.4)", glon_deg(1), glon_deg(npts)
      print "(' glat_deg = ',2F10.4)", glat_deg(1), glat_deg(npts)
      print "(' alt_km   = ',2F12.2)", alt_km(1), alt_km(npts)

      print "(' LOG10 O_density_m3    = ',2F10.4)", LOG10(on_m3(IN,lp,mp)), LOG10(on_m3(IS,lp,mp))
      print "(' LOG10 H_density_m3    = ',2F10.4)", LOG10(hn_m3(IN,lp,mp)), LOG10(hn_m3(IS,lp,mp))
      print "(' LOG10 N2_density_m3   = ',2F10.4)", LOG10(n2n_m3(IN,lp,mp)), LOG10(n2n_m3(IS,lp,mp))
      print "(' LOG10 O2_density_m3   = ',2F10.4)", LOG10(o2n_m3(IN,lp,mp)), LOG10(o2n_m3(IS,lp,mp))
      print "(' LOG10 HE_density_m3   = ',2F10.4)", LOG10(he_m3(IN,lp,mp)), LOG10(he_m3(IS,lp,mp))
      print "(' LOG10 N4S_density_m3  = ',2F10.4)", LOG10(n4s_m3(IN,lp,mp)), LOG10(n4s_m3(IS,lp,mp))

      print "(' tn_k   = ',2F10.4)",tn_k(IN,lp,mp), tn_k(IS,lp,mp)
      print "(' tinf_k = ',2F10.4)",tinf_k(IN,lp,mp), tinf_k(IS,lp,mp)


      print "(' vn_east_ms1  = ',2F10.4)",vn_ms1(1,1), vn_ms1(1,npts)
      print "(' vn_north_ms1 = ',2F10.4)",vn_ms1(2,1), vn_ms1(2,npts)

!dbg20110923      print "(' un_meast_ms1     = ',2F10.4)",un_ms1(IN,lp,mp,1), un_ms1(IS,lp,mp,1)
!dbg20110923      print "(' un_down/eq_ms1   = ',2F10.4)",un_ms1(IN,lp,mp,2), un_ms1(IS,lp,mp,2)
      print "(' un_para_ms1      = ',2F10.4)",un_ms1(IN,lp,mp,3), un_ms1(IS,lp,mp,3)
END IF !( sw_debug ) THEN 


!nm20110822: no more allocatable arrays
!          IF ( ALLOCATED( glon_deg ) )  DEALLOCATE( glon_deg )
!          IF ( ALLOCATED( glat_deg ) )  DEALLOCATE( glat_deg )
!          IF ( ALLOCATED( alt_km   ) )  DEALLOCATE( alt_km  )
!          IF ( ALLOCATED( Vn_ms1   ) )  DEALLOCATE( Vn_ms1   )

        END DO  apex_latitude_height_loop !: DO lp = 1,NLP

!nm20120312 output wind
!write (6000,fmt=*) utime, Un_ms1(1:NPTS2D,mp,3) 
if ( sw_neutral==2  ) then
!write (6000,fmt=*) utime, Un_ms1(1:NPTS2D,mp,3) 
  if(parallelBuild) then
    print*,'module_neutral: sw_neutral=2 disabled for parallel runs'
    print*,'stopping in module_neutral'
    stop
  else
    if ( utime==start_time ) then
      luntmp3=6003
      filename="wind_input"
      FORM_dum="formatted  "
      STATUS_dum="old"
      CALL open_file ( filename, luntmp3, FORM_dum, STATUS_dum ) 
    endif
!read (unit=luntmp3,fmt=*) utime_dum, Un_ms1(1:NPTS2D,mp,3) 
    read (unit=luntmp3,fmt=*) utime_dum, dum0 
    if( utime_dum /=utime ) then 
      print *,"sub-neutral: !STOP! INVALID utime_dum!",utime_dum
      STOP
    endif
    do lp=1,NLP
      Un_ms1(JMIN_IN(lp):JMAX_IS(lp),lp,mp,3) = dum0(JMIN_ING(lp):JMAX_ISG(lp))
    enddo

    if( utime==stop_time )   CLOSE(UNIT=luntmp3)
  endif ! parallelBuild

end if !sw_neutral

      END DO  apex_longitude_loop  !: DO mp = 1,NMP
!SMS$PARALLEL END

!      IF ( ALLOCATED(AP_dum) )  DEALLOCATE ( AP_dum )
      end subroutine neutral

      END MODULE module_NEUTRAL_MKS
