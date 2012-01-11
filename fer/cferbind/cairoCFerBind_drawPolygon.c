/* Python.h should always be first */
#include <Python.h>
#include <cairo/cairo.h>
#include <stdio.h>
#include <string.h>
#include "cferbind.h"
#include "cairoCFerBind.h"
#include "grdel.h"

/*
 * Draw a polygon to this "Window".
 *
 * Arguments:
 *     ptsx   - x-coordinates of the polygon vertices
 *     ptsy   - y-coordinates of the polygon vertices
 *     numpts - number of vertices given in ptsx and ptsy
 *     brush  - Brush object to use for filling the polygon
 *     pen    - Pen object to use for drawing the polygon edges
 *
 * Coordinates are in units of pixels from te upper left corner,
 * increasing as one goes to the bottom right corner.  The last
 * vertex given will always be attached to the first vertex.
 *
 * If the brush argument is NULL, the polygon will not be filled.
 * If the pen argument is NULL, the polygon edges will be drawn
 * using a solid cosmetic pen with the same color/pattern as the
 * brush.
 *
 * Returns one if successful.   If an error occurs, grdelerrmsg
 * is assigned an appropriate error message and zero is returned.
 */
grdelBool cairoCFerBind_drawPolygon(CFerBind *self, double ptsx[], double ptsy[],
                                    int numpts, grdelType brush, grdelType pen)
{
    CairoCFerBindData *instdata;
    CCFBBrush *brushobj;
    CCFBPen   *penobj;
    double     unitfactor;
    double     xval, yval;
    int        k;
    double     adjwidth;
    double     adjdashes[8];

    /* Sanity checks */
    if ( self->enginename != CairoCFerBindName ) {
        sprintf(grdelerrmsg, "cairoCFerBind_drawPolygon: unexpected error, "
                             "self is not a %s CFerBind struct", CairoCFerBindName);
        return 0;
    }
    instdata = (CairoCFerBindData *) self->instancedata;
    if ( instdata->context == NULL ) {
        strcpy(grdelerrmsg, "cairoCFerBind_drawPolygon: unexpected error, "
                            "NULL context");
        return 0;
    }
    if ( brush != NULL ) {
        brushobj = (CCFBBrush *) brush;
        if ( brushobj->id != CCFBBrushId ) {
            strcpy(grdelerrmsg, "cairoCFerBind_drawPolygon: unexpected error, "
                                "brush is not CCFBBrush struct");
            return 0;
        }
    }
    else
        brushobj = NULL;
    if ( pen != NULL ) {
        penobj = (CCFBPen *) pen;
        if ( penobj->id != CCFBPenId ) {
            strcpy(grdelerrmsg, "cairoCFerBind_drawPolygon: unexpected error, "
                                "pen is not CCFBPen struct");
            return 0;
        }
    }
    else
        penobj = NULL;
    if ( (brushobj == NULL) && (penobj == NULL) ) {
        strcpy(grdelerrmsg, "cairoCFerBind_drawPolygon: "
                            "both brush and pen are NULL");
        return 0;
    }
    if ( numpts < 2 ) {
        strcpy(grdelerrmsg, "cairoCFerBind_drawPolygon: "
                            "fewer than two points given");
        return 0;
    }

    /* Convertions factor for those surfaces that expect points instead of pixels */
    switch( instdata->imageformat ) {
    case CCFBIF_PDF:
    case CCFBIF_PS:
    case CCFBIF_SVG:
        unitfactor = CCFB_POINTS_PER_PIXEL;
        break;
    default:
        unitfactor = 1.0;
        break;
    }

    /* Create the path that will be filled and/or stroked */
    cairo_new_path(instdata->context);
    xval = ptsx[0] * unitfactor;
    yval = ptsy[0] * unitfactor;
    cairo_move_to(instdata->context, xval, yval);
    for (k = 1; k < numpts; k++) {
        xval = ptsx[k] * unitfactor;
        yval = ptsy[k] * unitfactor;
        cairo_line_to(instdata->context, xval, yval);
    }
    cairo_close_path(instdata->context);

    /* First fill the path, if appropriate */
    if ( brushobj != NULL ) {
        /* Fill pattern or solid color */
        if ( brushobj->pattern != NULL )
            cairo_set_source(instdata->context, brushobj->pattern);
        else if ( instdata->usealpha )
            cairo_set_source_rgba(instdata->context, brushobj->color.redfrac,
                  brushobj->color.greenfrac, brushobj->color.bluefrac,
                  brushobj->color.opaquefrac);
        else
            cairo_set_source_rgb(instdata->context, brushobj->color.redfrac,
                  brushobj->color.greenfrac, brushobj->color.bluefrac);
        /* Fill the polygon, but preserve the path for stroking */
        cairo_fill_preserve(instdata->context);
    }

    /* Now stroke the path */
    if ( penobj != NULL ) {
        /* Assign the line color to the context */
        if ( instdata->usealpha )
            cairo_set_source_rgba(instdata->context, penobj->color.redfrac,
                  penobj->color.greenfrac, penobj->color.bluefrac,
                  penobj->color.opaquefrac);
        else
            cairo_set_source_rgb(instdata->context, penobj->color.redfrac,
                  penobj->color.greenfrac, penobj->color.bluefrac);
        /* Assign the adjusted line width */
        adjwidth = penobj->width * instdata->viewfactor;
        if ( adjwidth < 1.0 )
            adjwidth = 1.0;
        adjwidth *= unitfactor;
        cairo_set_line_width(instdata->context, adjwidth);
        /* Assign the line style (solid/dash/dor/dashdot) using the adjusted width */
        for (k = 0; k < penobj->numdashes; k++)
            adjdashes[k] = penobj->dashes[k] * adjwidth;
        cairo_set_dash(instdata->context, adjdashes, penobj->numdashes, 0.0);
        if ( cairo_status(instdata->context) != CAIRO_STATUS_SUCCESS ) {
            strcpy(grdelerrmsg, "cairoCFerBind_drawPolygon: unexpected error, "
                                "problems setting pen dashes");
            return 0;
        }
        /* Assign the line cap and join styles */
        cairo_set_line_cap(instdata->context, penobj->captype);
        cairo_set_line_join(instdata->context, penobj->jointype);
    }
    else {
        /* Source already assigned; make a cosmetic solid line */
        cairo_set_line_width(instdata->context, unitfactor);
        cairo_set_dash(instdata->context, NULL, 0, 0.0);
        cairo_set_line_cap(instdata->context, CAIRO_LINE_CAP_SQUARE);
        cairo_set_line_join(instdata->context, CAIRO_LINE_JOIN_BEVEL);
    }

    /* stroke and remove the path */
    cairo_stroke(instdata->context);

    return 1;
}

