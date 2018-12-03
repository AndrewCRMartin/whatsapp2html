#!/usr/bin/perl -s
use strict;
use Cwd qw(abs_path);
use FindBin;

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

### Start work! ###

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

        PrintMessage($fpOut, $person, $name, $time, $text, $emojiInDir, $emojiOutDir, $inDir, $outDir);
    }
    elsif(length && (! /^\d+\/\d+\/\d+/))
    {
        my $text = $_;
        PrintMessage($fpOut, $person, '', '', $text, $emojiInDir, $emojiOutDir, $inDir, $outDir);
    }
}
ClearBoth($fpOut);
PrintHTMLFooter($fpOut);

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

sub PrintMessage
{
    my($fpOut, $person, $name, $time, $text, $emojiInDir, $emojiOutDir, $inDir, $outDir) = @_;
    $text = FixImageLink($text, $inDir, $outDir);
    $text = EmojifyText($text, $emojiInDir, $emojiOutDir);
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

# This code needs to be a bit more complex since the extended codes
# are not all three characters as assumed here. Some are 8-, 7-, 
# or 6-part, lots are 5-, 4-, 3- or 2-part
sub PrintHex
{
    my($out, $emojiInDir, $emojiOutDir, $nHexSet, @hexSet) = @_;

    # If we have 3 or more Unicode characters in a row
    while($nHexSet >= 3)
    {
        # Create a filename which combines  the first three codes
        my $allHex = $hexSet[0] . '-' . $hexSet[1] . '-' . $hexSet[2];

        # Create the filename and try to copy it over from our store
        # of emojis
        my $emojiFile = $allHex . '.png';
        CopyFile($emojiFile, $emojiInDir, $emojiOutDir);

        # If  the copy was OK, then we have one of these extended emojis, so
        # reference it in the HTML
        if( -e "$emojiOutDir/$emojiFile")
        {
            $out .= "<img src='emojis/$emojiFile' width='30px' alt='{$allHex}'/>";

            # Move on to the next Unicode character
            for(my $i=0; $i<3; $i++)
            {
                shift @hexSet;
                $nHexSet--;
            }
        }
        else
        {
            # The copy failed so we just have a normal single character emoji. Copy
            # that over and reference it
            CopyFile("$hexSet[0].png", $emojiInDir, $emojiOutDir);
            
            $out .= "<img src='emojis/$hexSet[0].png' width='30px' alt='{$hexSet[0]}'/>";

            # Move on to the next Unicode character
            shift @hexSet;
            $nHexSet--;
        }
    }

    # Display any remaining Unicode characters
    while($nHexSet)
    {
        CopyFile("$hexSet[0].png", $emojiInDir, $emojiOutDir);
        $out .= "<img src='emojis/$hexSet[0].png' width='30px' alt='{$hexSet[0]}'/>";
        shift @hexSet;
        $nHexSet--;
    }
    return($out);
}


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
        if($asc < 255)  # If it's s normal character
        {
            # Flush out any Unicode characters that we have
            $out = PrintHex($out, $emojiInDir, $emojiOutDir, $nHexSet, @hexSet);

            # Add the normal character
            $out    .= $char;

            # Clear the lists of Unicode characters
            @hexSet  = ();
            $nHexSet = 0;
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

    # Flush out any remaining unicode characters
    $out = PrintHex($out, $emojiInDir, $emojiOutDir, $nHexSet, @hexSet);

    return($out);
}

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

sub PrintHTMLFooter
{
    my($fpOut) = @_;

    print $fpOut <<__EOF;

</div> <!-- whatsapp -->
</body>
</html>

__EOF

}

sub ClearBoth
{
    my($fpOut) = @_;
    
    print $fpOut "<div style='clear: both;'>&nbsp;</div>\n";
}

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

sub UsageDie
{
    print <<__EOF;

whatsapp2html V1.0 (c) Andrew C.R. Martin
        
Usage: whatsapp2html whatsapp.txt [outputdir]

Takes a WhatsApp conversation dump and converts it to HTML, embedding emojis
and multimedia as required.    
    
__EOF
    exit 0;
}

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
}

