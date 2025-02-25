/*
 * $Header: f:/src/gulam\RCS\gmcatari.c,v 1.1 1991/09/10 01:02:04 apratt Exp $ $Locker:  $
 * ======================================================================
 * $Log: gmcatari.c,v $
 * Revision 1.1  1991/09/10  01:02:04  apratt
 * First CI of AKP
 *
 * Revision: 1.12 90.01.15.18.15.22 apratt 
 * Changed df's output from free/total to free/used/total.
 * 
 * Revision: 1.11 89.06.16.17.23.48 apratt 
 * Header style change.
 * 
 * Revision: 1.10 89.03.30.17.56.42 Author: apratt
 * Added setting a NEW dta to the save/restore DTA bit.
 * 
 * Revision: 1.9 89.03.30.17.50.20 Author: apratt
 * Added saving of caller's DTA and restoring to shell_p handler.
 * 
 * Revision: 1.8 89.03.28.13.02.32 Author: apratt
 * Added code to set masterdate when we make the Tgettime/Tgetdate call.
 * Doesn't add execution time, but keeps us up to date often enough.
 * 
 * Revision: 1.7 89.02.14.14.57.20 Author: apratt
 * Changed tooold to use masterdate rather than stamptime(), which
 * makes two OS calls.  This means the question of "too old" means
 * "over a year old when you STARTED GULAM" not a year old from NOW.
 * 
 * Revision: 1.6 89.02.07.14.05.00 Author: apratt
 * mem did not work, does now
 * 
 * Revision: 1.5 89.02.07.13.31.40 Author: apratt
 * Reinstated mem, but made it more innocuous
 * 
 * Revision: 1.4 89.02.07.12.29.10 Author: apratt
 * Changed cmdfirst to cmdprobe ... see main.c for more.
 * 
 * Revision: 1.3 89.02.01.18.31.14 Author: apratt
 * Added yearstr and tooold, used by ls -l to show year rather
 * than time when a file is tooold() (twelve months).
 * 
 * Revision: 1.2 89.02.01.17.58.40 Author: apratt
 * Fixed lack of unredirection when _shell_p is used.  Problem was
 * that doredirections clobbered the (static) fda[] array without
 * noticing that it should be nesting redirections.  callgulam()
 * now saves & restores fda[].
 * 
 * Callgulam also now performs keyreset() after processcmd() because
 * otherwise calling ue or te from shell_p causes kb to be gu-ized.
 * 
 * Revision: 1.1 89.01.11.14.37.50 Author: apratt
 * Initial Revision
 * 
 */

/*
	machine.c of Gulam/uE -- machine/system specific rtns and vars

*/

/* 890111 kbad	Changed OS name to TOS (AtariST/TOS is silly)
*/

#include "gu.h"

#ifdef STANC
# define P_(s) s
#else
# define P_(s) ()
#endif
local readtime P_((void));
local twodigits P_((int a, uchar *p));
local maketimestr P_((int hr, int min, int sec, uchar *p));
local sbf P_((int p, long m, int i));
#ifdef __GNUC__
local int peekw P_((int *a));
local void pokew P_((int *a, int v));
#endif
#undef P_

#if	!TOS
/* %%	AtariSt/TOS	version */
#endif

#ifdef	H
extern	long	getticks();

			/* Insert user-id (10 chars at most) at p. */
#define	userid(x, p)	strcpy(p, "u         ")
#define	execfile(g, cmdln, envp) Pexec(0, g, cmdln, envp)
#endif

#ifndef H 

/* The following have AtariSt specific special chars embedded in the
strings.  These special chars are visually more appealing; they have
no other functional requirements.  */

uchar	OS[]		= "TOS";
uchar	GulamLogo[]	= "\257gul\204m\256";
uchar	Copyright[]	= "\275";
uchar	defaultprompt[] = "\257\257 ";		/* two > > chars */
uchar	Mini[]		= "\257mini\256";
uchar	Completions[]	= "\257completions\256";
uchar	uE[]		= "\346\356";		/* mu-epsilon */
uchar	Bufferlist[]	= "\257buffers\256";
uchar	Tempexit[]	=
"temporarily exiting to \257gul\204m\256; buffers are NOT freed...\r\n";

