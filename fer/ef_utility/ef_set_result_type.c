/* Make sure Python.h is included first */
#include <Python.h>
#include <stdlib.h>
#include "ferret.h"
#include "EF_Util.h"

void FORTRAN(ef_set_result_type)(int *id_ptr, int *type)
{
  ExternalFunction *ef_ptr;

  ef_ptr = ef_ptr_from_id_ptr(id_ptr);
  if ( ef_ptr == NULL ) {
     abort();
  }
  ef_ptr->internals_ptr->return_type = *type;
}  

