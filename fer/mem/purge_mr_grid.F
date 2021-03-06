	SUBROUTINE PURGE_MR_GRID( grid, status )

*
*
*  This software was developed by the Thermal Modeling and Analysis
*  Project(TMAP) of the National Oceanographic and Atmospheric
*  Administration''s (NOAA) Pacific Marine Environmental Lab(PMEL),
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
*
* eliminate all stored mrs on the given grid

* programmer - steve hankin
* NOAA/PMEL, Seattle, WA - Tropical Modeling and Analysis Program
* written for VAX computer under VMS operating system
*
* V200:  8/4/89
*	12/6/89 - purge mgrid_abstract_last, too
* Unix/RISC port - 4/25/91 *sh*: longer ds_name
*Linux Port 1/97 *kob* - Added a preprocessor include for tmap_dset.parm
*			  because it needed a preprocessor.
* V500 *sh* 7/99 - issue warning, only, if grid is in-use in a data set
* V510: 5/00 *sh* - BUG fix: special grids exceed "6"
* v540 *acm* 10/01 increase length of ds_name
* v540 *acm* 10/01  remove VMS include statements
* v604 *acm* 7/07 increase length of ds_name
*        2/12 *kms* Add E and F dimensions (use nferdims in tmap_dims.parm)
* V695+ *sh 3/15 - bug fix.  Grid name was not displayed with warnings
* V698  3/16 *acm* Removed Philander-Seigel code including diagnostic 
*                  variables, pre-defined axes and grids, cat_calc_var.

        IMPLICIT NONE
        include 'tmap_dims.parm'
#	include	"tmap_dset.parm"
	include	'tmap_errors.parm'
	include	'ferret.parm'
	include	'errmsg.parm'
	include 'xdset_info.cmn_text'
	external xdset_info_data
	include 'xtm_grid.cmn_text'
	external xgt_grid_data
	include	'xfr_grid.cmn'
	include 'xvariables.cmn'
        include 'xpyvar_info.cmn'

* calling argument declaration:
	INTEGER	grid, status

* internal variable declarations:
	INTEGER	TM_LENSTR1,
     .		mr, ivar, dset, glen, done_dset
!	INTEGER	TM_LENSTR1, mr, ivar, cvar, dset, glen, done_dset

* the lowest grids are protected
	IF ( grid .LE. mgrid_fabstract ) GOTO 5200

* initialize
	done_dset = 0

* make sure grid is not used by any file variables
	DO 10 ivar = 1, maxvars
	   dset = ds_var_setnum( ivar )
	   IF ( dset .EQ. set_not_open ) GOTO 10
	   IF ( ds_grid_number(ivar) .EQ. grid
     .	  .AND. dset .NE. done_dset ) THEN
	      glen = TM_LENSTR1(grid_name(grid))
	      CALL WARN('grid '//grid_name(grid)(:glen)//
     .		' used by data set '//ds_name(dset))
	      CALL WARN
     .		('Redefinition may alter apparent contents of data set')
	      CALL PURGE_DSET(dset)
	      done_dset = dset
	   ENDIF
 10	CONTINUE

* make sure grid is not used by any pystat variables
        DO 30 ivar = 1, maxpyvars
           IF ( pyvar_ndarray_obj(ivar) .EQ. 0 ) GOTO 30
           IF ( pyvar_grid_number(ivar) .EQ. grid ) THEN
              CALL WARN('grid ' // grid_name(grid)(:glen) //
     .            ' used by python data variable ' // pyvar_code(ivar))
              CALL WARN(
     .      'Redefinition may alter apparent contents of the variable')
              CALL PURGE_PYSTAT_VAR(ivar)
           ENDIF
 30     CONTINUE

* the coast is clear
* ...clear out the memory variables
	DO 100 mr = 1, max_mrs
	   IF ( mr_protected( mr ) .EQ. mr_deleted ) GOTO 100
	   IF ( mr_grid ( mr )     .NE. grid	   ) GOTO 100
	   CALL DELETE_VARIABLE( mr )
 100	CONTINUE

* and wipe out all user-defined variables (they may depend on it indirectly)
	CALL PURGE_ALL_UVARS

* success
	status = ferr_ok
	RETURN

* error exit
 5000	RETURN
 5200	CALL ERRMSG( ferr_grid_definition, status,
     .		'protected grid: '//grid_name(grid), *5000 )
	END

