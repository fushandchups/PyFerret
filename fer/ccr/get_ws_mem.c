/*
 *
 * Allocate c heap storage needed for the storage of Ferret work storage
 * and pass the pointer to it to an FORTRAN 90
 * routine that will save it in COMMON
 *
 * V702 1/17 *sh* for trac enhancement #2369 -- dynamic memory management
 *
 */

#include <Python.h> /* make sure Python.h is first */
#include "ferret.h"
#include "FerMem.h"

void FORTRAN(get_ws_mem)(int *index, int *alen, int *status)
/*
  input  - index:  Ferret ws index at which to store the array pointer
  input  - alen:   array length
*/
{
  double *pointer;

  pointer = (double *) FerMem_Malloc(sizeof(double) * (*alen), __FILE__, __LINE__);

  if (pointer)
    {
      FORTRAN(store_ws_ptr) (index, alen, pointer);
      *status = 3;
    }
  else
    *status = 0;

  return;
}
