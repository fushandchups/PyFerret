	SUBROUTINE TAXIS_STYLE( x_or_y, lo_bc, hi_bc, tstyle, imposed_lab )

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
*
* set up PPLUS to properly format a time axis

* programmer - steve hankin
* NOAA/PMEL, Seattle, WA - Tropical Modeling and Analysis Program
* written for VAX computer under VMS operating system
*
* revision 0.0 - 9/22/88 - extracted from AXIS_FORMAT
* revision 0.1 -  1/9/89 - added climatological axis logic
* 12/10/93 - set only the small tic size - do not mess with large tics
* V420: 11/95 - accomodate century long time axes
*	      - and 4-digit PLOT+ years!!
*	      - added "x_or_y" argument for Y axis calendar axes
*	      - added TXTYPE MULTIYR
* V510: 5/00 *sh* - extend formatting to 1000's of years axes
* V650  1/10 *acm*- Define a symbol TXTYPE_SETTING which can be used in
*               scripts when deciding whether to set the axis style as DMY
** V650  1/10 *acm*-  Bug 670 fixed: added TXTYPE MULTIYR, multi-decade
* V66    7/10 *kms* - undiscovered bug fixed: 'TXTYPE_SETTING' was used 
*                     directly instead of buff30 in call to GETSYM
* V686 *acm* 11/13 Allow symbol names to be up to 120 characters long
* V695+ *sh*  3/15 Added argument "imposed_lab" to disambiguate F and T axes
* V695  *acm*  9/15 Changes for hour:min labeling on time axes
* V710 *acm*  8/16 Change the span for labeling year axes with months
* V710  *acm* 11/16 Ticket 2483: Fix the axis-end symbols that are defined 
*                   for time axis plots

	include 'ferret.parm'
	include 'plot_setup.parm'
	include 'tmap_dims.parm'
	include 'xplot_setup.cmn'
        include 'axis_inc.decl'	! with axis lengths
        include 'AXIS.INC'      ! with axis lengths	

* calling argument declarations:
	CHARACTER	x_or_y*1, tstyle*3
	CHARACTER*(*)	imposed_lab
	REAL*8		lo_bc, hi_bc

* parameter definitions:
	INTEGER		pmax_tax
	REAL*8		psecs_at_2_yrs
	PARAMETER     ( pmax_tax   = 16,
     .			psecs_at_2_yrs = 60.*60.*24.*365.*2. )

* internal variable declarations:
	LOGICAL		climatology, its_x
	INTEGER		TM_LENSTR1, TM_LENSTR, itax, hi_int, slen, ilen, i1, i2
	CHARACTER	ppl_cmnd*128, tstyle_long*10, buff30*30, buff*10
	REAL		hrs, hrsper8, axlen, labsize

* time axis style table
	INTEGER		tax_loint( pmax_tax ),	! PPL TXLINT lo,...
     .			tax_hiint( pmax_tax )	! PPL TXLINT ...,hi
	REAL		tax_hours( pmax_tax )	! bounds: range-->style
	CHARACTER*10	tax_style( pmax_tax )	! PPL TXTYPE value

	DATA	tax_hours(1)	/   12.	/,	! < 24 hour long axis with partial days, see label 510 for HR type
     .		tax_style(1)	/  'HR'/,
     .		tax_loint(1)	/    3	/,
     .		tax_hiint(1)	/    1	/
	DATA	tax_hours(2)	/  144.	/,	! 24 hour to 6 day long axis
     .		tax_style(2)	/ 'DAY'	/,
     .		tax_loint(2)	/    6	/,
     .		tax_hiint(2)	/    1	/
	DATA	tax_hours(3)	/  768.	/,	! 6 to 32 day long axis
     .		tax_style(3)	/ 'MON'	/,
     .		tax_loint(3)	/    1	/,
     .		tax_hiint(3)	/    1	/
	DATA	tax_hours(4)	/ 2880.	/,	! 32 day to 4 month long axis
     .		tax_style(4)	/ 'MON'	/,
     .		tax_loint(4)	/    5	/,
     .		tax_hiint(4)	/    1	/
	DATA	tax_hours(5)	/43200.	/,	! 4 month to 5 year long axis
     .		tax_style(5)	/  'YR'	/,
     .		tax_loint(5)	/    1	/,
     .		tax_hiint(5)	/    1	/
	DATA	tax_hours(6)	/84000./,	! 5 to 10 year long axis
     .		tax_style(6)	/  'YR'	/,
     .		tax_loint(6)	/    3	/,
     .		tax_hiint(6)	/    1	/
	DATA	tax_hours(7)	/144000./,	! 10 to 17 year long axis
     .		tax_style(7)	/  'YR'	/,
     .		tax_loint(7)	/    0	/,
     .		tax_hiint(7)	/    2	/
