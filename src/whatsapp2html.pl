#!/usr/bin/perl -s
use strict;
my $prevDate = '';
my $prevName = '';
my $person   = 0;

if((scalar(@ARGV) == 0) ||
   (scalar(@ARGV) >  2) || 
   defined($::h))
{
    UsageDie();
}

my($inDir, $inFile)   = ParseFileName($ARGV[0]);
my($outDir, $outFile) = ParseFileName(scalar(@ARGV)==2?$ARGV[1]:'.', $ARGV[0]);

open(my $fpOut, '>', $outFile) or die;

PrintHTMLHeader($fpOut);

open my $fp, "<:encoding(UTF-8)", $inFile or die;

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
            ClearBoth();
        }

        PrintMessage($fpOut, $person, $name, $time, $text);
    }
    elsif(length && (! /^\d+\/\d+\/\d+/))
    {
        my $text = $_;
        PrintMessage($fpOut, $person, '', '', $text);
    }
}
ClearBoth($fpOut);
PrintHTMLFooter($fpOut);

sub PrintDate
{
    my($fpOut, $date) = @_;

    ClearBoth();
    print $fpOut <<__EOF;
<div class='datewrap'>
  <div class='date'>$date</div>
</div>
__EOF
    ClearBoth();
}

sub PrintMessage
{
    my($fpOut, $person, $name, $time, $text) = @_;
    $text = FixImageLink($text);
    $text = EmojifyText($text);
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

sub PrintHex
{
    my($out, $nHexSet, @hexSet) = @_;

    while($nHexSet >= 3)
    {
        my $allHex = $hexSet[0] . '-' . $hexSet[1] . '-' . $hexSet[2];
        my $emoji = 'emojis/' . $allHex . '.png';
        if( -e $emoji)
        {
            $out .= "<img src='$emoji' width='30px' alt='{$allHex}'/>";
            for(my $i=0; $i<3; $i++)
            {
                shift @hexSet;
                $nHexSet--;
            }
        }
        else
        {
            $out .= "<img src='emojis/$hexSet[0].png' width='30px' alt='{$hexSet[0]}'/>";
            shift @hexSet;
            $nHexSet--;
        }
    }

    while($nHexSet)
    {
        $out .= "<img src='emojis/$hexSet[0].png' width='30px' alt='{$hexSet[0]}'/>";
        shift @hexSet;
        $nHexSet--;
    }
    return($out);
}


sub EmojifyText
{
    my($text) = @_;
    my $out = '';
    my @chars = split(//, $text);
    my @hexSet = ();
    my $nHexSet = 0;

    foreach my $char (@chars)
    {
        my $asc = ord($char);
        if($asc < 255)
        {
            $out = PrintHex($out, $nHexSet, @hexSet);

            $out    .= $char;
            @hexSet  = ();
            $nHexSet = 0;
        }
        elsif($asc == 8217)
        {
            $out    .= "'";
            @hexSet  = ();
            $nHexSet = 0;
        }
        else
        {
            my $hex = sprintf("%x", $asc);
            $hexSet[$nHexSet++] = $hex;
        }
    }

    $out = PrintHex($out, $nHexSet, @hexSet);

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
    my($text) = @_;

    if($text =~ /(IMG.*)\s+\(file attached\)/)
    {
        my $img = $1;
        $text =~ s/\s+\(file attached\)//;
        $text =~ s/$img/<a href='$img'><img src='$img' alt='$img' width='400px' \/><\/a>/;
    }
    if($text =~ /(VID.*)\s+\(file attached\)/)
    {
        my $vid = $1;
        $text =~ s/\s+\(file attached\)//;
#        $text =~ s/$vid/<embed src='$vid' autostart='false' width='400px' \/>/;
        $text =~ s/$vid/<a href='$vid' title='$vid'>$vid<\/a>/;
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
    my($path1, $path2) = @_;
    my $path = '';
    my $file = '';

    if($path2 eq '') # Parsing and input filename
    {
        if($path1 =~ /(.*)\/(.*?)/)
        {
            $path = $1;
            $file = $2;
        }
        else
        {
            $path = '.';
            $file = $2;
        }
    }
    else # Parsing output directory and file
    {
        $path = $1;
        $file = $2;
        $file =~ s/\..*?//; # Remove the extension
        $file .= ".html";
        $file = "$path/$file";
        $file =~ s/\/\//\//g; #  // -> /
    }
    return($path, $file);
}