uchar	DS0[] = "\\";		/* file path name related strings */
uchar	DS1[] =	"\\.";
uchar	DS2[] =	"\\\\";
uchar	DS3[] = "\\~";
uchar	DS4[] = ":\\";
uchar	DS5[] =	"\\..\\";

uchar ext[SZext] = "g\000\000\000tos\000ttp\000prg\000";

long	_stksize	= 8*1024L;	/* controls stack size	*/
uint32	starttick;

local uint32	present	= 0L;	  /* Present time in 200-Hz ticks */

/* Read the value of the systems 200-Hz counter (located at 0x4baL).
Must be called in Super Mode.  */

local	readtime()	{present = *((long *) 0x000004baL);}

/* Get the present time (in ticks) to the highest degree of accuracy
possible.  */

	uint32
getticks()
{
	Supexec(readtime);
	return present;
}

/* Compute the time spent by the just executed cmd.  AtariST ticks at
200Hz.  */

computetime()
{	register int	hr, mn, sc;
	register long	totalticks;
	uchar		tm[10];

	if (starttick == 0L) return;
	totalticks = getticks() - starttick; starttick = 0L;
	if (totalticks < 0L) {totalticks += 0x7fffffffL; totalticks ++;}
	sc = (int) ((totalticks+100L)/200L);
	mn = sc/60;	sc -= mn*60;
	hr = mn/60;	mn -= hr*60;
	maketimestr(hr, mn, sc, tm); tm[8] = '\000';	/* see ls.c */
	outstr(sprintp("time spent by cmd = %s (%D 5ms-ticks)",
		tm, totalticks));
}

/* Stamp current date-time into the [] pted by ip. */
/* AKP: also set master date & time, since we're bothering anyway... */

stamptime(ip)
register int ip[];
{
	extern unsigned int masterdate[2];
	ip[0] = masterdate[0] = Tgetdate();
	ip[1] = masterdate[1] = Tgettime();
}

	local
twodigits(a, p)			/* the last two decimal digits of A	*/
register int	a;		/* are stuffed into p[0], p[1]		*/
register uchar *p;
{
	*p++   = (a%100)/10 + '0';
	*p = a%10 + '0';
}

/* Make a date string from d, and stuff it in p[0..6]; no \0 in
p[0..7].  */

datestr(d, p)
register int	d;
register uchar	*p;
{
	static uchar * mons[] =
	{	"???", 
		"Jan", "Feb", "Mar",	"Apr", "May", "Jun",
		"Jul", "Aug", "Sep",	"Oct", "Nov", "Dec",
		"???", "???", "???"
	};

	register int day, mon;

	day = (d & 0x001F);
	mon = (d >> 5) & 0x000F;
/*	yr  = ((d >> 9) & 0x01FF) + 1980;	*/
	strcpy(p, mons[mon]);
	twodigits(day, p+4);
	p[3] = p[6] = ' ';
	if (p[4] == '0') p[4] = ' ';
}

/* tooold and yearstr added by AKP so ls -l shows year, not time */
/* for very old files (>= 1 year old) */

tooold(date)
register unsigned int date;
{
	extern unsigned int masterdate[2];
	return ((masterdate[0] - date) >= 0x0180); /* 0x180 is 12 months */
}

yearstr(date,s)
register unsigned int date;
register char *s;
{
	*s++ = ' ';
	date = ((date >> 9) + 1980);
	twodigits(date/100,s);
	twodigits(date%100,s+2);
}

/* Make a string (hr:mi:se) from the first three args, and store the
string in area p[0..7].  */

	local
maketimestr(hr, min, sec, p)
register int	min, hr, sec;
register uchar	*p;
{
	twodigits(hr,  p);
	twodigits(min, p+3);
	twodigits(sec, p+6);
	p[2] = p[5] = ':';
}

/* Make a time string from d, and stuff it in p[0..7]; no \0 in
p[0..8].  */