* ... eliminate small tics beyond here
	DATA	tax_hours(8)	/172800./,	! 17 to 20 year long axis
     .		tax_style(8)	/  'YR MULTIYR'	/,
     .		tax_loint(8)	/    0	/,
     .		tax_hiint(8)	/    2	/
	DATA	tax_hours(9)	/432000./,	! 20 to 50 year long axis
     .		tax_style(9)	/  'YR MULTIYR'	/,
     .		tax_loint(9)	/    0	/,
     .		tax_hiint(9)	/    5	/
	DATA	tax_hours(10)	/864000./,	! 50 to 100 year long axis
     .		tax_style(10)	/  'YR MULTIDC'	/,
     .		tax_loint(10)	/    0	/,
     .		tax_hiint(10)	/   10	/
	DATA	tax_hours(11)	/1728000.	/, ! 100 to 200 yr long axis
     .		tax_style(11)	/  'YR MULTIDC'	/,
     .		tax_loint(11)	/    0	/,
     .		tax_hiint(11)	/   20	/
	DATA	tax_hours(12)	/4320000.	/, ! 200 to 500 yr long axis
     .		tax_style(12)	/  'YR MULTIDC'	/,
     .		tax_loint(12)	/    0	/,
     .		tax_hiint(12)	/   50	/
	DATA	tax_hours(13)	/8640000.	/, ! 500 to 1000 yr long axis
     .		tax_style(13)	/  'YR MULTIDC'	/,
     .		tax_loint(13)	/    0	/,
     .		tax_hiint(13)	/   100	/
	DATA	tax_hours(14)	/17280000.	/, ! 1000 to 2000 yr long axis
     .		tax_style(14)	/  'YR MULTIDC'	/,
     .		tax_loint(14)	/    0	/,
     .		tax_hiint(14)	/   200	/
	DATA	tax_hours(15)	/43200000.	/, ! 2000 to 5000 yr long axis
     .		tax_style(15)	/  'YR MULTIDC'	/,
     .		tax_loint(15)	/    0	/,
     .		tax_hiint(15)	/   500	/
	DATA	tax_hours(16)	/    0.	/,    ! greater than 5000 yr long axis
     .		tax_style(16)	/  'YR MULTIDC'	/,
     .		tax_loint(16)	/    0	/,
     .		tax_hiint(16)	/   1000	/

* time axis orientation
	its_x = x_or_y .EQ. 'X'

* axis length
	IF ( its_x ) THEN
	   axlen = xlen
	ELSE
	   axlen = ylen
	ENDIF

*	
	ilen = TM_LENSTR(imposed_lab)

* regard axis as climatological if it starts in year 0000 or 0001 and
* extends less than 2 years
	climatology = lo_bc .LE. psecs_at_2_yrs
     .		.AND. (hi_bc-lo_bc).LT.psecs_at_2_yrs

* get axis length in hours from times since BC in seconds
	hrs = ( hi_bc - lo_bc ) / 3600.

* how many hours if the axis were 8 in length ?
	hrsper8 = 8./axlen * hrs

* select style based on axis length
	DO 500 itax = 1, pmax_tax
	   IF ( hrsper8 .LE. tax_hours( itax ) ) GOTO 510
 500	CONTINUE	         
	itax = pmax_tax


* TXTYPE and TXLINT commands (time axis style)
 510	tstyle_long = tax_style( itax )
	IF (hrs .LE. 36) tstyle_long = 'HR'
	IF (hrs .LE.  2) tstyle_long = 'MIN'
	tstyle = tstyle_long	! 3 character, only
	CALL PPLCMD ( from, line, 0, 'TXTYPE '//tstyle_long, 1, 1 )

* ---
* Define a symbol TXTYPE_SETTING
* if this symbol already exists then delete it
        buff30 = 'TXTYPE_SETTING'
	CALL GETSYM( buff30, buff, i2, i1 )
	IF ( i1 .EQ. 0 ) CALL DELSYM(buff30,i1)

* define the symbol
	slen = TM_LENSTR1(tstyle_long)
	CALL PUTSYM( buff30, tstyle_long, slen, i2)
* ---

* ... suppress year display on climatological axes
	hi_int = tax_hiint(itax)
	IF ( climatology ) THEN
	   IF ( tstyle(:2) .EQ. 'YR' ) hi_int = 0 ! suppress year axis label
	   tstyle = 'CLM'			  ! suppress "YEAR:" label
	ENDIF
	WRITE ( ppl_cmnd, 3030 ) tax_loint(itax), hi_int
 3030	FORMAT ('TXLINT',2I6)
	CALL PPLCMD ( from, line, 0, ppl_cmnd, 1, 1 )

* special "imposed" labels (used to disambiguate T and F axes)
	IF (ilen.GT.0 .AND. imposed_lab .NE. ' ') THEN
	   slen = TM_LENSTR1(imposed_lab)
       labsize = dflt_letsize_label * textscale
	   IF ( its_x ) THEN
* ... lower left corner along the horizontal page edge
              CALL PUT_LABEL( ppl_movlab, 
     .                        0.5-xorg, labsize-yorg,
     .                        ppl_left_just, labsize,
     .                        '@AS'//imposed_lab(:slen),
     .                        lab_loc_absolute, lab_loc_absolute )
	   ELSE
* ... lower left corner, rotated along the vertical page edge
              CALL PUT_LABEL( ppl_movlab,
     .                        2*labsize-xorg, 0.5-yorg,
     .                        ppl_left_just, labsize,
     .                        '@AS'//imposed_lab(:slen),
     .                        lab_loc_absolute, lab_loc_absolute )

* ... rotate it
	      WRITE ( buff30, 3100 )	nlabs_on
 3100	      FORMAT ('RLABS ',I4, ',90')
	      CALL PPLCMD ( from, line, 0, buff30, 1, 1 )
	   ENDIF
	ENDIF

	RETURN
	END
