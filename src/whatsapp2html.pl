#!/usr/bin/perl -s
#*************************************************************************
#
#   Program:    whatsapp2html
#   File:       whatsapp2html.pl
#   
#   Version:    V1.1
#   Date:       12.12.18
#   Function:   Convert an exported WhatsApp chat to HTML
#   
#   Copyright:  (c) Dr. Andrew C. R. Martin, 2018
#   Author:     Dr. Andrew C. R. Martin
#   EMail:      andrew@andrew-martin.org
#               
#*************************************************************************
#
#   This program is not in the public domain, but it may be copied
#   according to the conditions laid out in the accompanying file
#   COPYING.DOC
#
#   The code may be modified as required, but any modifications must be
#   documented so that the person responsible can be identified. If 
#   someone else breaks this code, I don't want to be blamed for code 
#   that does not work! 
#
#   The code may not be sold commercially or included as part of a 
#   commercial product except as described in the file COPYING.DOC.
#
#*************************************************************************
#
#   Description:
#   ============
#
#*************************************************************************
#
#   Usage:
#   ======
#
#*************************************************************************
#
#   Revision History:
#   =================
#   V1.0   04.12.18  Original
#   V1.1   12.12.18  Puts in correct HTML entity references for pound
#                    signs, <, > and &
#
#*************************************************************************
use strict;
use Cwd qw(abs_path);
use FindBin;

#*************************************************************************
my $prevDate = '';
my $prevName = '';
my $person   = 0;
my $fpOut;
my $fp;
my $shareDir = abs_path("$FindBin::Bin/share/whatsapp2html");
my $emojiInDir = "$shareDir/emojis";
my $cssInDir   = "$shareDir/css";

# Check command line
if((scalar(@ARGV) == 0) ||
   (scalar(@ARGV) >  2) || 
   defined($::h))
{
    UsageDie();
}

# Set input and output files and directories
my($inDir, $inFile)   = ParseFileName($ARGV[0]);
my($outDir, $outFile) = ParseFileName(scalar(@ARGV)==2?$ARGV[1]:'.', $ARGV[0]);
my $emojiOutDir       = "$outDir/emojis";

# Create output directory if needed
if(! -d $outDir)
{
    `mkdir $outDir`;
    if(! -d $outDir)
    {
        print STDERR "Unable to create output directory: $outDir\n";
        exit 1;
    }
}

# Create output directory for emojis if needed
if(! -d $emojiOutDir)
{
    `mkdir $emojiOutDir`;
    if(! -d $emojiOutDir)
    {
        print STDERR "Unable to create output emojis directory: $emojiOutDir\n";
        exit 1;
    }
}

# Open output file for writing
if(!open($fpOut, '>', $outFile))
{
    print STDERR "Unable to open output file for writing: $outFile\n";
    exit 1;
}

# Open input file for reading
if(!open($fp, "<:encoding(UTF-8)", $inFile))
{
    print STDERR "Unable to open input file for reading: $inFile\n";
    exit 1;
}

#***                            Start work!                                  ***

# Copy in the CSS file if needed
`cp $cssInDir/whatsapp.css $outDir` if(! -f "$outDir/whatsapp.css");

# Print header and start processing
PrintHTMLHeader($fpOut);

while(<$fp>)
{
    chomp;

    # 01/01/2018, 10:00 - Name name: text
    if(/(\d.*?),\s+(\d\d:\d\d)\s+-\s+(.*?):\s+(.*)/)
    {
        my $date = $1;
        my $time = $2;
        my $name = $3;
        my $text = $4;

        if($date ne $prevDate)
        {
            PrintDate($fpOut, $date);
            $prevDate = $date;
        }
        if($name ne $prevName)
        {
            $person = $person?0:1;
            $prevName = $name;
            ClearBoth($fpOut);
        }

        PrintMessage($fpOut, $person, $name, $time, $text, $emojiInDir, 
                     $emojiOutDir, $inDir, $outDir);
    }
    elsif(length && (! /^\d+\/\d+\/\d+/))
    {
        my $text = $_;
        PrintMessage($fpOut, $person, '', '', $text, $emojiInDir, 
                     $emojiOutDir, $inDir, $outDir);
    }
}
ClearBoth($fpOut);
PrintHTMLFooter($fpOut);

#*************************************************************************
# void PrintDate($fpOut, $date)
# -----------------------------
# \param[in]   $fpOut   Output file handle
# \patam[in]   $date    Date read from file
#
# Prints the date in HTML
#
# 04.12.18  Original   By: ACRM
sub PrintDate
{
    my($fpOut, $date) = @_;

    ClearBoth($fpOut);
    print $fpOut <<__EOF;
<div class='datewrap'>
  <div class='date'>$date</div>
</div>
__EOF
    ClearBoth($fpOut);
}

