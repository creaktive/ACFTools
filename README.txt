##############################################################################
[ACFTools v0.62a] Set of tools to play with ACF files outside of Plane-Maker
Perl script and modules coded by Stanislaw Pusep <stas@sysd.org>
Site of this and another X-Plane projects of mine: http://xplane.sysd.org/

Allows you to:
 * export X-Plane (www.x-plane.com) aircraft data files to human-editable
   plaintext format and 3D mesh editable in AC3D modeler (www.ac3d.org).
 * import plaintext/3D mesh back to ACF file.
##############################################################################

Usage: acftools.exe <commands> [parameters]
 o Commands:
	-extract [DEF]	: extract TXT from ACF (opt: using DEF definition)
        -generate       : generate ACF from TXT
        -merge          : merge body from AC3D file to TXT
 o Parameters:
        -acffile FILE   : name of ACF file to process
        -txtfile FILE   : name of TXT file to process
        -ac3dfile FILE  : name of AC3D file to process
        -noorder        : DO NOT sort vertices while merging bodies
        -noac3d         : DO NOT generate AC3D
        -(min|max)body N: write all bodies in specified range to AC3D
        -force LIST     : force extraction of bodies LIST (comma-separated N)
        -normalize N    : normalize wings to N vert/surface (N>=2 or no wings!)
 o Notes:
        * You can use abbreviations of commands/parameters (-gen or even -g
          instead of -generate).
        * The only required parameter for "extract" command is -acffile.
          Both -txtfile and -ac3dfile are derivated from it.
        * "generate" command and -txtfile has the same relation.
        * By default "extract" uses the latest DEF file.
        * "generate" doesn't need DEF at all (it is implicit in TXT)
        * If file to be created already exists backup is made automatically.
 o Examples:
        acftools.exe --extract=ACF700 --acffile="F-22 Raptor.acf"
        (extract 'F-22 Raptor.txt' from 'F-22 Raptor.acf')

        acftools.exe -e -acf "F-22 Raptor.acf"
        (same as above)

        acftools.exe -me -ac3d ladar.ac -txt "F-22 Raptor.txt"
        (merge *single* 3D body from 'ladar.ac' to 'F-22 Raptor.txt')

        acftools.exe -g -txt "F-22 Raptor.txt"
        (reverse operation; generate 'F-22 Raptor.acf' from 'F-22 Raptor.txt')


Why AC3D (http://www.ac3d.org/)?
================================

You'd better ask "why not?". First of all AC3D can import/export many
different formats like AutoCAD DXF, 3D Studio, Milkshape, and OBJ
between others. Second, AC3D is small and lightweight. Full installation
has below 7 Mb. Third, AC3D format is supported by 'Progressive Fans'
(http://www.terra.es/personal3/atoniman/) so I can view my models directly
from Total Commander (http://www.ghisler.com/). And finally, AC3D has all
editing resources you will ever need. I only see 2 problems with AC3D:
it's shareware and it is for Intel machines, not Apple.


Tips & Tricks:
==============

When generating AC3D model, if ACFTools fails with message:
"No airfoil definition found ..."
you can do one of:

1) Run 'acftools.pl -normalize 0 ...' so wings are skipped.
2) Get into http://www.aae.uiuc.edu/m-selig/ads/coord_database.html
   download right airfoil and edit 'data/airfoil.lst'.
3) Simply edit 'data/airfoil.lst' aliasing new airfoil to any existent
   one, just like:
"Horz Stab.afl			naca2412.dat"

If you with to make your fuselage outside of Plane-Maker you can use
'models/fusepipe.ac' template. Remember to NOT to add/delete vertices
and neither surfaces! This still generates ACF (with warnings) but
X-Plane gets confuse with surface mapping.

If you want to export ACF to render in outer programs (maybe AutoCad? :)
then you'd better optimize AC3D file generated. Just open AC file, then
go to 'Object->Optimize vertices' and THEN 'Object->Optimize surfaces'.
Done this, 'Select->Vertex' and kill all unlinked vertices.
Note that now you can't return this model back to Plane-Maker!!!

By default ACFTools operates with X-Plane 7.0 ACF format. But if you're
sure what are you doing, you can mess with older versions also:

"acftools.pl -e ACF6_51.def -min 28 -max 38 -acf f16.acf"

On line above you will be extracting bodies from 28 to 38 using
X-Plane 6.51 definition file. Sorry, at this moment you need to deduce
'-min' & '-max' values by yourself! Everything you need is a little C
knowledge and "Instructions/Manual_Files/X-Plane ACF_format.html" file
from that version of X-Plane you are messing with.

To extract weapon models just use:

"acftools.pl -e wpn6_601.def -force 0 -acf droptank.wpn"

Special Thanks To:
==================

 * Andy Colebourne for AC3D of course.
 * Austin Meyer for X-Plane itself :)
 * Blair Zajac for Math::Interpolate Perl routines.
 * Emmanuel Sanvito for Perl Utilities and byte-swapping idea I stolen :)
 * Marcelo M. Marques for idea of extracting wings too.
 * Marco Testi for wing & airfoil specifications.
 * Mark Fisher for ACF format definitions.
 * Mark Tecson for being "test pilot" for my QuickIntro.txt
 * Tony Gondola for ACF2Text that was the inspiration for ACFTools.


