##############################################################################
[ACFTools v0.1] Set of tools to play with ACF files outside of Plane-Maker
Perl script and modules coded by Stanislaw Pusep <stanis@linuxmail.org>
Site of this and another X-Plane projects of mine:
<http://www.x-plane.org/users/stas/>

Allows you to:
 * export X-Plane (www.x-plane.com) aircraft data files to human-editable
   plaintext format and 3D mesh editable in AC3D modeler (www.ac3d.org).
 * import plaintext/3D mesh back to ACF file.
##############################################################################

Usage: acftools.pl <commands> [parameters]
 o Commands:
	-extract DEF	: extract TXT from ACF
	-generate	: generate ACF from TXT
	-merge		: merge body from AC3D file to TXT
 o Parameters:
	-acffile FILE	: name of ACF file to process
	-txtfile FILE	: name of TXT file to process
	-ac3dfile FILE	: name of AC3D file to process
	-noorder	: DO NOT sort vertices while merging bodies
	-noac3d|nowings	: DO NOT generate AC3D or no wings in AC3D
	-(min|max)body N: write all bodies in specified range to AC3D
	-force LIST	: force extraction of bodies LIST (comma-separated N)
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
        acftools.pl --extract=ACF700.def --acffile="F-22 Raptor.acf" --txtfile="F-22 Raptor.txt"
        (extract 'F-22 Raptor.txt' from 'F-22 Raptor.acf')

        acftools.pl -e -acf "F-22 Raptor.acf"
        (same as above)

        acftools.pl -me -ac3d ladar.ac -txt "F-22 Raptor.txt"
        (merge *single* 3D body from 'ladar.ac' to 'F-22 Raptor.txt')

        acftools.pl -g -txt "F-22 Raptor.txt"
        (reverse operation; generate 'F-22 Raptor.acf' from 'F-22 Raptor.txt')


Why AC3D?
=========

You'd better ask "why not?". First of all AC3D can import/export many
different formats like AutoCAD DXF, 3D Studio, Milkshape, and OBJ
between others. Second, AC3D is small and lightweight. Full installation
has below 7 Mb. And finally, AC3D has all editing resources you will ever
need. I only see 2 problems with AC3D: it's shareware and it is for Intel
machines, not Apple.


Tips & Tricks:
==============

When generating AC3D model, if ACFTools fails with message:
"No airfoil definition found ..."
you can do one of:

1) Run 'acftools.pl -nowings ...' so wings are skipped.
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

 * Austin Meyer for X-Plane itself :)
 * Emmanuel Sanvito for Perl Utilities and byte-swapping idea I stolen :)
 * Marcelo M. Marques for idea of extracting wings too.
 * Marco Testi for wing & airfoil specifications.
 * Mark Fisher for ACF format definitions.
 * Tony Gondola for ACF2Text that was the inspiration for ACFTools.


TODOs:
======

 * Different foils for root & tip.
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
   Thus, some are rounded and in some rare cases values are lost an all.

Body-related:
 * You may only import one model at time. Note that I did it to protect
   YOU; if many models would be imported at time they might acidentally
   overwrite things you didn't wanted to be overwritten. Beware!
 * Surface triangulation has inverse order of that observed in X-Plane.
 * Unlinked vertices from "ghost" sections should be filtered manually.
 * Engine nacelles should be rotated for helos.
 * Wheel fairing surfaces are "convolved" to inside of fairing.
 * When importing AC3D models they do loose original arm.

Wing-related:
 * No rotor wings at all.
 * No different airfoils for root/tip. Root foil applies to the whole wing.
 * I don't understand how *exactly* X-Plane handles incidence.
 * Some airfoils bring mess and desorder to wing surfaces.
