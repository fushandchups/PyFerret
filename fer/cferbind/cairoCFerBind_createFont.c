/* Python.h should always be first */
#include <Python.h>
#include <string.h>
#include "grdel.h"
#include "cferbind.h"
#include "cairoCFerBind.h"

/* Instantiate the global value */
const char *CCFBFontId = "CCFBFontId";

/*
 * Create a font object for this "Window".
 *
 * Returns a font object if successful.   If an error occurs,
 * grdelerrmsg is assigned an appropriate error message and NULL
 * is returned.
 */
grdelType cairoCFerBind_createFont(CFerBind *self, const char *familyname, int namelen,
                        double fontsize, int italic, int bold, int underlined)
{
    CairoCFerBindData *instdata;
    double adjfontsize;
    char *family;
    CCFBFont *fontobj;
#ifndef USEPANGOCAIRO
    cairo_font_slant_t slant;
    cairo_font_weight_t weight;
#endif

    /* Sanity check */
    if ( (self->enginename != CairoCFerBindName) &&
         (self->enginename != PyQtCairoCFerBindName) ) {
        strcpy(grdelerrmsg, "cairoCFerBind_createFont: unexpected error, "
                            "self is not a valid CFerBind struct");
        return NULL;
    }
    if ( fontsize <= 0.0 ) {
        strcpy(grdelerrmsg, "cairoCFerBind_createFont: invalid font size given");
        return NULL;
    }
    instdata = (CairoCFerBindData *) self->instancedata;
    /* adjust the font size for whether the surface is in pixels or points */
    if ( (instdata->imageformat == CCFBIF_PNG) ||
         (instdata->imageformat == CCFBIF_REC) ) {
        adjfontsize = fontsize / CCFB_POINTS_PER_PIXEL;
    }
    else {
        adjfontsize = fontsize;
    }

    if ( familyname == NULL ) {
        strcpy(grdelerrmsg, "cairoCFerBind_createFont: familyname is not given");
        return NULL;
    }
    if ( namelen < 0 ) {
        strcpy(grdelerrmsg, "cairoCFerBind_createFont: invalid familyname length given");
        return NULL;
    }

    fontobj = (CCFBFont *) PyMem_Malloc(sizeof(CCFBFont));
    if ( fontobj == NULL ) {
        strcpy(grdelerrmsg, "cairoCFerBind_createFont: "
                            "out of memory for a CCFBFont structure");
        return NULL;
    }

    family = (char *) PyMem_Malloc(namelen+1);
    if ( family == NULL ) {
        strcpy(grdelerrmsg, "cairoCFerBind_createFont: "
                            "out of memory for a copy of the familyname string");
        PyMem_Free(fontobj);
        return NULL;
    }
    strncpy(family, familyname, namelen);
    family[namelen] = '\0';

#ifdef USEPANGOCAIRO

    fontobj->fontdesc = pango_font_description_new();
    pango_font_description_set_family(fontobj->fontdesc, family);
    if ( italic == 0 )
        pango_font_description_set_style(fontobj->fontdesc, PANGO_STYLE_NORMAL);
    else
        pango_font_description_set_style(fontobj->fontdesc, PANGO_STYLE_ITALIC);
    if ( bold == 0 )
        pango_font_description_set_weight(fontobj->fontdesc, PANGO_WEIGHT_NORMAL);
    else
        pango_font_description_set_weight(fontobj->fontdesc, PANGO_WEIGHT_BOLD);
    pango_font_description_set_variant(fontobj->fontdesc, PANGO_VARIANT_NORMAL);
    pango_font_description_set_stretch(fontobj->fontdesc, PANGO_STRETCH_NORMAL);
    pango_font_description_set_size(fontobj->fontdesc, (int) (adjfontsize * PANGO_SCALE + 0.5));

#else

    if ( italic != 0 )
	    slant = CAIRO_FONT_SLANT_ITALIC;
    else
       slant = CAIRO_FONT_SLANT_NORMAL;
    if ( bold != 0 )
       weight = CAIRO_FONT_WEIGHT_BOLD;
    else
       weight = CAIRO_FONT_WEIGHT_NORMAL;
    fontobj->fontface = cairo_toy_font_face_create(family, slant, weight);
    if ( cairo_font_face_status(fontobj->fontface) != CAIRO_STATUS_SUCCESS ) {
        strcpy(grdelerrmsg, "cairoCFerBind_createFont: "
                            "unable to find a font face for the given font");
        cairo_font_face_destroy(fontobj->fontface);
        PyMem_Free(family);
        PyMem_Free(fontobj);
        return NULL;
    }
    fontobj->fontsize = adjfontsize;

#endif

    PyMem_Free(family);

    fontobj->underline = underlined;
    fontobj->id = CCFBFontId;
    return fontobj;
}

