#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifndef NVTYPE
#  if defined(USE_LONG_DOUBLE) && defined(HAS_LONG_DOUBLE)
#    define NVTYPE long double
#  else
#    define NVTYPE double
#  endif
typedef NVTYPE NV;
#endif

#ifndef newSVuv
#  define newSVuv(uv) (uv > ((~((UV)0))>>1) ? newSVnv((NV)uv) : newSViv((IV)uv))
#endif

#ifndef aTHX_
#  define aTHX_
#endif

#ifndef SvGETMAGIC
#  define SvGETMAGIC(x) STMT_START { if (SvGMAGICAL(x)) mg_get(x); } STMT_END
#endif

#define TABSIZE 256

static UV reflect(UV in, int width)
{
  int i;
  UV out = 0;

  for (i = width; in; i--, in >>= 1)
    out = (out << 1) | (in & 1);

  return out << i;
}

MODULE = Digest::CRC		PACKAGE = Digest::CRC		

PROTOTYPES: ENABLE

SV *
_tabinit(width, poly, ref)
	IV width
	UV poly
	IV ref

	PREINIT:
		UV *tab;
		UV mask, t, r, i;
		int j, wm8;

	CODE:
		if (ref)
		  poly = reflect(poly, width);

		mask = ((UV)1)<<(width-1);
		mask = mask + (mask-1);

		i = TABSIZE*sizeof(UV);
		RETVAL = newSV(i);
		SvPOK_only(RETVAL);
		SvCUR_set(RETVAL, i);
		tab = (UV *) SvPVX(RETVAL);

		if (!ref) {
		  t = ((UV)1) << (width - 1);
		  wm8 = width - 8;
		}

		for (i = 0; i < TABSIZE; i++) {
		  if (ref) {
		    r = i;
		    for (j = 0; j < 8; j++)
		      if (r & 1)
		        r = (r >> 1) ^ poly;
		      else
		        r >>= 1;
		  }
		  else {
		    r = i << (width - 8);
		    for (j = 0; j < 8; j++)
		      if (r & t)
		        r = (r << 1) ^ poly;
		      else
		        r <<= 1;
		  }
		  tab[i] = r & mask;
		}

	OUTPUT:
		RETVAL

SV *
_crc(message, width, init, xorout, refin, refout, table)
	SV *message
	IV  width
	UV  init
	UV  xorout
	IV  refin
	IV  refout
	SV *table

	PREINIT:
		UV crc, mask, *tab;
		STRLEN len;
		const char *msg, *end;

        CODE:
		SvGETMAGIC(message);

		crc  = refin ? reflect(init, width) : init;
		msg  = SvPV(message, len);
		end  = msg + len;
		mask = ((UV)1)<<(width-1);
		mask = mask + (mask-1);
		tab  = (UV *) SvPVX(table);

		if (refin) {
		  while (msg < end)
		    crc = (crc >> 8) ^ tab[(crc ^ *msg++) & 0xFF];
		}
		else {
		  int wm8 = width - 8;
		  while (msg < end)
		    crc = (crc << 8) ^ tab[((crc >> wm8) ^ *msg++) & 0xFF];
		}

		if (refout ^ refin)
		  crc = reflect(crc, width);

		crc = (crc ^ xorout) & mask;

		RETVAL = newSVuv(crc);

        OUTPUT:
		RETVAL
