	LOGICAL FUNCTION TM_CHECK_BNDS_CENTERED (line, line_edges, npts, 
     .		iaxis, doubletype)
*
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
* Checks whether data points are all centered within the bounds on an axis
* Do this in single precision, as in the check for regular axis in cd_get_1_axis.

* 4/2004 ACM 
* V58+ *acm*  1/05 Fixes for irreg axes with bounds: This routine now checks
*                  whether the coordinates are centered in the bound boxes, and 
*                  whether the boxes are equal sized.
* V601 *acm* 9/19  Fix bug 1434; check bounds for regularly-spaced axes 
* V694  5/15 *acm* Match precision for bounds checks (as is done for coords).
* V72 6/17 *acm* for trac enhancement #767 -- dynamic coordinate storage 
*                line and line_edges are the coordinates and edges for this line

	include 'tmap_dims.parm'
	include 'xtm_grid.cmn_text'
	external xgt_grid_data

* Argument declarations
	REAL	line(*), line_edges(*)
	LOGICAL doubletype, regular
	INTEGER npts, iaxis

* Local variable declarations
        LOGICAL TM_FPEQ_EPS, TM_DFPEQ_TOL, equal
	INTEGER i
        REAL diff_hi, diff_lo, diff_last
        REAL pt, del, blo, bhi
	REAL epsilon_23, epsilon
	REAL*8 depsilon_46, depsilon, first_delta

	epsilon_23 =  2.**(-23) 
	depsilon_46 =  2.**(-46) 

	first_delta = line(2) - line(1)

	depsilon = depsilon_46 * 2.*(ABS(line(1)) / first_delta )
	epsilon = epsilon_23 * 2.*(ABS(line(1)) / first_delta )

        IF (line_regular(iaxis)) THEN
           pt = line_start(iaxis)
           del = line_delta(iaxis) 

	   DO 100 i = 1, npts

             blo = line_edges(2*(i-1)+1)
             bhi = line_edges(2*(i-1)+2)

	     diff_hi = bhi - pt
             diff_lo = pt - blo

	     IF (doubletype) THEN
	       equal = TM_DFPEQ_TOL(diff_lo, diff_hi, depsilon)
	     ELSE
	       equal = TM_FPEQ_EPS(epsilon, diff_lo, diff_hi) 
	     ENDIF

	     IF ( .NOT. equal ) THEN
	        TM_CHECK_BNDS_CENTERED = .FALSE.
	        RETURN
	     ENDIF

             IF (i .GT. 1) THEN
                IF (diff_hi .NE. diff_last) THEN
	           TM_CHECK_BNDS_CENTERED = .FALSE.
	           RETURN
                ENDIF
	     ENDIF
             diff_last = diff_hi
             pt = float(i) * del + line_start(iaxis)

  100	   CONTINUE

        ELSE  ! not line_regular
   
	   DO 200 i = 1, npts
             blo = line_edges(2*(i-1)+1)
             bhi = line_edges(2*(i-1)+2)

             diff_hi = bhi - line(i)
             diff_lo = line(i)- blo

	     IF (doubletype) THEN
	       equal = TM_DFPEQ_TOL(diff_lo, diff_hi, depsilon)
	     ELSE
	       equal = TM_FPEQ_EPS(epsilon, diff_lo, diff_hi) 
	     ENDIF
	     IF ( .NOT. equal ) THEN
	        TM_CHECK_BNDS_CENTERED = .FALSE.
	        RETURN
	     ENDIF

             IF (i .GT. 1) THEN
                IF (diff_hi .NE. diff_last) THEN
	           TM_CHECK_BNDS_CENTERED = .FALSE.
	           RETURN
                ENDIF
	     ENDIF
             diff_last = diff_hi

  200	   CONTINUE

        ENDIF

	TM_CHECK_BNDS_CENTERED = .TRUE.
	RETURN
	END