#*************************************************************************
# void PrintMessage($fpOut, $person, $name, $time, $text, $emojiInDir, 
#                   $emojiOutDir, $inDir, $outDir)
# --------------------------------------------------------------------
# \param[in]   $fpOut        Output file handle
# \param[in]   $person       The person number
# \param[in]   $name         The name of the person
# \param[in]   $time         The time of the message
# \param[in]   $text         The text of the message
# \param[in]   $emojiInDir   The directory containing the emoji catalogue
# \param[in]   $emojiOutDir  The ouput emoji directory
# \param[in]   $inDir        The input directory containing WhatsApp text
#                            and media
# \param[in]   $outDir       The ouput directory for the HTML version
#
# Prints a person's message
#
# 04.12.18  Original   By: ACRM
# 12.12.18  Now calls EmojifyText before FixImageLink
sub PrintMessage
{
    my($fpOut, $person, $name, $time, $text, $emojiInDir, $emojiOutDir, 
       $inDir, $outDir) = @_;
    $text = EmojifyText($text, $emojiInDir, $emojiOutDir);
    $text = FixImageLink($text, $inDir, $outDir);
    if($name ne '')
    {
        print $fpOut "<div class='person person$person'>\n";
        print $fpOut "  <p class='msghead'>$name: $time</p>\n";
        print $fpOut "  <p class='msgbody'>$text</p>\n";
        print $fpOut "</div> <!-- person person$person --> \n";
    }
    else
    {
        print $fpOut "<div class='person person$person'>\n";
        print $fpOut "  <p class='msgbody'>$text</p>\n";
        print $fpOut "</div> <!-- person person$person --> \n";
    }
}