TODOs:
======

 * Export gear models.


Not TODOs:
==========

 * GUI.
 * Models in other than AC3D format.
 * Control surfaces.
 * Paint mapping.
 * Wing import back to ACF.


Known Bugs/Issues:
==================

ACF to TXT and backwards converters:
 * VERY SLOW.
 * Certainly not bullet-proof; malformed lines will mess all things.
 * If you mess with input file type, you will crash hard.
 * BAD THINGS may happen if you attempt to use wrong definition.
 * Several X-Plane version 7.0 constants are hard-coded. I mean, I
   designed ACFTools to work for latest X-Plane. Other versions work
   but with tons of parameters.
 * It seems that Perl float numbers are different from C float numbers.
   Thus, some are rounded and in some rare cases values are lost at all.

Body-related:
 * You may only import one model at time. Note that I did it to protect
   YOU; if many models would be imported at time they might acidentally
   overwrite things you didn't wanted to be overwritten. Beware!
 * Surface triangulation has inverse order of that observed in X-Plane.
   This doesn't see to be important but who knows?
 * Unlinked vertices from "ghost" sections should be filtered manually.
 * Engine nacelles should be rotated for helos.
 * Wheel fairing surfaces are "convolved" to inside of fairing.
 * When importing AC3D models they do loose original arm.
   But they are re-centered at least :)
 * When merging section vertices are ordered anti-clockwise. May break
   some very weird designs. If it happens to be yours, pass -noorder flag.

Wing-related:
 * No rotor wings at all.
 * I don't understand how *exactly* X-Plane handles incidence.
 
 
Quick Intro:
============
 
How to use ACFTools? Well... My GUI programming skills are poor, so
ACFTools is, as most of my programs, command-line. You can write it
in any folder. For example, C:\ACFTools of C:\X-Plane\ACFTools. But
you may operate it from DOS prompt. Remember this buddy from ancient
computing days? :)
If not, here is brief usage explanation. Go to
"Start->Run", type "command" and press
"OK". This will open black screen which is better seen when
configured to have 80x50 characters-wide. There, you type: "cd
C:\ACFTools" or whatever directory ACFTools is located. There,
type "acftools" (note that "acftools",
"acftools.exe" and "acftools.pl" may be different
files but they do refer the same thing: main ACFTools executable).
That screen that appears is parameter list. Now, for extract good old
747, type:

acftools --extract --acffile="C:\X-Plane\Aircraft\HeavyMetal\B747-400 United\United-Air.acf" --txtfile 747.txt

This will start conversion from ACF to TXT & AC3D formats. Lots of
stuff are dumped to screen. When process is finished, "Press
<RETURN> to exit" appears. At this point, 747.txt & 747.ac
files were created. 747.txt is plaintext detailed description of 747
aircraft. It's HUGE: 5 Mb! Then, 747.ac is AC3D model of 747. Just
open it in AC3D and have a lot of fun :)
Note that you may separate body you wish to edit into separate file.
For example, select "body[47]" group, copy it and paste in
new file: "body.ac". Then edit it as you wish. Note that
you can't add nor delete vertices/surfaces. This is enormous
limitation imposed by X-Plane itself.
When you want to IMPORT edited model back to ACF file, do following:

Step 1:
acftools --merge --ac3dfile=body.ac --txtfile 747.txt
Step 2:
acftools --generate --txtfile 747.txt --acffile 747.acf

Sometimes resulting file is weirdly broken, this is because my
merging algorithm is poor :(
To avoid that use "--noorder" parameter:

acftools --merge --ac3dfile=body.ac --txtfile 747.txt --noorder

Unfortunately ACFTools stills very ugly and difficult to use piece of
software. Even me, it's author, suffered several hours to try to
import cool duct fans into X-Plane. I hope to expand ACFTools in
brief future!


Change Log:
===========

v0.1
	- first public release
v0.2
	- section vertex sorting for merging added
v0.5
	- bug fixes for merging routines
	- support for interpolated wings
	- better organized source & package
	- licensed under GPL
	- propeller blades in different color now
	- added docs/QuickIntro.txt
v0.5a
	- fixed a bug in .WPN handling
v0.6
	- added lib/acf_h2def.pl which aids conversion from Austin's
          "X-Plane ACF_format.html" to standart .def format!
	- added ACF740.def
	- added WPN740.def
	- tested with X-Plane 7.40 RC-2 models
	- now using 7.40 definition by default
	- fixed bug of AC3D writer applying surface to only 12 of 20 sections
	- made some error messages more clear
	- updated author's mail & official site URL
	- added contrib/*.bat contribution by Marcelo M. Marques
v0.61
	- fixed 7.40 "is_left" misc. wing attribute
	  (7.00 also had it, but it was undocumented until 7.40)
	- removed dumb & unnecessary Time::HiRes dependency
	- ACFTools can now run from PATH
	- minor docs/help fixes
	- added models/Seabee.ac model by Tracy Walker sample
v0.62
	- rewritten major part of XPlane::Convert::AC3Dparse
	- now using AC3D 'loc' attribute to get/set bodies arm
	- Win32 binary is now made with PAR - Perl Archive Toolkit
	- recreated models/*
v0.62a
	- fixed WPN740.def: weird radius attribute shi(f)ted 3D model
	- fixed weapon AC3D generation: weapons has no arm