timestr(t, p)
register int	t;
register uchar	*p;
{
	register int	min, hr, sec;

	min = (t >> 5)  & 0x003F;
	hr  = (t >> 11) & 0x001F;
	sec = (t        & 0x001F) << 1;
	maketimestr(hr, min, sec, p);
}

local	uchar	*new;	/* ptr to new time date string	*/
local	long	td;	/* time and date in internal TOS form		*/

/* Assign bit field <i:j> of td with a computed value from new[p],
new[p+1] which should be decimal digits, where j == i - 1 + #1's in
mask m */

	local
sbf(p, m, i)
long	m;
int	i, p;
{
	register int	a, b;
	register long	ll;

	a = new[p++];	b = new[p];
	if (	(a == 0) || (b == 0)
	||	(a > '9')|| (a < '0')
	||	(b > '9')|| (b < '0')	) return;

	ll = (long) ((a - '0') *10 + b - '0');
	if (i == 0) ll >>= 1;	/* couple of kludges! for 2*sec and yr */
	else if (i == 25) ll -= 80;
	ll = (ll << i) & m;
	td = (td & ~m) | ll;
}


/* Get/Set date and time; Get returns the date-stime string in strg,
which should be free()d when done.  Exported.  */

gsdatetime(s)
uchar *s;
{
	register int	*ip;
	register uchar	*q;

	stamptime(ip = (int *) &td);
	if (*s)
	{	new = q = gmalloc(((uint)(strlen(s) + 20))); if (new == NULL) return;
		while (*q++ = *s++);
		for (q--; q < new+20;) *q++ = ' ';
		sbf(0,  (long) (0x0000000FL << 21), 21);/* month */
		sbf(3,  (long) (0x0000001FL << 16), 16);/* day */
		sbf(6,  (long) (0x0000003FL << 25), 25);/* yr, 20th century */
		sbf(9,  (long) (0x0000001FL << 11), 11);/* hr */
		sbf(12, (long) (0x0000003FL << 5),  5);	/* min */
		sbf(15, (long) (0x0000001FL),       0);	/* sec */

		Settime(td);		/* set ikbd clock */
		Tsettime(ip[1]); Tsetdate(ip[0]);
		gfree(new);
	} else
	{	strg = q = gmalloc(16);
		datestr(ip[0], q);
		timestr(ip[1], q+7);
		q[15] = '\000';
	}
}

/* 'gem' is a prefix to cmds in Gulam on AtariST.  This rtn gets
called from docmd(); see do.c */

Gem()			
{	register WS	*ws;
	extern	 uchar	Scrninit[];

	gputs(Scrninit); drawshadedrect(); mouseon(); 
	ws = useuplexws();	shiftws(ws, 1);
	gfree(execcmd(ws));
	mouseoff();	gputs(Scrninit);
	refresh();	/* redisplay windows */
}

/* Caller wants to get one line of input from user through the builtin
ue of Gulam.  Dont do a cr-lf after the line.  If caller so choses, he
can.  Called only via (*_shell_p)(p); the p better be a ptr to a
SZcmd-long byte area. */

getlineviaue(p)
register uchar	*p;
{	register uchar	*q;

	keysetup();
	if (q = getoneline()) strcpy(p, q);
	else *p = '\000';
	keyreset();
}

/* Called only via (*_shell_p)(p); returns the status of the cmd */

callgulam(p)
register uchar	*p;
{	extern	 uchar	Status[];
	extern   int	exitue;
	register int	e;
	extern	 int	cmdprobe;	/* AKP */
	extern	 int	fda[4];
	int		sfda[4];
	DTA		newdta, *olddta;	/* AKP */

	/* added saving of caller's DTA (AKP) */
	olddta = (DTA *)Fgetdta();
	Fsetdta(&newdta);
	/* added saving of fda's so redirection is undone properly (AKP) */
	for (e=0; e<4; e++) sfda[e] = fda[e];
	e = exitue; exitue = 2;
	insertvar(Status, "0");
	cmdprobe = 0;			/* AKP */
	processcmd(strdup(p), 0);
	exitue = e;
	/* added keyreset because otherwise it's not done (AKP) */
	keyreset();
	for (e=0; e<4; e++) fda[e] = sfda[e];
	Fsetdta(olddta);
	return varnum(Status);
}

