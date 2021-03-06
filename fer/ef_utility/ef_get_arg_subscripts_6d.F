c*
c* ef_get_arg_subscripts_6d.F (formerly ef_get_arg_subscripts.F)
c*   
*
*  This software was developed by the Thermal Modeling and Analysis
*  Project(TMAP) of the National Oceanographic and Atmospheric
*  Administration's (NOAA) Pacific Marine Environmental Lab(PMEL),
*  hereafter referred to as NOAA/PMEL/TMAP.
*
*  Access and use of this software shall impose the following
*  obligations and understandings on the user. The user is granted the
*  right, without any fee or cost, to use, copy, modify, alter, enhance
*  and distribute this software, and any derivative works thereof, and
*  its supporting documentation for any purpose whatsoever, provided
*  that this entire notice appears in all copies of the software,
*  derivative works and supporting documentation.  Further, the user
*  agrees to credit NOAA/PMEL/TMAP in any publications that result from
*  the use of this software or in any product that includes this
*  software. The names TMAP, NOAA and/or PMEL, however, may not be used
*  in any advertising or publicity to endorse or promote any products
*  or commercial entity unless specific written permission is obtained
*  from NOAA/PMEL/TMAP. The user also understands that NOAA/PMEL/TMAP
*  is not obligated to provide the user with any support, consulting,
*  training or assistance of any kind with regard to the use, operation
*  and performance of this software nor to provide the user with any
*  updates, revisions, new versions or "bug fixes".
*
*  THIS SOFTWARE IS PROVIDED BY NOAA/PMEL/TMAP "AS IS" AND ANY EXPRESS
*  OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
*  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
*  ARE DISCLAIMED. IN NO EVENT SHALL NOAA/PMEL/TMAP BE LIABLE FOR ANY SPECIAL,
*  INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER
*  RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF
*  CONTRACT, NEGLIGENCE OR OTHER TORTUOUS ACTION, ARISING OUT OF OR IN
*  CONNECTION WITH THE ACCESS, USE OR PERFORMANCE OF THIS SOFTWARE. 
*
c* Jonathan Callahan
c* Feb 19th 1998
c*
c*
c* Initialize the context limits the EF will use.  
c*
c* V510 12/99 *sh* - cope with unspecified limits (default=full axis range)
c*               and limits embedded inside of user variable definitions
c*               as in LET a = sst[L=5:9]; LIST FFT(a) (info from uvar_*)
c*      3/00 *sh* - bug fix: above logic applies only to CUSTOM axes 
*       3/12 *kms* Added E and F dimensions, appended _6D to subroutine name
*                  Reduced the outer dimensionality of arg_lo_ss, arg_hi_ss,
*                  and arg_incr from EF_MAX_ARG+1 to EF_MAX_ARGS

      SUBROUTINE EF_GET_ARG_SUBSCRIPTS_6D(id, arg_lo_ss, arg_hi_ss, 
     .                                    arg_incr)

      IMPLICIT NONE
      INCLUDE 'tmap_dims.parm'
      INCLUDE 'ferret.parm'
      INCLUDE 'xcontext.cmn'
      INCLUDE 'xvariables.cmn'
      INCLUDE 'EF_Util.parm'

* argument declarations
      INTEGER id, arg_lo_ss(nferdims,EF_MAX_ARGS),
     .            arg_hi_ss(nferdims,EF_MAX_ARGS),
     .            arg_incr (nferdims,EF_MAX_ARGS)


* internal variable declarations
      LOGICAL embedded_limits
      INTEGER idim, iarg, num_reqd_args, cat, var
      INTEGER cx_list(EF_MAX_ARGS), ax_src(nferdims)
      INTEGER efcn_get_num_reqd_args

      num_reqd_args = efcn_get_num_reqd_args(id)
      CALL efcn_get_axis_will_be(id, ax_src)

c* The context list was cached by Ferret and must be retrieved
c* to be accessible to the external function.
      CALL EF_GET_CX_LIST(cx_list)

      DO 200 idim=1,nferdims

         DO 100 iarg=1, num_reqd_args

            IF ( cx_given(idim,cx_list(iarg)) ) THEN
* limits are explicit in the top-level expression
              arg_lo_ss(idim,iarg) = cx_lo_ss(cx_list(iarg), idim)
              arg_hi_ss(idim,iarg) = cx_hi_ss(cx_list(iarg), idim)
            ELSE
* are there explicit limits embedded within user-var definitions?
              cat = cx_category( cx_list(iarg) )
              var = cx_variable( cx_list(iarg) )
              IF ( cat .EQ. cat_user_var ) THEN
                 embedded_limits =
     .                 uvar_given(idim,var) .GE. uvlim_gvn_gnl
     .           .AND. uvar_given(idim,var) .LE. uvlim_gvn_xact
              ELSE
                 embedded_limits = .FALSE.
              ENDIF
              IF ( embedded_limits ) THEN
* ... get embedded explicit limits from the user-variable definition
                arg_lo_ss(idim,iarg) = uvar_lo_ss(var, idim)
                arg_hi_ss(idim,iarg) = uvar_hi_ss(var, idim)
              ELSE
                IF (ax_src(idim) .NE. CUSTOM) THEN
* ... result axis inherits limits from SET REGION and command qualifiers, etc.
* NOTE: ARG LIMITS WILL BE WRONG IF USED DURING GRID-CREATION
*       (which should never happen ...)
                  arg_lo_ss(idim,iarg) = cx_lo_ss(cx_list(iarg), idim)
                  arg_hi_ss(idim,iarg) = cx_hi_ss(cx_list(iarg), idim)
                ELSE
* ... result axis is imposed by the EF and this arg has no explicit limits
*     so infer the limits from the nature of the variable
                  IF (  cat .EQ. cat_file_var ) THEN
*    ... get limits of file variable (possibly less than full-axis)
                    CALL VAR_SS_LIMS( idim, cx_list(iarg),
     .                                arg_lo_ss(idim,iarg),
     .                                arg_hi_ss(idim,iarg) )
                  ELSE
*    ... assume the full span of the defining axis as the default range
                    CALL GRID_SUBSCRIPT_EXTREMES_NO_MOD(
     .                  arg_lo_ss(idim,iarg),
     .                  arg_hi_ss(idim,iarg),
     .                  cx_grid(cx_list(iarg)), idim)
                  ENDIF
                ENDIF
              ENDIF
            ENDIF

* fill in the delta to indicate if a range is available
            IF (arg_lo_ss(idim,iarg) .EQ. arg_hi_ss(idim,iarg)) 
     .           THEN
               arg_incr(idim, iarg) = 0
            ELSE
               arg_incr(idim, iarg) = 1
            ENDIF

 100     CONTINUE

 200  CONTINUE

* Fill in "unused" values for the unused arguments - for checking in the 4D version
      DO 400 iarg=num_reqd_args+1, EF_MAX_ARGS
         DO 300 idim=1,nferdims
            arg_lo_ss(idim, iarg) = unspecified_int4
            arg_hi_ss(idim, iarg) = unspecified_int4
            arg_incr (idim, iarg) = 0
 300     CONTINUE
 400  CONTINUE

      RETURN 
      END

