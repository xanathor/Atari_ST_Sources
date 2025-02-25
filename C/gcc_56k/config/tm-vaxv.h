/* Definitions of target machine for GNU compiler.  Vax sysV version.
   Copyright (C) 1988 Free Software Foundation, Inc.

This file is part of GNU CC.

GNU CC is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 1, or (at your option)
any later version.

GNU CC is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with GNU CC; see the file COPYING.  If not, write to
the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.  */

#include "tm-vax.h"

/* Cope with these under SysV */

#define SCCS_DIRECTIVE

/* Output #ident as a .ident.  */

#define ASM_OUTPUT_IDENT(FILE, NAME) fprintf (FILE, "\t.ident \"%s\"\n", NAME);

#undef DBX_DEBUGGING_INFO
#define SDB_DEBUGGING_INFO

/* The .file command should always begin the output.  */
#undef ASM_FILE_START
#define ASM_FILE_START(FILE) sdbout_filename ((FILE), main_input_filename)

#undef ASM_OUTPUT_ALIGN
#define ASM_OUTPUT_ALIGN(FILE,LOG) \
  fprintf(FILE, "\t.align %d\n", 1 << (LOG))

#undef ASM_OUTPUT_LOCAL
#define ASM_OUTPUT_LOCAL(FILE,NAME,SIZE,ROUNDED)	\
( fputs (".data\n", (FILE)),			\
  assemble_name ((FILE), (NAME)),		\
  fprintf ((FILE), ":\n\t.space %d\n", (ROUNDED)))

#define ASM_OUTPUT_ASCII(FILE,PTR,LEN)  \
{							\
  char *s;						\
  int i;						\
  for (i = 0, s = (PTR); i < (LEN); s++, i++)		\
    {							\
      if ((i % 8) == 0)					\
	fputs ("\n\t.byte\t", (FILE));			\
      fprintf ((FILE), "%s0x%x", (i%8?",":""), (unsigned)*s); \
    }							\
  fputs ("\n", (FILE));					\
}

#undef ASM_OUTPUT_DOUBLE
#define ASM_OUTPUT_DOUBLE(FILE,VALUE)  \
  fprintf (FILE, "\t.double 0d%.20e\n", (VALUE))