setgulam()
{	register long	n;
	extern	 int	togulam();	/* in mwc.s	*/

	n = Super(0L);	/* _shell_p = 0x4f6L */
	*((long *)(0x00004f6L)) = (long) (togulam);
	Super(n);
}


typedef struct MDB			/* Memory Descriptor Block */
{	struct MDB	*next;		/* ptr to next descriptor */
	uchar		*base;		/* base of memory block */
	long		length;		/* length of memory block */
	long		owner;		/* owner's process id; meaning?? */
} MDB;

typedef struct				/* Memory Parameter Block */
{	MDB		*freelst;	/* free descriptor list head */
	MDB		*usedlst;	/* allocated descriptor list head */
	MDB		*roverp; 	/* ptr of unknown use */
} MPB;

	local
showmemlst(p, ws)
register MDB	*p;
register WS	*ws;
{
	register long	total, n;
	MDB	md;

	for (total = 0L; p; p = md.next)
	{	n = Super(0L); md = *p; Super(n);
		n = md.length;
		total += n;
		strwcat(ws, sprintp("%D \tbytes at %D  \towned by %D\r\n",
			n, md.base, md.owner), 0);
}	}

mem()
{
#ifdef NEVER
	register WS	*ws;
	register uchar	*p;
	/* pointer to GEMDOS memory parameter block	*/
	register MPB *gdosmpb;

	/* magic location addresses below! */
	gdosmpb = (*((long *)0xfc0018L) == 0x04221987L? /* ROM date */
		(MPB *) 0x00007e8eL :	/* Bammi & I labored for this! */
		(MPB *) 0x000056ecL);	/* thanks to Konrad Hahn */
	ws = initws(); p = lexgetword();
	if (*p)
	{if (*p != 'i')
	 {strwcat(ws, "Malloc lst: \r\n",0); showmemlst(gdosmpb->usedlst,ws);}
	 else showgumem();
	}
	strwcat(ws, "free   lst: \r\n",0); showmemlst(gdosmpb->freelst,ws);
	if (ws) {strg = ws->ps; gfree(ws);}
#else
	register WS	*ws = initws();
	long size;
	unsigned long *buf, *first, *last = 0;

	while ((size = Malloc(-1L)) >= 8) {
		buf = (unsigned long *)Malloc(size);
		strwcat(ws, sprintp("%D\tbytes free at %D\r\n",size,buf),0);
		if (last) *last = buf;
		else first = buf;
		last = buf;
		*buf = 0;
	}
	/* free all those buffers */
	buf = first;
	while (buf) {
		last = *buf;
		Mfree(buf);
		buf = last;
	}
	if (ws) {strg = ws->ps; gfree(ws);}
#endif
}

/* Try allocating a buffer as large as the requested size in nb.
Return the actual allocated size in nb.  At any time, only at most
one such block of mem is in use.  Must never fail, so we may
return the ptr to a static area.  Therefore, it must be freed by
maxfree().  TOS Malloc() gets unreliable if we call it too many (how many?)
times; so avoid using it unless necessary. */

local int	maxastate;
local uchar	rainyday[512];
local uchar	*maxap;

	uchar *
maxalloc(nb)
long	*nb;
{	register uchar		*q;
	register unsigned int	sz;
	register long		lsz;

#define	bsz0	19*1024
#define	bszD	1024

	q = NULL;
	if (maxastate != 0) goto ret;
	
	if (*nb > 0x0000FFFEL)
	{ if ((lsz = Malloc(-1L)) && (q = (uchar *) Malloc(lsz)))
		{*nb = lsz; maxastate = 1; goto ret;}
	}
	/* will go thru loop at least once; so q will be def */
	for (sz = (*nb == 0? bsz0 : *nb); sz >= bszD; sz -= bszD)
		if (q = gmalloc(sz)) break;
	if (q)	{*nb = (long) sz; maxastate = 2;}
	else	{*nb = 512L;	  maxastate = 3; q = rainyday;}

	ret:
	maxap = q;
	return q;
}