#*************************************************************************
# $out = EmojifyText($text, $emojiInDir, $emojiOutDir)
# ----------------------------------------------------
# \param[in] $text         The text in which to insert emojis
# \param[in] $emojiInDir   The directory containing the emoji catalogue
# \param[in] $emojiOutDir  The ouput emoji directory
# \return    $out          The resulting text
#
# Takes a line of text and replaces Unicode for emojis with an <img> tag
# linking to the image
#
# 04.12.18  Original   By: ACRM
# 12.12.18  Puts in entity references for pound, <, >, &
sub EmojifyText
{
    my($text, $emojiInDir, $emojiOutDir) = @_;
    my $out = '';
    my @chars = split(//, $text);
    my @hexSet = ();
    my $nHexSet = 0;

    foreach my $char (@chars)
    {
        my $asc = ord($char);
        if($asc == 163)         # Pound sign
        {
            $out    .= "&pound;";
            @hexSet  = ();
            $nHexSet = 0;
        }
        elsif($asc == 60)       # <
        {
            $out    .= "&lt;";
            @hexSet  = ();
            $nHexSet = 0;
        }
        elsif($asc == 62)       # >
        {
            $out    .= "&gt;";
            @hexSet  = ();
            $nHexSet = 0;
        }
        elsif($asc == 38)       # &
        {
            $out    .= "&amp;";
            @hexSet  = ();
            $nHexSet = 0;
        }
        elsif($asc < 255)       # If it's a normal character
        {
            if($nHexSet)
            {
                # Flush out any Unicode characters that we have
                $out = PrintHex($out, $emojiInDir, $emojiOutDir, 
                                $nHexSet, @hexSet);
                @hexSet  = ();
                $nHexSet = 0;
            }

            # Add the normal character
            $out    .= $char;
        }
        elsif($asc == 8217) # Special case of an inverted comma
        {
            $out    .= "'";
            @hexSet  = ();
            $nHexSet = 0;
        }
        else # It's unicode so store it
        {
            my $hex = sprintf("%x", $asc);
            $hexSet[$nHexSet++] = $hex;
        }
    }

    if($nHexSet)
    {
        # Flush out any remaining unicode characters
        $out = PrintHex($out, $emojiInDir, $emojiOutDir, $nHexSet, @hexSet);
    }

    return($out);
}


#*************************************************************************
# void PrintHTMLHeader($fpOut)
# ----------------------------
# \param[in]     $fpOut    Output file handle
#
# Prints an HTML header
#
# 04.12.18  Original   By: ACRM
sub PrintHTMLHeader
{
    my($fpOut) = @_;
    
    print $fpOut <<__EOF;

<html>
<head>
<title>WhatsApp Chat</title>
<link rel='stylesheet' type='text/css' href='whatsapp.css' />
</head>
<body>
<div class='whatsapp'>

__EOF

}

#*************************************************************************
# void PrintHTMLFooter($fpOut)
# ----------------------------
# \param[in]     $fpOut    Output file handle
#
# Prints an HTML footer
#
# 04.12.18  Original   By: ACRM
sub PrintHTMLFooter
{
    my($fpOut) = @_;

    print $fpOut <<__EOF;

</div> <!-- whatsapp -->
</body>
</html>

__EOF

}


#*************************************************************************
# void ClearBoth($fpOut)
# ----------------------
# \param[in]     $fpOut    Output file handle
#
# Prints a <div> to clear the left and right columns in the HTML
#
# 04.12.18  Original   By: ACRM
sub ClearBoth
{
    my($fpOut) = @_;
    
    print $fpOut "<div style='clear: both;'>&nbsp;</div>\n";
}


#*************************************************************************
# $text=FixImageLink($text, $inDir, $outDir)
# -----------------------------------------
# \param[in]  $text    The text in which to insert media links
# \param[in]  $inDir   The input directory containing WhatsApp text
#                      and media
# \param[in]  $outDir  The ouput directory for the HTML version
# \return     $text    The resulting output text
#
# Replaces indicators of attached files with an <img> tag to display the
# image (and an <a> to obtain the full size image). Also replaces video
# files with an <a> tag.
#
# We need to switch to HTML5 so we can have embedded vidoes
#
# 04.12.18  Original   By: ACRM
sub FixImageLink
{
    my($text, $inDir, $outDir) = @_;

    if($text =~ /(IMG.*)\s+\(file attached\)/)
    {
        my $img = $1;
        $text =~ s/\s+\(file attached\)//;
        $text =~ s/$img/<a href='$img'><img src='$img' alt='$img' width='400px' \/><\/a>/;
        CopyFile($img, $inDir, $outDir);
    }
    if($text =~ /(VID.*)\s+\(file attached\)/)
    {
        my $vid = $1;
        $text =~ s/\s+\(file attached\)//;
#        $text =~ s/$vid/<embed src='$vid' autostart='false' width='400px' \/>/;
        $text =~ s/$vid/<a href='$vid' title='$vid'>$vid<\/a>/;
        CopyFile($vid, $inDir, $outDir);
    }

    return($text);
}


#*************************************************************************
# ($path, $file) = ParseFileName($inPathFile1, $inPathFile2)
# ----------------------------------------------------------
# \param[in] $inPathFile1  First  [path/]file
# \param[in] $inPathFile2  Second [path/]file (optional)
# \return    $path         The resulting path
# \return    $file         The full filename with path
#
# Parse a supplied filename to obtain both the path and the full filename.
# When given one parameter this is parsed
# When given two parameters, the path from the first parameter is used
# with the filename from the second parameter
#
# 04.12.18  Original   By: ACRM
sub ParseFileName
{
    my($inPathFile1, $inPathFile2) = @_;
    my $path = '';
    my $file = '';

    if($inPathFile2 eq '') # Parsing and input filename
    {
        if($inPathFile1 =~ /(.*)\/(.*?)$/)
        {
            $path = $1;
            $file = $inPathFile1;
        }
        else
        {
            $path = '.';
            $file = $inPathFile1;
        }
    }
    else # Parsing output directory and file
    {
        $path = $inPathFile1;
        $file = $inPathFile2;
        $file =~ s/.*\///;   # Remove the path
        $file =~ s/\..*?$//; # Remove the extension
        $file .= ".html";    # Add the HTML extension
        $file = "$path/$file"; # Add the new path
        $file =~ s/\/\//\//g; #  // -> /
    }
    return($path, $file);
}


#*************************************************************************
# $success=CopyFile($File, $InDir, $OutDir)
# -----------------------------------------
# \param[in] $File    A file to be copied
# \param[in] $InDir   File in which it is (or may be) stored
# \param[in] $OutDir  File in which it should be placed
# \return    $success Was it copied?
#
# If the file does not exist in $OutDir, then copy if from $InDir and
# check if it was successful. 
# If it wasn't, try again, but adding -fe0f to the filename if it's a 
# PNG file (i.e. xxxx.png becomes # xxxx-fe0f.pdb). This is for some 
# emojis that have this in the filename but not in the WhatsApp Unicode.
# Finally checks again if the file was copied and returns an indication
# of success
#
# 04.12.18  Original   By: ACRM
sub CopyFile
{
    my($File, $InDir, $OutDir) = @_;
    if(! -e "$OutDir/$File")
    {
        if( -e "$InDir/$File")
        {
            `cp $InDir/$File $OutDir`;
        }
    }

    # If it still doesn't exist, try copying a version with -fe0f on the end
    if(! -e "$OutDir/$File")
    {
        my $newFile = $File;
        $newFile =~ s/\.png/-fe0f\.png/;
        if( -e "$InDir/$newFile")
        {
            `cp $InDir/$newFile $OutDir/$File`;
        }
    }

    my $success = 0;
    $success = 1 if( -e "$OutDir/$File");
    return($success);
}


#*************************************************************************
# $filename=CreateBaseFilename($nparts, @parts)
# ---------------------------------------------
# \param[in] $nparts    Number of parts to use
# \param[in] @parts     Array of parts for the name
# \return    $filename  Filestem (no extension)
#
# Assembles the base part of a Unicode filename of the form xxxx-xxxx-xxxx
# by assmbling the parts in the @parts array.
#
# 04.12.18  Original   By: ACRM
sub CreateBaseFilename
{
    my($nparts, @parts) = @_;
    my $filename = '';
    for(my $i=0; $i<$nparts; $i++)
    {
        $filename .= '-' if($filename ne '');
        $filename .= $parts[$i];
    }
    return($filename);
}


#*************************************************************************
# $out=PrintHex($out, $emojiInDir, $emojiOutDir, $nHexSet, @hexSet)
# -----------------------------------------------------------------
# \param[in] $out         Current string for output
# \param[in] $emojiInDir  The directory containing the emoji catalogue
# \param[in] $emojiOutDir The ouput emoji directory
# \param[in] $nHexSet     The number of items in a list of hex Unicodes
# \param[in] @hexSet      The list of hex unicodes
# \return    $out         The updated string for output
#
# Works through the provided set of hex Unicode and does the actual
# substitution by <img> tags. We start of trying to find an emoji with
# as many Unicode elements as possible (up to 5); if that fails we
# successively try fewer elements (down to 1) until we succesfully find
# a file to which to link.
#
# 04.12.18  Original   By: ACRM
sub PrintHex
{
    my($out, $emojiInDir, $emojiOutDir, $nHexSet, @hexSet) = @_;

    # While we have some hex characters
    while($nHexSet)
    {
        # Start with the longest possible and work down to 1
        for(my $hexSize=min($nHexSet, 5); $hexSize>=1; $hexSize--)
        {
            # Create a filename which combines the codes
            my $allHex = CreateBaseFilename($hexSize, @hexSet);

            # Create the filename and try to copy it over from our store
            # of emojis
            my $emojiFile = $allHex . '.png';

            print STDERR "Trying $emojiFile\n" if(defined($::debug));

            # If  the copy was OK, then we have the extended emojis, so
            # reference it in the HTML
            if(CopyFile($emojiFile, $emojiInDir, $emojiOutDir))
            {
                $out .= "<img src='emojis/$emojiFile' width='30px' alt='{$allHex}'/>";
                
                # Move on to the next Unicode character
                for(my $i=0; $i<$hexSize; $i++)
                {
                    shift @hexSet;
                    $nHexSet--;
                }
            }
            elsif($hexSize == 1)
            {
                # We failed even though it was a 1-character Unicode
                # so simply put in some text
                $out .= "{$allHex}";
                
                shift @hexSet;
                $nHexSet--;
            }

            # Exit the loop if we have run out of Unicode elements
            last if(! $nHexSet);
        }
    }

    return($out);
}


#*************************************************************************
# $minVal = min($a, $b)
# ---------------------
# \param[in] $a       A value
# \param[in] $b       A second value
# \return    $minVal  The minimum value
#
# Returns the minimum of two numeric values
#
# 04.12.18  Original   By: ACRM
sub min
{
    my($a, $b) = @_;
    return (($a < $b)?$a:$b);
}


#*************************************************************************
# void UsageDie(void)
# -------------------
# Prints a usage message and exits
#
# 04.12.18  Original 
# 12.12.18  V1.1
sub UsageDie
{
    print <<__EOF;

whatsapp2html V1.1 (c) Andrew C.R. Martin
        
Usage: whatsapp2html [-debug] [pathto/]whatsapp.txt [outputdir]
       -debug Print some debugging information about emojis

Takes a WhatsApp conversation dump and converts it to HTML, embedding emojis
and multimedia as required.    

The input can be just a filename (in the current directory) or a full path
to a file. (Note that it cannot read from standard input.)

If the output directory is not specified then HTML output (including CSS,
emojis and media files) is to the current directory, otherwise to the
specified directory.
    
__EOF
    exit 0;
}