maxfree(p)
register uchar	*p;
{
	if (p == maxap) 	/* else stray ptr */
	{	if (maxastate == 2) gfree(p);	else
		if (maxastate == 1) Mfree(p);
	}
	ret: maxastate =  0;
}


lpeekw()
{	register int	*a, v;
	register uchar	*p;

	p = lexgetword();  if (*p == '\000') return;
	a = (int *) (atoir(p, 16) & 0xFFFFFFFEL);
	v = peekw(a); 	/* peekw() is in MWC lib */
	strg = strdup(sprintp("word 0x%X has 0x%x", a, v));
}

lpokew()
{	register int	*a, v;
	register uchar	*p, *q;

	p = lexgetword(); q = lexgetword();
	if (*p && *q)
	{	a = (int *) (atoir(p, 16) & 0xFFFFFFFEL);
		v = (int) atoir(q, 16);
		pokew(a, v);	/* pokew() is in MWC lib */
}	}

#ifdef __GNUC__
local int peekw(a)
int *a;
{
    long ssp = Super(0L);
    int ret = *a;
    Super(ssp);
    return ret;
}

local void pokew(a, v)
int *a, v;
{
    long ssp = Super(0L);
    *a = v;
    Super(ssp);
}
#endif

/* cmd stx: format -1/2 [a] [b].  Formats with 11-sector interleaving, but
with 9 sectors/track. */

format(p)
register uchar *p;
{	register int	nb, t, drive, ns, sides, disktype, nerr, *ip, *bf;
	register uchar	c;

	drive = 0; sides = 1 + negopts['2']; valu = 1;
	if (c = *p)
	{	if (c != 'a' && c != 'b') return;
		drive = c - 'a';
	}
	disktype = 1+sides;
	bf = (int *) gmalloc(9*512*2); if (bf == NULL) {valu = -39; return;}
	for (nerr = nb = t = 0; t < 80; t++)
	  for (ns = sides; ns-- > 0;)
	  { userfeedback(sprintp
		("\033f\rtrack %d, side %d, bad sectors %d, status %D\033K:",
			t, ns, nb, valu), 1);
	    valu = Flopfmt(bf, 0L, drive, 9, t, ns,11, 0x87654321L, 0xE5E5);
	    for (ip = (int *) bf; *ip++;) nb++;
	    if (useraborted()) {valu = -1; goto freebf;}
	  }
	for (t = 9*512; t--;) bf[t] = 0;
	for (t = 0; t < 2; t++)
		valu = Flopwr(bf, 0L, drive, 1, t, 0, 9);
	Protobt(bf, (long) Random(), disktype, 0);
	valu += Flopwr (bf, 0L, drive, 1, 0, 0, 1);
	valu += Flopver(bf, 0L, drive, 1, 0, 0, 1);
	freebf:	gfree(bf);
	if (valu == 0L) valu = -nb;
}

	uchar * 				/* exported */
drvmap()
{	register long	n;
	register uchar	*p, c;
	static   uchar	dmap[27];

	n = Drvmap();
	p = dmap;
	for (c='a'; c < 'z'; c++)
	{	if (n & 1L) *p++ = c;
		n >>= 1;
	}
	*p = '\000';
	return dmap;
}

df(p)
register uchar *p;
{
	register int	c;
	long	v[4], nb, total;
	uchar	s[2];

	c = *p;
	if (('A' <= c) && (c <= 'P')) c -= 'A' - 1; else
	if (('a' <= c) && (c <= 'p')) c -= 'a' - 1; else c = 1+(int)Dgetdrv();

	if (Dfree(v, c) >= 0L)
	{	s[0]	= c + 'a' - 1; s[1] = '\000';
		nb	= v[2]*v[3];	/* bytes/cluster	*/
		total	= v[1]*nb;
		nb 	*= v[0];
		outstr(sprintp("%s: free %D, used %D, total %D", 
			s, nb, total-nb, total));
	}
}

dm()
{
	strg = str3cat("drive map: ", drvmap(), ES);
}

#endif	H

/* -eof- */
